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

init_registry() {
  CHARTS_URL=oci://registry.drycc.cc/$([ $CHANNEL == "stable" ] && echo charts || echo charts-testing)
  if [[ -z "$DRYCC_REGISTRY" ]] ; then
    echo -e "\\033[32m---> Get the fastest drycc registry...\\033[0m"
    registrys=(quay.io ccr.ccs.tencentyun.com sgccr.ccs.tencentyun.com jpccr.ccs.tencentyun.com uswccr.ccs.tencentyun.com useccr.ccs.tencentyun.com deccr.ccs.tencentyun.com saoccr.ccs.tencentyun.com)
    delay=65535
    DRYCC_REGISTRY=quay.io
    for registry in ${registrys[@]}
    do
        time_total=$(curl -o /dev/null -s -w "%{time_total}" "https://$registry")
        if [[ `echo "$delay>$time_total"|bc` -eq 1 ]];then
            delay=$time_total
            DRYCC_REGISTRY=$registry
        fi
    done
  fi
  echo -e "\\033[32m---> The drycc registry is: ${DRYCC_REGISTRY}\\033[0m"
}

function clean_before_exit {
    # delay before exiting, so stdout/stderr flushes through the logging system
    rm -rf /tmp/drycc-values.yaml 
    configure_registries runtime
    sleep 3
}
trap clean_before_exit EXIT
init_arch
init_registry

