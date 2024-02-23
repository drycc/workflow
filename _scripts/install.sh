#!/usr/bin/env bash
set -eo pipefail
shopt -s expand_aliases

# default vars
GATEWAY_CLASS="istio"
CLUSTER_CIDR=${CLUSTER_CIDR:-"10.43.0.0/16"}
CLUSTER_DOMAIN=${CLUSTER_DOMAIN:-"cluster.local"}
CERT_MANAGER_ENABLED="${CERT_MANAGER_ENABLED:false}"
DRYCC_REGISTRY="${DRYCC_REGISTRY:-registry.drycc.cc}"
CHARTS_URL=oci://registry.drycc.cc/$([ "$CHANNEL" == "stable" ] && echo charts || echo charts-testing)

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
    rm -rf /tmp/drycc-values.yaml 
    configure_containerd runtime
    sleep 3
}
trap clean_before_exit EXIT
init_arch

urlencode() {
  # urlencode <string>

  old_lang=$LANG
  LANG=C
  
  old_lc_collate=$LC_COLLATE
  LC_COLLATE=C

  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
      local c="${1:i:1}"
      case $c in
          [a-zA-Z0-9.~_-]) printf "$c" ;;
          *) printf '%%%02X' "'$c" ;;
      esac
  done

  LANG=$old_lang
  LC_COLLATE=$old_lc_collate
}

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
  max_user_instances=$(sysctl -ne fs.inotify.max_user_instances)
  if [ ! -n "$max_user_instances" ] || [ 65535 -gt $max_user_instances ] ;then
    echo 'fs.inotify.max_user_instances = 65535' >> /etc/sysctl.conf
  fi
  sysctl -p
  
  cpufreq=$(ls /sys/devices/system/cpu/cpu*/cpufreq >/dev/null 2>&1 || echo "false")
  if [[ $cpufreq != "false" ]]; then
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
      echo performance > $cpu
    done
  fi
  echo -e "\\033[32m---> Configuring kernel parameters finish\\033[0m"
}

function configure_registries {
  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]]; then
    if [[ "$1" == "runtime" ]] ; then
      cat << EOF >> "/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl"
[plugins.cri.registry.mirrors]
[plugins.cri.registry.mirrors."docker.io"]
  endpoint = ["https://docker-mirror.drycc.cc", "https://registry-1.docker.io"]
EOF
    else
      cat << EOF >> "/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl"
[plugins.cri.registry.mirrors]
[plugins.cri.registry.mirrors."docker.io"]
  endpoint = ["https://docker-mirror.drycc.cc", "https://registry-1.docker.io"]
[plugins.cri.registry.mirrors."quay.io"]
  endpoint = ["https://quay-mirror.drycc.cc", "https://quay.io"]
[plugins.cri.registry.mirrors."gcr.io"]
  endpoint = ["https://quay-mirror.drycc.cc", "https://gcr.io"]
[plugins.cri.registry.mirrors."k8s.gcr.io"]
  endpoint = ["https://k8s-mirror.drycc.cc", "https://registry.k8s.io"]
[plugins.cri.registry.mirrors."registry.k8s.io"]
  endpoint = ["https://k8s-mirror.drycc.cc", "https://registry.k8s.io"]
EOF
    fi
  fi
}

function download_runtime {
  # download crun
  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    crun_base_url="https://drycc-mirrors.drycc.cc/containers"
  else
    crun_base_url="https://github.com/containers"
  fi
  crun_version=$(curl -Ls ${crun_base_url}/crun/releases|grep /containers/crun/releases/tag/ | sed -E 's/.*\/containers\/crun\/releases\/tag\/([0-9\.]{1,}(-rc.[0-9]{1,})?)".*/\1/g' | head -1)
  crun_download_url=${crun_base_url}/crun/releases/download/${crun_version}/crun-${crun_version}-linux-${ARCH}
  curl -sfL "${crun_download_url}" -o /usr/local/bin/crun
  chmod a+rx /usr/local/bin/crun

  # download runsc
  gvisor_download_url=https://storage.googleapis.com/gvisor/releases/release/latest/$(uname -m)
  curl -sfL "${gvisor_download_url}/runsc" -o /usr/local/bin/runsc
  curl -sfL "${gvisor_download_url}/containerd-shim-runsc-v1" -o /usr/local/bin/containerd-shim-runsc-v1
  chmod a+rx /usr/local/bin/runsc /usr/local/bin/containerd-shim-runsc-v1
}

