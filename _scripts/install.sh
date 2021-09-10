#!/usr/bin/env bash
set -eo pipefail
shopt -s expand_aliases

# initArch discovers the architecture for this system.
init_arch() {
  ARCH=$(uname -m)
  case $ARCH in
    armv5*) ARCH="armv5";;
    armv6*) ARCH="armv6";;
    armv7*) ARCH="arm";;
    aarch64) ARCH="arm64";;
    x86) ARCH="386";;
    x86_64) ARCH="amd64";;
    i686) ARCH="386";;
    i386) ARCH="386";;
  esac
}

function clean_before_exit {
    # delay before exiting, so stdout/stderr flushes through the logging system
    sleep 3
}
trap clean_before_exit EXIT
init_arch

function install_helm {
  tar_name="helm-canary-linux-${ARCH}.tar.gz"
  curl -fsSL -o "${tar_name}" "https://get.helm.sh/${tar_name}"
  tar -zxvf "${tar_name}"
  mv "linux-${ARCH}/helm" /usr/local/bin/helm
  rm -rf "${tar_name}" "linux-${ARCH}"
}

function pre_install_k3s {
  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    mkdir -p /etc/rancher/k3s
    cat << EOF > "/etc/rancher/k3s/registries.yaml"
mirrors:
  "docker.io":
    endpoint:
      - "https://hub-mirror.c.163.com"
      - "https://mirror.baidubce.com"
      - "https://docker-mirror.drycc.cc"
      - "https://registry-1.docker.io"
  "quay.io":
    endpoint:
      - "https://quay-mirror.drycc.cc"
      - "https://quay.io"
  "gcr.io":
    endpoint:
      - "https://gcr-mirror.drycc.cc"
      - "https://gcr.io"
  "k8s.gcr.io":
    endpoint:
      - "https://k8s-mirror.drycc.cc"
      - "https://k8s.gcr.io"
EOF
    INSTALL_K3S_MIRROR="${INSTALL_DRYCC_MIRROR}"
    export INSTALL_K3S_MIRROR
    k3s_install_url="http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh"
    addons_url="https://drycc-mirrors.oss-accelerate.aliyuncs.com/drycc/addons/releases/download/latest/index.yaml"
  else
    k3s_install_url="https://get.k3s.io"
    addons_url="https://github.com/drycc/addons/releases/download/latest/index.yaml"
  fi
}

function install_k3s_server {
  pre_install_k3s
  INSTALL_K3S_EXEC="server ${INSTALL_K3S_EXEC} --flannel-backend=none --disable=traefik --disable=servicelb --cluster-cidr=10.233.0.0/16"
  if [[ -z "${K3S_URL}" ]] ; then
    INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC --cluster-init"
  fi
  curl -sfL "${k3s_install_url}" |INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC" sh -s -
}

function install_k3s_agent {
  pre_install_k3s
  curl -sfL "${k3s_install_url}" |INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC" sh -s -
}


function install_components {
  mount bpffs -t bpf /sys/fs/bpf
  install_helm
  helm repo add drycc https://charts.drycc.cc/${CHANNEL:-stable}
  helm repo update

  echo -e "\\033[32m---> Waiting for helm to install components...\\033[0m"

  helm install cilium drycc/cilium --set operator.replicas=1 --namespace kube-system --wait
  helm install metallb drycc/metallb --namespace kube-system --wait -f - <<EOF
configInline:
  address-pools:
   - name: default
     protocol: layer2
     addresses:
     - ${METALLB_ADDRESS_POOLS:-172.16.0.0/12}
EOF
  helm install ingress-nginx drycc/ingress-nginx --namespace kube-system --wait
  helm install cert-manager drycc/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true --wait
  helm install catalog drycc/catalog --set asyncBindingOperationsEnabled=true --namespace catalog --create-namespace --wait
}

function install_longhorn {
  helm install longhorn drycc/longhorn --create-namespace \
    --set persistence.defaultClass=false \
    --set persistence.defaultClassReplicaCount=1 \
    --namespace longhorn-system --wait
}

function check_drycc_env {
  if [[ -z "${PLATFORM_DOMAIN}" ]] ; then
    echo -e "\\033[31m---> Please set the PLATFORM_DOMAIN variable.\\033[0m"
    echo -e "\\033[31m---> For example:\\033[0m"
    echo -e "\\033[31m---> export PLATFORM_DOMAIN=drycc.cc\\033[0m"
    echo -e "\\033[31m---> And confirm that wildcard domain name resolution has been set.\\033[0m"
    echo -e "\\033[31m---> For example, the current server IP is 8.8.8.8\\033[0m"
    echo -e "\\033[31m---> Please point *.drycc.cc to 8.8.8.8\\033[0m"
    exit 1
  fi	

  if [[ -z "${DRYCC_ADMIN_USERNAME}" || -z "${DRYCC_ADMIN_PASSWORD}" ]] ; then
    echo -e "\\033[31m---> Please set the DRYCC_ADMIN_USERNAME and DRYCC_ADMIN_PASSWORD variable.\\033[0m"
    echo -e "\\033[31m---> For example:\\033[0m"
    echo -e "\\033[31m---> export DRYCC_ADMIN_USERNAME=admin\\033[0m"
    echo -e "\\033[31m---> export DRYCC_ADMIN_PASSWORD=admin\\033[0m"
    echo -e "\\033[31m---> This password is used by end users to log in and manage drycc.\\033[0m"
    echo -e "\\033[31m---> Please set a high security string!!!\\033[0m"
    exit 1
  fi
}