function install_helm {
  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    version=$(curl -Ls https://drycc-mirrors.drycc.cc/helm/helm/releases|grep /helm/helm/releases/tag/ | sed -E 's/.*\/helm\/helm\/releases\/tag\/(v[0-9\.]{1,}(-rc.[0-9]{1,})?)".*/\1/g' | head -1)
    tar_name="helm-${version}-linux-${ARCH}.tar.gz"
    helm_download_url="https://drycc-mirrors.drycc.cc/helm/${tar_name}"
  else
    version=$(curl -Ls https://github.com/helm/helm/releases|grep /helm/helm/releases/tag/ | sed -E 's/.*\/helm\/helm\/releases\/tag\/(v[0-9\.]{1,}(-rc.[0-9]{1,})?)".*/\1/g' | head -1)
    tar_name="helm-${version}-linux-${ARCH}.tar.gz"
    helm_download_url="https://get.helm.sh/${tar_name}"
  fi
  curl -fsSL -o "${tar_name}" "${helm_download_url}"
  tar -zxvf "${tar_name}"
  mv "linux-${ARCH}/helm" /usr/local/bin/helm
  rm -rf "${tar_name}" "linux-${ARCH}"
}

function configure_os {
  echo -e "\\033[32m---> Start configuring kernel parameters\\033[0m"
  if [[ "$(command -v iptables)" != "" ]] ; then
    iptables -F
    iptables -X
    iptables -F -t nat
    iptables -X -t nat
    iptables -P FORWARD ACCEPT
  fi
  swapoff -a
  sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
  mount bpffs -t bpf /sys/fs/bpf
  rmem_max=$(sysctl -ne net.core.rmem_max)
  if [ ! -n "$rmem_max" ] || [ 2500000 -gt $rmem_max ] ;then
      echo 'net.core.rmem_max = 2500000' >> /etc/sysctl.conf
      
  fi
  nr_hugepages=$(sysctl -ne vm.nr_hugepages)
  if [ ! -n "$nr_hugepages" ] || [ 1024 -gt $nr_hugepages ] ;then
      echo 'vm.nr_hugepages = 1024' >> /etc/sysctl.conf
  fi
  sysctl -p
  echo -e "\\033[32m---> Configuring kernel parameters finish\\033[0m"
}

function configure_registries {
  mkdir -p /etc/rancher/k3s
  if [[ -f  "${REGISTRIES_FILE}" ]]; then
    cat "${REGISTRIES_FILE}" > /etc/rancher/k3s/registries.yaml
  elif [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]]; then
    if [[ "$1" == "runtime" ]] ; then
      cat << EOF > "/etc/rancher/k3s/registries.yaml"
configs:
  "registry.drycc.cc":
    auth:
      username: anonymous
      password: anonymous
mirrors:
  "docker.io":
    endpoint:
    - "https://hub-mirror.c.163.com"
    - "https://registry-1.docker.io"
EOF
    else
      cat << EOF > "/etc/rancher/k3s/registries.yaml"
configs:
  "registry.drycc.cc":
    auth:
      username: anonymous
      password: anonymous
mirrors:
  "docker.io":
    endpoint:
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
    fi
  fi
}

function configure_mirrors {
  echo -e "\\033[32m---> Start configuring mirrors\\033[0m"
  configure_registries
  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    INSTALL_K3S_MIRROR="${INSTALL_DRYCC_MIRROR}"
    k3s_install_url="https://get-k3s.drycc.cc"
    K3S_RELEASE_URL=https://drycc-mirrors.drycc.cc/k3s-io/k3s/releases
    export INSTALL_K3S_MIRROR
  else
    k3s_install_url="https://get.k3s.io"
    K3S_RELEASE_URL=github.com/k3s-io/k3s/releases
  fi
  INSTALL_K3S_VERSION=$(curl -Ls "$K3S_RELEASE_URL" | grep /k3s-io/k3s/releases/tag/ | sed -E 's/.*\/k3s-io\/k3s\/releases\/tag\/(v[0-9\.]{1,}[rc0-9\-]{0,}%2Bk3s[0-9])".*/\1/g' | head -1)
  export INSTALL_K3S_VERSION
  echo -e "\\033[32m---> Configuring mirrors finish\\033[0m"
}

function install_k3s_server {
  configure_os
  configure_mirrors
  INSTALL_K3S_EXEC="server ${INSTALL_K3S_EXEC} --flannel-backend=none  --disable-network-policy --disable=traefik --disable=servicelb --disable-kube-proxy --cluster-cidr=10.233.0.0/16"
  if [[ -n "${K3S_DATA_DIR}" ]] ; then
    INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC --data-dir=${K3S_DATA_DIR}/rancher/k3s"
  fi
  if [[ -z "${K3S_URL}" ]] ; then
    INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC --cluster-init"
  fi
  curl -sfL "${k3s_install_url}" |INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC" sh -s -
}

function install_k3s_agent {
  configure_os
  configure_mirrors
  if [[ -n "${K3S_DATA_DIR}" ]] ; then
    INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC --data-dir=${K3S_DATA_DIR}/rancher/k3s"
  fi
  curl -sfL "${k3s_install_url}" |INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC" sh -s -
}

function check_metallb {
  if [[ "${METALLB_CONFIG_FILE}" && ! -f "${METALLB_CONFIG_FILE}" ]] ; then
    echo -e "\\033[33m---> The path ${METALLB_CONFIG_FILE} does not exist...\\033[0m"
    exit 1
  fi
}

function install_network() {
  echo -e "\\033[32m--->Start installing network...\\033[0m"
  api_server_address=(`ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'`)
  helm install cilium $CHARTS_URL/cilium \
    --set tunnel=geneve \
    --set operator.replicas=1 \
    --set bandwidthManager=true \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=${KUBE_API_SERVER_ADDRESS:-$api_server_address} \
    --set k8sServicePort=${KUBE_API_SERVER_PORT:-"6443"} \
    --set global.containerRuntime.integration="containerd" \
    --set global.containerRuntime.socketPath="/var/run/k3s/containerd/containerd.sock" \
    --set hostPort.enabled=true \
    --namespace kube-system --wait
  echo -e "\\033[32m---> Network installed!\\033[0m"
}

function install_metallb() {
  check_metallb
  echo -e "\\033[32m--->Start installing metallb...\\033[0m"
  helm install metallb $CHARTS_URL/metallb \
    --set speaker.frr.enabled=true \
    --namespace metallb \
    --create-namespace

  echo -e "\\033[32m--->Waiting metallb pods ready...\\033[0m"
  kubectl wait pods -n metallb --all  --for condition=Ready --timeout=600s
  echo -e "\\033[32m--->Waiting metallb webhook ready...\\033[0m"
  sleep 30s

  if [[ -z "${METALLB_CONFIG_FILE}" ]] ; then
    echo -e "\\033[32m---> Metallb using the default configuration.\\033[0m"
    kubectl apply -n metallb -f - <<EOF
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: public
spec:
  addresses:
  - $(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')/32

---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
spec:
  addresses:
  - 192.168.254.0/24

---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: drycc-l2-advertisement
  namespace: metallb
spec:
  ipAddressPools:
  - public
  - default
EOF
  else
    kubectl apply -n metallb -f ${METALLB_CONFIG_FILE}
  fi
  echo -e "\\033[32m---> Metallb installed!\\033[0m"
}

function install_traefik() {
  echo -e "\\033[32m--->Start installing traefik...\\033[0m"
  helm install traefik $CHARTS_URL/traefik \
    --namespace traefik \
    --create-namespace --wait -f - <<EOF
service:
  annotations:
    metallb.universe.tf/address-pool: public
    metallb.universe.tf/allow-shared-ip: drycc 
websecure:
  tls:
    enabled: true
ingressClass:
  enabled: true
  isDefaultClass: true
additionalArguments:
- "--entrypoints.websecure.http.tls"
- "--experimental.http3=true"
- "--entrypoints.name.http3"
- "--providers.kubernetesingress.allowEmptyServices=true"
EOF
  echo -e "\\033[32m---> Traefik installed!\\033[0m"
}

function install_cert_manager() {
  echo -e "\\033[32m--->Start installing cert-manager...\\033[0m"
  helm install cert-manager $CHARTS_URL/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set clusterResourceNamespace=drycc \
    --set installCRDs=true --wait
  echo -e "\\033[32m---> Cert-manager installed!\\033[0m"
}

function install_catalog() {
  echo -e "\\033[32m--->Start installing catalog...\\033[0m"
  helm install catalog $CHARTS_URL/catalog \
    --set asyncBindingOperationsEnabled=true \
    --set image=docker.io/drycc/service-catalog:canary \
    --namespace catalog \
    --create-namespace --wait
  echo -e "\\033[32m---> Catalog installed!\\033[0m"
}

function install_components {
  install_network
  install_metallb
  install_traefik
  install_cert_manager
  install_catalog
}

function check_drycc {
  if [[ -z "${PLATFORM_DOMAIN}" ]] ; then
    echo -e "\\033[33m---> Please set the PLATFORM_DOMAIN variable.\\033[0m"
    echo -e "\\033[33m---> For example:\\033[0m"
    echo -e "\\033[33m---> export PLATFORM_DOMAIN=drycc.cc\\033[0m"
    echo -e "\\033[33m---> And confirm that wildcard domain name resolution has been set.\\033[0m"
    echo -e "\\033[33m---> For example, the current server IP is 8.8.8.8\\033[0m"
    echo -e "\\033[33m---> Please point *.drycc.cc to 8.8.8.8\\033[0m"
    exit 1
  fi

  if [[ -z "${DRYCC_ADMIN_USERNAME}" || -z "${DRYCC_ADMIN_PASSWORD}" ]] ; then
    echo -e "\\033[33m---> Please set the DRYCC_ADMIN_USERNAME and DRYCC_ADMIN_PASSWORD variable.\\033[0m"
    echo -e "\\033[33m---> For example:\\033[0m"
    echo -e "\\033[33m---> export DRYCC_ADMIN_USERNAME=admin\\033[0m"
    echo -e "\\033[33m---> export DRYCC_ADMIN_PASSWORD=admin\\033[0m"
    echo -e "\\033[33m---> This password is used by end users to log in and manage drycc.\\033[0m"
    echo -e "\\033[33m---> Please set a high security string!!!\\033[0m"
    exit 1
  fi
}

function install_drycc {
  check_drycc
  echo -e "\\033[32m---> Start installing workflow...\\033[0m"
  RABBITMQ_USERNAME=$(cat /proc/sys/kernel/random/uuid)
  RABBITMQ_PASSWORD=$(cat /proc/sys/kernel/random/uuid)
  INFLUXDB_USERNAME=$(cat /proc/sys/kernel/random/uuid)
  INFLUXDB_PASSWORD=$(cat /proc/sys/kernel/random/uuid)


cat << EOF > "/tmp/drycc-values.yaml"
global:
  clusterDomain: cluster.local
  platformDomain: ${PLATFORM_DOMAIN}
  certManagerEnabled: ${CERT_MANAGER_ENABLED:-true}
  ingressClass: traefik

builder:
  replicas: ${BUILDER_REPLICAS}
  imageRegistry: ${DRYCC_REGISTRY}
  service:
    type: LoadBalancer
    annotations:
      metallb.universe.tf/address-pool: public
      metallb.universe.tf/allow-shared-ip: drycc

database:
  replicas: ${DATABASE_REPLICAS}
  imageRegistry: ${DRYCC_REGISTRY}
  limitsMemory: "256Mi"
  limitsHugepages2Mi: "256Mi"
  persistence:
    enabled: true
    size: ${DATABASE_PERSISTENCE_SIZE:-5Gi}
    storageClass: ${DATABASE_PERSISTENCE_STORAGE_CLASS:-""}

fluentd:
  imageRegistry: ${DRYCC_REGISTRY} 
  daemonEnvironment:
    CONTAINER_TAIL_PARSER_TYPE: "/^(?<time>.+) (?<stream>stdout|stderr)( (?<tags>.))? (?<log>.*)$/"

controller:
  apiReplicas: ${CONTROLLER_API_REPLICAS}
  celeryReplicas: ${CONTROLLER_CELERY_REPLICAS}
  webhookReplicas: ${CONTROLLER_WEBHOOK_REPLICAS}
  imageRegistry: ${DRYCC_REGISTRY} 
  appStorageClass: ${CONTROLLER_APP_STORAGE_CLASS:-"drycc-storage"}

redis:
  replicas: ${REDIS_REPLICAS}
  imageRegistry: ${DRYCC_REGISTRY}
  persistence:
    enabled: true
    size: ${REDIS_PERSISTENCE_SIZE:-5Gi}
    storageClass: ${REDIS_PERSISTENCE_STORAGE_CLASS:-""}

storage:
  minio:
    zone: ${STORAGE_MINIO_ZONE:-1}
    drives: ${STORAGE_MINIO_DRIVES:-4}
    replicas: ${STORAGE_MINIO_REPLICAS:-1}
    imageRegistry: ${DRYCC_REGISTRY}
    persistence:
      enabled: true
      size: ${STORAGE_MINIO_PERSISTENCE_SIZE:-20Gi}
      storageClass: ${STORAGE_MINIO_PERSISTENCE_STORAGE_CLASS:-""}
  meta:
    pd:
      replicas: ${STORAGE_META_PD_REPLICAS}
      persistence:
        enabled: true
        size: ${STORAGE_META_PD_PERSISTENCE_SIZE:-10Gi}
        storageClass: ${STORAGE_META_PD_PERSISTENCE_STORAGE_CLASS:-""}
    tikv:
      replicas: ${STORAGE_META_TIKV_REPLICAS}
      persistence:
        enabled: true
        size: ${STORAGE_META_TIKV_PERSISTENCE_SIZE:-10Gi}
        storageClass: ${STORAGE_META_TIKV_PERSISTENCE_STORAGE_CLASS:-""}

rabbitmq:
  replicas: ${RABBITMQ_REPLICAS}
  imageRegistry: ${DRYCC_REGISTRY}
  username: "${RABBITMQ_USERNAME}"
  password: "${RABBITMQ_PASSWORD}"
  persistence:
    enabled: true
    size: ${RABBITMQ_PERSISTENCE_SIZE:-5Gi}
    storageClass: ${RABBITMQ_PERSISTENCE_STORAGE_CLASS:-""}

imagebuilder:
  imageRegistry: ${DRYCC_REGISTRY}

influxdb:
  replicas: ${INFLUXDB_REPLICAS}
  imageRegistry: ${DRYCC_REGISTRY}
  user: "${INFLUXDB_USERNAME}"
  password: "${INFLUXDB_PASSWORD}"
  persistence:
    enabled: true
    size: ${INFLUXDB_PERSISTENCE_SIZE:-5Gi}
    storageClass: ${INFLUXDB_PERSISTENCE_STORAGE_CLASS:-""}

logger:
  replicas: ${LOGGER_REPLICAS}
  imageRegistry: ${DRYCC_REGISTRY}

monitor:
  grafana:
    imageRegistry: ${DRYCC_REGISTRY}
    persistence:
      enabled: true
      size: ${MONITOR_GRAFANA_PERSISTENCE_SIZE:-5Gi}
      storageClass: ${MONITOR_GRAFANA_PERSISTENCE_STORAGE_CLASS:-""}
  telegraf:
    imageRegistry: ${DRYCC_REGISTRY}


passport:
  replicas: ${PASSPORT_REPLICAS}
  imageRegistry: ${DRYCC_REGISTRY}
  adminUsername: ${DRYCC_ADMIN_USERNAME}
  adminPassword: ${DRYCC_ADMIN_PASSWORD}

registry:
  replicas: ${REGISTRY_REPLICAS}
  imageRegistry: ${DRYCC_REGISTRY}

registry-proxy:
  imageRegistry: ${DRYCC_REGISTRY}

acme:
  server: ${ACME_SERVER:-"https://acme-v02.api.letsencrypt.org/directory"}
  externalAccountBinding:
    keyID: ${ACME_EAB_KEY_ID:-""}
    keySecret: ${ACME_EAB_KEY_SECRET:-""}
EOF

  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    cat << EOF > "/tmp/drycc-mirror-values.yaml"
imagebuilder:
  container_registries: |
    unqualified-search-registries = ["docker.io"]
    short-name-mode="permissive"
    [[registry]]
    prefix = "docker.io"
    location = "registry-1.docker.io"
    [[registry.mirror]]
    prefix = "docker.io"
    location = "hub-mirror.c.163.com"
EOF
  else
    cat << EOF > "/tmp/drycc-mirror-values.yaml"
imagebuilder:
  container_registries: |
    unqualified-search-registries = ["docker.io"]
    short-name-mode="permissive"
EOF
  fi

  helm install drycc $CHARTS_URL/workflow \
    --namespace drycc \
    --values /tmp/drycc-values.yaml \
    --values /tmp/drycc-mirror-values.yaml \
    --create-namespace --wait --timeout 30m0s
  echo -e "\\033[32m---> Rabbitmq username: $RABBITMQ_USERNAME\\033[0m"
  echo -e "\\033[32m---> Rabbitmq password: $RABBITMQ_PASSWORD\\033[0m"
  echo -e "\\033[32m---> Influxdb username: $INFLUXDB_USERNAME\\033[0m"
  echo -e "\\033[32m---> Influxdb password: $INFLUXDB_PASSWORD\\033[0m"
}

function install_helmbroker {
  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    addons_url="https://drycc-mirrors.drycc.cc/drycc-addons/addons/releases/download/latest/index.yaml"
  else
    addons_url="https://github.com/drycc-addons/addons/releases/download/latest/index.yaml"
  fi
  HELMBROKER_USERNAME=$(cat /proc/sys/kernel/random/uuid)
  HELMBROKER_PASSWORD=$(cat /proc/sys/kernel/random/uuid)

  echo -e "\\033[32m---> Start installing helmbroker...\\033[0m"

  helm install helmbroker $CHARTS_URL/helmbroker \
    --set ingressClass="traefik" \
    --set platformDomain="cluster.local" \
    --set persistence.size=${HELMBROKER_PERSISTENCE_SIZE:-5Gi} \
    --set persistence.storageClass=${HELMBROKER_PERSISTENCE_STORAGE_CLASS:-"drycc-storage"} \
    --set platformDomain=${PLATFORM_DOMAIN} \
    --set certManagerEnabled=${CERT_MANAGER_ENABLED:-true} \
    --set username=${HELMBROKER_USERNAME} \
    --set password=${HELMBROKER_PASSWORD} \
    --set replicas=${HELMBROKER_REPLICAS} \
    --set celeryReplicas=${HELMBROKER_CELERY_REPLICAS} \
    --set environment.HELMBROKER_CELERY_BROKER="amqp://${RABBITMQ_USERNAME}:${RABBITMQ_PASSWORD}@drycc-rabbitmq.drycc.svc.cluster.local:5672/drycc" \
    --namespace drycc --create-namespace --wait -f - <<EOF
repositories:
- name: drycc-helm-broker
  url: ${addons_url}
EOF
  if [[ "${CERT_MANAGER_ENABLED:-true}" == "true" ]] ; then
    BROKER_URL="https://${HELMBROKER_USERNAME}:${HELMBROKER_PASSWORD}@drycc-helmbroker.${PLATFORM_DOMAIN}"
  else
    BROKER_URL="http://${HELMBROKER_USERNAME}:${HELMBROKER_PASSWORD}@drycc-helmbroker.${PLATFORM_DOMAIN}"
  fi

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
  url: ${BROKER_URL}
EOF

  echo -e "\\033[32m---> Helmbroker username: $HELMBROKER_USERNAME\\033[0m"
  echo -e "\\033[32m---> Helmbroker password: $HELMBROKER_PASSWORD\\033[0m"
}

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

if [[ -z "$@" ]] ; then
  check_drycc
  check_metallb
  install_k3s_server
  install_helm
  install_components
  install_drycc
  install_helmbroker
  echo -e "\\033[32m---> Installation complete, enjoy life...\\033[0m"
else
  for command in "$@"
  do
      $command
      echo -e "\\033[32m---> Execute $command complete, enjoy life...\\033[0m"
  done
fi