function configure_runtime {
  cat << EOF > "/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl"
[plugins.cri.containerd]
  snapshotter = "overlayfs"
  default_runtime_name = "crun"
  disable_snapshot_annotations = true

[plugins.cri.containerd.runtimes.crun]
  runtime_type = "io.containerd.runc.v2"

[plugins.cri.containerd.runtimes.crun.options]
  SystemdCgroup = true

[plugins.cri.containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"

[plugins.cri.containerd.runtimes.runc.options]
	SystemdCgroup = true

[plugins.cri.containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"

[plugins.cri.containerd.runtimes.runsc.options]
  SystemdCgroup = true
  TypeUrl = "io.containerd.runsc.v1.options"
  ConfigPath = "/var/lib/rancher/k3s/agent/etc/containerd/runsc.toml"
EOF
  cat << EOF > "/var/lib/rancher/k3s/agent/etc/containerd/runsc.toml"
[runsc_config]
network = "host"
EOF
}

function configure_containerd {
  mkdir -p /var/lib/rancher/k3s/agent/etc/containerd
  if [[ -f  "${CONTAINERD_FILE}" ]]; then
    cat "${CONTAINERD_FILE}" > /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl
  else
    configure_runtime
    configure_registries $1
  fi
}

function configure_mirrors {
  echo -e "\\033[32m---> Start configuring mirrors\\033[0m"
  configure_containerd
  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    INSTALL_K3S_MIRROR="${INSTALL_DRYCC_MIRROR}"
    k3s_install_url="https://get-k3s.drycc.cc"
    K3S_RELEASE_URL=https://drycc-mirrors.drycc.cc/k3s-io/k3s/releases
    export INSTALL_K3S_MIRROR
  else
    k3s_install_url="https://get.k3s.io"
    K3S_RELEASE_URL=github.com/k3s-io/k3s/releases
  fi
  if [ -z "${INSTALL_K3S_VERSION}" ]; then
    INSTALL_K3S_VERSION=$(curl -Ls "$K3S_RELEASE_URL" | grep /k3s-io/k3s/releases/tag/ | sed -E 's/.*\/k3s-io\/k3s\/releases\/tag\/(v[0-9\.]{1,}[rc0-9\-]{0,}%2Bk3s[0-9])".*/\1/g' | head -1)
  else 
    INSTALL_K3S_VERSION=$(urlencode "$INSTALL_K3S_VERSION")
  fi
  export INSTALL_K3S_VERSION
  echo -e "\\033[32m---> Configuring mirrors finish\\033[0m"
}

function install_k3s_server {
  configure_os
  download_runtime
  configure_mirrors
  INSTALL_K3S_EXEC="server ${INSTALL_K3S_EXEC} --flannel-backend=none  --disable-network-policy --disable=traefik --disable=servicelb --disable-kube-proxy --cluster-cidr=${CLUSTER_CIDR} --cluster-domain=${CLUSTER_DOMAIN}"
  if [[ -n "${K3S_DATA_DIR}" ]] ; then
    INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC --data-dir=${K3S_DATA_DIR}/rancher/k3s"
  fi
  if [[ -z "${K3S_URL}" ]] ; then
    INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC --cluster-init"
  fi
  curl -sfL "${k3s_install_url}" |INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC" sh -s -
  kubectl apply -f - <<EOF
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: crun
handler: crun
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: runc
handler: runc
---
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: runsc
handler: runsc
---
EOF
}

function install_k3s_agent {
  configure_os
  download_runtime
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
  echo -e "\\033[32m---> Start installing network...\\033[0m"
  kubernetes_service_host=(`ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'`)
  helm install cilium $CHARTS_URL/cilium \
    --set endpointHealthChecking.enabled=false \
    --set healthChecking=false \
    --set operator.replicas=1 \
    --set bpf.masquerade=true \
    --set bandwidthManager.enabled=true \
    --set bandwidthManager.bbr=true \
    --set kubeProxyReplacement=true \
    --set hubble.enabled=false \
    --set hostPort.enabled=true \
    --set k8sServiceHost=${KUBERNETES_SERVICE_HOST:-$kubernetes_service_host} \
    --set k8sServicePort=${KUBERNETES_SERVICE_PORT:-6443} \
    --set prometheus.enabled=true \
    --set operator.prometheus.enabled=true \
    --namespace kube-system --wait
  echo -e "\\033[32m---> Network installed!\\033[0m"
}

function install_metallb() {
  check_metallb
  echo -e "\\033[32m---> Start installing metallb...\\033[0m"
  helm install metallb $CHARTS_URL/metallb \
    --set speaker.frr.enabled=true \
    --namespace metallb \
    --create-namespace

  echo -e "\\033[32m---> Waiting metallb pods ready...\\033[0m"
  kubectl wait pods -n metallb --all  --for condition=Ready --timeout=600s
  echo -e "\\033[32m---> Waiting metallb webhook ready...\\033[0m"
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
  serviceAllocation:
    priority: 50
    namespaces:
    - drycc

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

function install_gateway() {
  echo -e "\\033[32m---> Start installing gateway...\\033[0m"

  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    gateway_api_url=https://drycc-mirrors.drycc.cc/kubernetes-sigs/gateway-api
  else
    gateway_api_url=https://github.com/kubernetes-sigs/gateway-api
  fi
  version=$(curl -Ls $gateway_api_url/releases|grep /kubernetes-sigs/gateway-api/releases/tag/ | sed -E 's/.*\/kubernetes-sigs\/gateway-api\/releases\/tag\/(v[0-9\.]{1,}(-rc[0-9]{1,})?)".*/\1/g' | head -1)

  helm repo add istio https://drycc-mirrors.drycc.cc/istio-charts
  helm repo update
  kubectl apply -f $gateway_api_url/releases/download/${version}/experimental-install.yaml
  helm install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace --wait
  helm install istio-istiod istio/istiod -n istio-system --set pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true --wait
  helm install istio-gateway istio/gateway -n istio-gateway --create-namespace --wait
  echo -e "\\033[32m---> Gateway installed!\\033[0m"
}

function install_cert_manager() {
  echo -e "\\033[32m---> Start installing cert-manager...\\033[0m"
  helm install cert-manager $CHARTS_URL/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set clusterResourceNamespace=drycc \
    --set "extraArgs={--feature-gates=ExperimentalGatewayAPISupport=true}" \
    --set installCRDs=true --wait
  echo -e "\\033[32m---> Cert-manager installed!\\033[0m"
}

function install_catalog() {
  echo -e "\\033[32m---> Start installing catalog...\\033[0m"
  helm install catalog $CHARTS_URL/catalog \
    --set asyncBindingOperationsEnabled=true \
    --set image=registry.drycc.cc/drycc-addons/service-catalog:canary \
    --namespace catalog \
    --create-namespace --wait
  echo -e "\\033[32m---> Catalog installed!\\033[0m"
}

function install_components {
  install_network
  install_metallb
  install_gateway
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

cat << EOF > "/tmp/drycc-values.yaml"
global:
  clusterDomain: ${CLUSTER_DOMAIN}
  platformDomain: ${PLATFORM_DOMAIN}
  certManagerEnabled: ${CERT_MANAGER_ENABLED}
  gatewayClass: ${GATEWAY_CLASS}

builder:
  replicas: ${BUILDER_REPLICAS:-1}
  imageRegistry: ${DRYCC_REGISTRY}

database:
  replicas: ${DATABASE_REPLICAS:-2}
  imageRegistry: ${DRYCC_REGISTRY}
  limitsMemory: "256Mi"
  limitsHugepages2Mi: "256Mi"
  persistence:
    enabled: true
    size: ${DATABASE_PERSISTENCE_SIZE:-5Gi}
    storageClass: ${DATABASE_PERSISTENCE_STORAGE_CLASS:-""}

timeseries:
  replicas: ${TIMESERIES_REPLICAS:-1}
  imageRegistry: ${DRYCC_REGISTRY}
  limitsMemory: "256Mi"
  limitsHugepages2Mi: "256Mi"
  persistence:
    enabled: true
    size: ${TIMESERIES_PERSISTENCE_SIZE:-5Gi}
    storageClass: ${TIMESERIES_PERSISTENCE_STORAGE_CLASS:-""}

fluentbit:
  imageRegistry: ${DRYCC_REGISTRY}

controller:
  apiReplicas: ${CONTROLLER_API_REPLICAS:-1}
  celeryReplicas: ${CONTROLLER_CELERY_REPLICAS:-1}
  webhookReplicas: ${CONTROLLER_WEBHOOK_REPLICAS:-1}
  imageRegistry: ${DRYCC_REGISTRY}
  appRuntimeClass: ${CONTROLLER_APP_RUNTIME_CLASS:-""}
  appStorageClass: ${CONTROLLER_APP_STORAGE_CLASS:-"drycc-storage"}

redis:
  replicas: ${REDIS_REPLICAS:-1}
  imageRegistry: ${DRYCC_REGISTRY}
  persistence:
    enabled: true
    size: ${REDIS_PERSISTENCE_SIZE:-5Gi}
    storageClass: ${REDIS_PERSISTENCE_STORAGE_CLASS:-""}

storage:
  csi:
    statefulset:
      replicas: ${STORAGE_CSI_STATEFULSET_REPLICAS:-1}
  mainnode:
    tipd:
      replicas: ${STORAGE_MAINNODE_TIPD_REPLICAS:-1}
      persistence:
        enabled: true
        size: ${STORAGE_MAINNODE_TIPD_PERSISTENCE_SIZE:-5Gi}
        storageClass: "${STORAGE_MAINNODE_TIPD_PERSISTENCE_STORAGE_CLASS}"
    weed:
      replicas: ${STORAGE_MAINNODE_WEED_REPLICAS:-1}
      volumePreallocate: ${STORAGE_MAINNODE_WEED_PREALLOCATE:-false}
      volumeSizeLimitMB: ${STORAGE_MAINNODE_WEED_SIZE_LIMIT_MB:-512}
      defaultReplication: "${STORAGE_MAINNODE_WEED_DEFAULT_REPLICATION:-000}"
      persistence:
        enabled: true
        size: ${STORAGE_MAINNODE_WEED_PERSISTENCE_SIZE:-5Gi}
        storageClass: "${STORAGE_MAINNODE_WEED_PERSISTENCE_STORAGE_CLASS}"
  metanode:
    tikv:
      replicas: ${STORAGE_METANODE_TIKV_REPLICAS:-1}
      persistence:
        enabled: true
        size: ${STORAGE_METANODE_TIKV_PERSISTENCE_SIZE:-5Gi}
        storageClass: "${STORAGE_METANODE_TIKV_PERSISTENCE_STORAGE_CLASS}"
    weed:
      replicas: ${STORAGE_METANODE_WEED_REPLICAS:-1}
      persistence:
        enabled: true
        size: ${STORAGE_METANODE_WEED_PERSISTENCE_SIZE:-5Gi}
        storageClass: "${STORAGE_METANODE_WEED_PERSISTENCE_STORAGE_CLASS}"
  datanode:
    weed:
      replicas: ${STORAGE_DATANODE_WEED_REPLICAS:-1}
      persistence:
        enabled: true
        size: ${STORAGE_DATANODE_WEED_PERSISTENCE_SIZE:-10Gi}
        storageClass: "${STORAGE_DATANODE_WEED_PERSISTENCE_STORAGE_CLASS}"

rabbitmq:
  replicas: ${RABBITMQ_REPLICAS:-1}
  imageRegistry: ${DRYCC_REGISTRY}
  username: "${RABBITMQ_USERNAME}"
  password: "${RABBITMQ_PASSWORD}"
  persistence:
    enabled: true
    size: ${RABBITMQ_PERSISTENCE_SIZE:-5Gi}
    storageClass: ${RABBITMQ_PERSISTENCE_STORAGE_CLASS:-""}

imagebuilder:
  imageRegistry: ${DRYCC_REGISTRY}

logger:
  replicas: ${LOGGER_REPLICAS:-1}
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

prometheus:
  prometheus-server:
    retention: ${PROMETHEUS_SERVER_RETENTION:-"15d"}
    persistence:
      enabled: true
      accessMode: ReadWriteOnce
      size: ${PROMETHEUS_SERVER_PERSISTENCE_SIZE:-10Gi}
      storageClass: ${PROMETHEUS_SERVER_PERSISTENCE_STORAGE_CLASS:-""}

passport:
  replicas: ${PASSPORT_REPLICAS:-1}
  imageRegistry: ${DRYCC_REGISTRY}
  adminUsername: ${DRYCC_ADMIN_USERNAME}
  adminPassword: ${DRYCC_ADMIN_PASSWORD}

registry:
  replicas: ${REGISTRY_REPLICAS:-1}
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
    --set global.rabbitmqLocation="off-cluster" \
    --set global.gatewayClass=${GATEWAY_CLASS} \
    --set global.clusterDomain=${CLUSTER_DOMAIN} \
    --set global.platformDomain=${PLATFORM_DOMAIN} \
    --set global.certManagerEnabled=${CERT_MANAGER_ENABLED} \
    --set persistence.size=${HELMBROKER_PERSISTENCE_SIZE:-5Gi} \
    --set persistence.storageClass=${HELMBROKER_PERSISTENCE_STORAGE_CLASS:-"drycc-storage"} \
    --set username=${HELMBROKER_USERNAME} \
    --set password=${HELMBROKER_PASSWORD} \
    --set replicas=${HELMBROKER_REPLICAS} \
    --set celeryReplicas=${HELMBROKER_CELERY_REPLICAS} \
    --set rabbitmqUrl="amqp://${RABBITMQ_USERNAME}:${RABBITMQ_PASSWORD}@drycc-rabbitmq.drycc.svc.${CLUSTER_DOMAIN}:5672/drycc" \
    --namespace drycc-helmbroker --create-namespace --wait -f - <<EOF
repositories:
- name: drycc-helmbroker
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
  url: http://${HELMBROKER_USERNAME}:${HELMBROKER_PASSWORD}@drycc-helmbroker.drycc-helmbroker.svc.${CLUSTER_DOMAIN}
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