function install_drycc {
  check_drycc_env
  echo -e "\\033[32m---> Start installing workflow...\\033[0m"

  RABBITMQ_USERNAME=$(cat /proc/sys/kernel/random/uuid)
  RABBITMQ_PASSWORD=$(cat /proc/sys/kernel/random/uuid)

  helm install drycc drycc/workflow \
    --set builder.service.type=LoadBalancer \
    --set global.cluster_domain="cluster.local" \
    --set global.platform_domain="${PLATFORM_DOMAIN}" \
    --set global.ingress_class=nginx \
    --set fluentd.daemon_environment.CONTAINER_TAIL_PARSER_TYPE="/^(?<time>.+) (?<stream>stdout|stderr)( (?<tags>.))? (?<log>.*)$/" \
    --set controller.app_storage_class=longhorn \
    --set minio.persistence.enabled=true \
    --set minio.persistence.size=${MINIO_PERSISTENCE_SIZE:-5Gi} \
    --set minio.persistence.storageClass="longhorn" \
    --set rabbitmq.username="${RABBITMQ_USERNAME}" \
    --set rabbitmq.password="${RABBITMQ_PASSWORD}" \
    --set rabbitmq.persistence.enabled=true \
    --set rabbitmq.persistence.size=${RABBITMQ_PERSISTENCE_SIZE:-5Gi} \
    --set rabbitmq.persistence.storageClass="longhorn" \
    --set influxdb.persistence.enabled=true \
    --set influxdb.persistence.size=${INFLUXDB_PERSISTENCE_SIZE:-5Gi} \
    --set influxdb.persistence.storageClass="longhorn" \
    --set monitor.grafana.persistence.enabled=true \
    --set monitor.grafana.persistence.size=${MONITOR_PERSISTENCE_SIZE:-5Gi} \
    --set monitor.grafana.persistence.storageClass="longhorn" \
    --set passport.admin_username=${DRYCC_ADMIN_USERNAME} \
    --set passport.admin_password=${DRYCC_ADMIN_PASSWORD} \
    --namespace drycc \
    --create-namespace --wait --timeout 30m0s
  echo -e "\\033[32m---> Rabbitmq username: $RABBITMQ_USERNAME\\033[0m"
  echo -e "\\033[32m---> Rabbitmq password: $RABBITMQ_PASSWORD\\033[0m"
}

function install_helmbroker {
  HELMBROKER_USERNAME=$(cat /proc/sys/kernel/random/uuid)
  HELMBROKER_PASSWORD=$(cat /proc/sys/kernel/random/uuid)

  echo -e "\\033[32m---> Start installing helmbroker...\\033[0m"

  helm install helmbroker drycc/helmbroker \
    --set ingress_class="nginx" \
    --set platform_domain="cluster.local" \
    --set persistence.storageClass="longhorn" \
    --set persistence.size=${HELMBROKER_PERSISTENCE_SIZE:-5Gi} \
    --set platform_domain=${PLATFORM_DOMAIN} \
    --set username=${HELMBROKER_USERNAME} \
    --set password=${HELMBROKER_PASSWORD} \
    --set environment.HELMBROKER_CELERY_BROKER="amqp://${RABBITMQ_USERNAME}:${RABBITMQ_PASSWORD}@drycc-rabbitmq-0.drycc-rabbitmq.drycc.svc.cluster.local:5672/drycc" \
    --namespace drycc --create-namespace --wait -f - <<EOF
repositories:
- name: drycc-helm-broker
  url: ${addons_url}
EOF

  kubectl apply -f - <<EOF
apiVersion: servicecatalog.k8s.io/v1beta1
kind: ClusterServiceBroker
metadata:
  finalizers:
  - kubernetes-incubator/service-catalog
  generation: 1
  labels:
    app.kubernetes.io/managed-by: Helm
    heritage: Helm
  name: helmbroker
spec:
  relistBehavior: Duration
  relistRequests: 5
  url: https://${HELMBROKER_USERNAME}:${HELMBROKER_PASSWORD}@drycc-helmbroker.${PLATFORM_DOMAIN}
EOF

  echo -e "\\033[32m---> Helmbroker username: $HELMBROKER_USERNAME\\033[0m"
  echo -e "\\033[32m---> Helmbroker password: $HELMBROKER_PASSWORD\\033[0m"
}

function config_haproxy {
  BUILDER_IP=$(kubectl get svc drycc-builder -n drycc -o="jsonpath={.status.loadBalancer.ingress[0].ip}")
  INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n kube-system -o="jsonpath={.status.loadBalancer.ingress[0].ip}")

  if [[ "${USE_HAPROXY:-true}" == "true" ]] ; then
    cat << EOF > "/etc/haproxy/haproxy.cfg"
global
   log /dev/log    local0
   log /dev/log    local1 notice
   chroot /var/lib/haproxy
   stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
   stats timeout 30s
   user haproxy
   group haproxy
   daemon
listen http-80
   bind *:80
   mode tcp
   maxconn 100000
   timeout connect 60s
   timeout client  30000
   timeout server  30000
   server ingress ${INGRESS_IP}:80 check
listen http-443
   bind *:443
   mode tcp
   maxconn 100000
   timeout connect 60s
   timeout client  30000
   timeout server  30000
   server ingress ${INGRESS_IP}:443 check
listen builder
   bind *:2222
   mode tcp
   maxconn 100000
   timeout connect 60s
   timeout client  30000
   timeout server  30000
   server builder ${BUILDER_IP}:2222 check
EOF
  fi

  mkdir -p /run/haproxy
  systemctl enable haproxy
  systemctl restart haproxy
}

if [[ -z "$@" ]] ; then
  install_k3s_server
  install_components
  install_longhorn
  install_drycc
  install_helmbroker
  config_haproxy
  echo -e "\\033[32m---> Installation complete, enjoy life...\\033[0m"
else
  for command in "$@"
  do
      $command
      echo -e "\\033[32m---> Installation $command complete, enjoy life...\\033[0m"
  done
fi