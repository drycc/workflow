#!/usr/bin/env bash
set -eo pipefail
shopt -s expand_aliases

# default vars
GATEWAY_CLASS="istio"
CLUSTER_CIDR=${CLUSTER_CIDR:-"10.42.0.0/16"}
SERVICE_CIDR=${SERVICE_CIDR:-"10.43.0.0/16"}
CLUSTER_DOMAIN=${CLUSTER_DOMAIN:-"cluster.local"}
CERT_MANAGER_ENABLED="${CERT_MANAGER_ENABLED:-false}"
DRYCC_REGISTRY="${DRYCC_REGISTRY:-registry.drycc.cc}"
CHARTS_URL=oci://registry.drycc.cc/$([ "$CHANNEL" == "stable" ] && echo charts || echo charts-testing)
CONTAINERD_RUNTIMES="${CONTAINERD_RUNTIMES:-runc}"
CONTAINERD_CONFIG_PATH="${CONTAINERD_CONFIG_PATH:-/var/lib/rancher/k3s/agent/etc/containerd}"
mkdir -p "${CONTAINERD_CONFIG_PATH}"
CONTAINERD_CONFIG_FILE="${CONTAINERD_CONFIG_PATH}/config.toml.tmpl"
REGISTRY_CONFIG_PATH="${REGISTRY_CONFIG_PATH:-/etc/rancher/k3s/}"
mkdir -p "${REGISTRY_CONFIG_PATH}"
REGISTRY_CONFIG_FILE="${REGISTRY_CONFIG_PATH}/registries.yaml"

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
  else
    # Kube hostport depends on iptables
    echo -e "\\033[33m---> The iptables does not exist...\\033[0m"
    exit 1
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

function install_crun_runtime {
  echo -e "\\033[32m---> Start install crun runtime\\033[0m"
  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    crun_base_url="https://drycc-mirrors.drycc.cc/containers"
  else
    crun_base_url="https://github.com/containers"
  fi
  crun_version=$(curl -Ls ${crun_base_url}/crun/releases|grep /containers/crun/releases/tag/ | sed -E 's/.*\/containers\/crun\/releases\/tag\/([0-9\.]{1,}(-rc.[0-9]{1,})?)".*/\1/g' | head -1)
  crun_download_url=${crun_base_url}/crun/releases/download/${crun_version}/crun-${crun_version}-linux-${ARCH}
  curl -sfL "${crun_download_url}" -o /usr/local/bin/crun
  chmod a+rx /usr/local/bin/crun
  echo -e "\\033[32m---> crun runtime install completed!\\033[0m"
}

function install_kata_runtime {
  echo -e "\\033[32m---> Start install kata runtime\\033[0m"
  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    kata_base_url="https://drycc-mirrors.drycc.cc/kata-containers"
  else
    kata_base_url="https://github.com/kata-containers"
  fi

  kata_version=$(curl -Ls ${kata_base_url}/kata-containers/releases|grep /kata-containers/kata-containers/releases/tag/ | sed -E 's/.*\/kata-containers\/kata-containers\/releases\/tag\/([0-9\.]{1,}(-rc.[0-9]{1,})?)".*/\1/g' | head -1)
  kata_package=kata-static-${kata_version}-${ARCH}.tar.xz
  kata_download_url=${kata_base_url}/kata-containers/releases/download/${kata_version}/${kata_package}

  curl -sfL "${kata_download_url}" -o ${kata_package}
  tar xvf ${kata_package} -C /
  ln -s /opt/kata/bin/containerd-shim-kata-v2 /usr/local/bin/containerd-shim-kata-v2
  ln -s /opt/kata/bin/kata-collect-data.sh /usr/local/bin/kata-collect-data.sh
  ln -s /opt/kata/bin/kata-runtime /usr/local/bin/kata-runtime
  rm -rf ${kata_package}
  echo -e "\\033[32m---> Kata runtime install completed!\\033[0m"
}

function install_runtime {
  readarray -d , -t containerd_runtimes <<<"$CONTAINERD_RUNTIMES"
  if [[ "$CONTAINERD_RUNTIMES" =~ "crun" ]]; then
    containerd_default_runtime="crun"
  else
    containerd_default_runtime="runc"
  fi
  cat << EOF > "${CONTAINERD_CONFIG_FILE}"
{{ template "base" . }}

[plugins.cri.containerd]
  snapshotter = "overlayfs"
  default_runtime_name = "${containerd_default_runtime}"
  disable_snapshot_annotations = true
EOF

  for (( n=0; n < ${#containerd_runtimes[*]}; n++ ))
  do
    if [[ "${containerd_runtimes[n]}" == "kata" ]]; then
      install_kata_runtime
      sed -i s/sandbox_cgroup_only=false/sandbox_cgroup_only=true/g /opt/kata/share/defaults/kata-containers/configuration.toml
      cat << EOF >> "${CONTAINERD_CONFIG_FILE}"
[plugins.cri.containerd.runtimes.kata]
  runtime_type = "io.containerd.kata.v2"
  privileged_without_host_devices = true
  pod_annotations = ["io.katacontainers.*"]
  container_annotations = ["io.katacontainers.*"]
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata.options]
  ConfigPath = "/opt/kata/share/defaults/kata-containers/configuration.toml"
EOF
    elif [[ "${containerd_runtimes[n]}" == "crun" ]]; then
      install_crun_runtime
      cat << EOF >> "${CONTAINERD_CONFIG_FILE}"
[plugins.cri.containerd.runtimes.crun]
  runtime_type = "io.containerd.runc.v2"
[plugins.cri.containerd.runtimes.crun.options]
  SystemdCgroup = true
EOF
    else
      cat << EOF >> "${CONTAINERD_CONFIG_FILE}"
[plugins.cri.containerd.runtimes.runc]
  runtime_type = "io.containerd.runc.v2"
[plugins.cri.containerd.runtimes.runc.options]
  SystemdCgroup = true
EOF
    fi
  done
}

function configure_registry {
  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]]; then
    cat << EOF >> "${REGISTRY_CONFIG_FILE}"
mirrors:
  docker.io:
    endpoint:
    - "https://docker.m.daocloud.io"
    - "https://docker-mirror.drycc.cc"
    - "https://registry-1.docker.io"
  quay.io:
    endpoint:
    - "https://quay.m.daocloud.io"
    - "https://quay-mirror.drycc.cc"
    - "https://quay.io"
  gcr.io:
    endpoint:
    - "https://gcr.m.daocloud.io"
    - "https://quay-mirror.drycc.cc"
    - "https://gcr.io"
  registry.k8s.io:
    endpoint:
    - "https://k8s.m.daocloud.io"
    - "https://k8s-mirror.drycc.cc"
    - "https://registry.k8s.io"
EOF
  fi
}

function configure_k3s_mirrors {
  echo -e "\\033[32m---> Start configuring k3s mirrors\\033[0m"
  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    INSTALL_K3S_MIRROR="${INSTALL_DRYCC_MIRROR}"
    k3s_install_url="https://drycc-mirrors.drycc.cc/get-k3s/"
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
  echo -e "\\033[32m---> Configuring k3s mirrors finish\\033[0m"
}

function install_k3s_server {
  configure_os
  install_runtime
  configure_registry
  configure_k3s_mirrors
  INSTALL_K3S_EXEC="server ${INSTALL_K3S_EXEC} --embedded-registry --flannel-backend=none  --disable-network-policy --disable=traefik --disable=servicelb --disable-kube-proxy --cluster-cidr=${CLUSTER_CIDR} --service-cidr=${SERVICE_CIDR} --cluster-domain=${CLUSTER_DOMAIN}"
  if [[ -n "${K3S_DATA_DIR}" ]] ; then
    INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC --data-dir=${K3S_DATA_DIR}/rancher/k3s"
  fi
  if [[ -z "${K3S_URL}" ]] ; then
    INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC --cluster-init"
  fi
  curl -sfL "${k3s_install_url}" |INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC" sh -s -

  readarray -d , -t containerd_runtimes <<<"$CONTAINERD_RUNTIMES"
  for (( n=0; n < ${#containerd_runtimes[*]}; n++ ))
  do
    kubectl apply -f - <<EOF
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: ${containerd_runtimes[n]}
handler: ${containerd_runtimes[n]}
EOF
  done
}

function install_k3s_agent {
  configure_os
  install_runtime
  configure_registry
  configure_k3s_mirrors
  if [[ -n "${K3S_DATA_DIR}" ]] ; then
    INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC --embedded-registry --data-dir=${K3S_DATA_DIR}/rancher/k3s"
  fi
  curl -sfL "${k3s_install_url}" |INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC" sh -s -
}

function install_longhorn {
  options=${1:-""}
  helm repo add longhorn https://drycc-mirrors.drycc.cc/longhorn-charts
  helm repo update
  if [[ -z "${LONGHORN_CONFIG_FILE}" ]] ; then
    echo -e "\\033[32m---> Longhorn using the default configuration.\\033[0m"
    helm upgrade --install longhorn longhorn/longhorn \
      --set csi.attacherReplicaCount=1 \
      --set csi.provisionerReplicaCount=1 \
      --set csi.resizerReplicaCount=1 \
      --set csi.snapshotterReplicaCount=1 \
      --set persistence.defaultClass=false \
      --set longhornUI.replicas=1 \
      --set persistence.defaultClassReplicaCount=1 \
      --namespace longhorn-system \
      --create-namespace $options --wait
  else
    helm upgrade --install longhorn longhorn/longhorn -f "${LONGHORN_CONFIG_FILE}" --wait
  fi
  echo -e "\\033[32m---> Longhorn install completed!\\033[0m"
}

function install_mountpoint {
  options=${1:-""}
  helm repo add aws-mountpoint-s3-csi-driver https://drycc-mirrors.drycc.cc/mountpoint-charts
  helm repo update

  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    mountpoint_api_url=https://drycc-mirrors.drycc.cc/drycc-addons/mountpoint-s3-csi-driver
  else
    mountpoint_api_url=https://github.com/drycc-addons/mountpoint-s3-csi-driver
  fi
  version=$(curl -Ls $mountpoint_api_url/releases|grep /drycc-addons/mountpoint-s3-csi-driver/releases/tag/ | sed -E 's/.*\/drycc-addons\/mountpoint-s3-csi-driver\/releases\/tag\/v([0-9\.]{1,}(-rc.[0-9]{1,})?)".*/\1/g' | head -1)

  helm upgrade --install aws-mountpoint-s3-csi-driver aws-mountpoint-s3-csi-driver/aws-mountpoint-s3-csi-driver \
    --set experimental.podMounter=true \
    --set image.repository=registry.drycc.cc/drycc-addons/mountpoint-s3-csi-driver \
    --set image.tag=${version} \
    --namespace kube-system $options --wait
  echo -e "\\033[32m---> Longhorn install completed!\\033[0m"
}

function check_metallb {
  if [[ "${METALLB_CONFIG_FILE}" && ! -f "${METALLB_CONFIG_FILE}" ]] ; then
    echo -e "\\033[33m---> The path ${METALLB_CONFIG_FILE} does not exist...\\033[0m"
    exit 1
  fi
}

# Best practices
#
# 1. Jumbo frames, change MTU(9000).
# 2. Big tcp, enableIPv6BIGTCP/enableIPv4BIGTCP.
# 3. Set `routingMode=native` and `ipv4NativeRoutingCIDR`.
# 4. Change `loadBalancer.mode` to dsr(requires `routingMode=native`).
# 5. Set `loadBalancer.acceleration=native`(requires hardware support).
#
# The following is a general configuration without optimization.
function install_network() {
  options=${1:-""}
  echo -e "\\033[32m---> Start install network...\\033[0m"
  kubernetes_service_host=(`ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'`)
  helm upgrade --install cilium $CHARTS_URL/cilium \
    --set endpointHealthChecking.enabled=false \
    --set healthChecking=false \
    --set operator.replicas=1 \
    --set sysctlfix.enabled=true \
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
    --set envoy.enabled=false \
    --namespace kube-system $options --wait
  echo -e "\\033[32m---> Network install completed!\\033[0m"
}

function install_metallb() {
  check_metallb
  options=${1:-""}
  echo -e "\\033[32m---> Start install metallb...\\033[0m"
  helm upgrade --install metallb $CHARTS_URL/metallb \
    --set speaker.frr.enabled=true \
    --namespace metallb \
    --create-namespace $options --wait

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
  echo -e "\\033[32m---> Metallb install completed!\\033[0m"
}

function install_gateway() {
  options=${1:-""}
  echo -e "\\033[32m---> Start install gateway...\\033[0m"
  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    gateway_api_url=https://drycc-mirrors.drycc.cc/kubernetes-sigs/gateway-api
  else
    gateway_api_url=https://github.com/kubernetes-sigs/gateway-api
  fi
  version=$(curl -Ls $gateway_api_url/releases|grep /kubernetes-sigs/gateway-api/releases/tag/ | sed -E 's/.*\/kubernetes-sigs\/gateway-api\/releases\/tag\/(v[0-9\.]{1,}(-rc.[0-9]{1,})?)".*/\1/g' | head -1)

  helm repo add istio https://drycc-mirrors.drycc.cc/istio-charts
  helm repo update
  kubectl apply -f $gateway_api_url/releases/download/${version}/experimental-install.yaml
  helm upgrade --install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace --wait $options
  helm upgrade --install istio-istiod istio/istiod -n istio-system \
    --set pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true \
    --set pilot.env.PILOT_ENABLE_QUIC_LISTENERS=true \
    --wait $options
  helm upgrade --install istio-gateway istio/gateway -n istio-gateway --create-namespace --wait $options
  echo -e "\\033[32m---> Gateway install completed!\\033[0m"
}

function install_cert_manager() {
  options=${1:-""}
  echo -e "\\033[32m---> Start install cert-manager...\\033[0m"
  helm upgrade --install cert-manager $CHARTS_URL/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set clusterResourceNamespace=drycc \
    --set "extraArgs={--feature-gates=ExperimentalGatewayAPISupport=true}" \
    --set crds.enabled=true --wait $options
  echo -e "\\033[32m---> Cert-manager install completed!\\033[0m"
}

function install_catalog() {
  service_catalog_version="canary"
  if [[ "$CHANNEL" == "stable" ]]; then
    if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
      service_catalog_url=https://drycc-mirrors.drycc.cc/drycc-addons/service-catalog
    else
      service_catalog_url=https://github.com/drycc-addons/service-catalog
    fi
    service_catalog_version=$(curl -Ls $service_catalog_url/releases|grep /drycc-addons/service-catalog/releases/tag/ | sed -E 's/.*\/drycc-addons\/service-catalog\/releases\/tag\/(v[0-9\.]{1,}(-rc.[0-9]{1,})?)".*/\1/g' | head -1)
  fi

  options=${1:-""}
  echo -e "\\033[32m---> Start install catalog...\\033[0m"
  helm upgrade --install catalog $CHARTS_URL/catalog \
    --set asyncBindingOperationsEnabled=true \
    --set image=registry.drycc.cc/drycc-addons/service-catalog:${service_catalog_version#v} \
    --namespace catalog \
    --create-namespace --wait $options
  echo -e "\\033[32m---> Catalog install completed!\\033[0m"
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
  options=${1:-""}
  echo -e "\\033[32m---> Start install workflow...\\033[0m"
  if [[ "$CHANNEL" == "stable" ]]; then
    if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
      FILER_VERSION=$(curl -Ls https://drycc-mirrors.drycc.cc/drycc/filer/releases|grep /drycc/filer/releases/tag/ | sed -E 's/.*\/drycc\/filer\/releases\/tag\/(v[0-9\.]{1,}(-rc.[0-9]{1,})?)".*/\1/g' | head -1)
    else
      FILER_VERSION=$(curl -Ls https://github.com/drycc/filer/releases|grep /drycc/filer/releases/tag/ | sed -E 's/.*\/drycc\/filer\/releases\/tag\/(v[0-9\.]{1,}(-rc.[0-9]{1,})?)".*/\1/g' | head -1)
    fi
    FILER_IMAGE=${DRYCC_REGISTRY}/drycc/filer:$(sed 's#v##' <<< $FILER_VERSION)
    FILER_IMAGE_PULL_POLICY="IfNotPresent"
  else
    FILER_IMAGE=${DRYCC_REGISTRY}/drycc/filer:canary
    FILER_IMAGE_PULL_POLICY="Always"
  fi

cat << EOF > "/tmp/drycc-values.yaml"
global:
  clusterDomain: ${CLUSTER_DOMAIN}
  platformDomain: ${PLATFORM_DOMAIN}
  certManagerEnabled: ${CERT_MANAGER_ENABLED}

builder:
  replicas: ${BUILDER_REPLICAS:-1}
  imageRegistry: ${DRYCC_REGISTRY}

gateway:
  gatewayClass: ${GATEWAY_CLASS}

database:
  imageRegistry: ${DRYCC_REGISTRY}
  resources:
    limits:
      memory: 2512Mi
      hugepages-2Mi: 256Mi
  persistence:
    enabled: true
    size: ${DATABASE_PERSISTENCE_SIZE:-5Gi}
    storageClass: ${DATABASE_PERSISTENCE_STORAGE_CLASS:-""}

fluentbit:
  imageRegistry: ${DRYCC_REGISTRY}

controller:
  apiReplicas: ${CONTROLLER_API_REPLICAS:-1}
  celeryReplicas: ${CONTROLLER_CELERY_REPLICAS:-1}
  webhookReplicas: ${CONTROLLER_WEBHOOK_REPLICAS:-1}
  imageRegistry: ${DRYCC_REGISTRY}
  appRuntimeClass: ${CONTROLLER_APP_RUNTIME_CLASS:-""}
  appGatewayClass: ${CONTROLLER_APP_GATEWAY_CLASS:-$GATEWAY_CLASS}
  appStorageClass: ${CONTROLLER_APP_STORAGE_CLASS:-"longhorn"}
  filerImage: ${FILER_IMAGE}
  filerImagePullPolicy: ${FILER_IMAGE_PULL_POLICY}

valkey:
  imageRegistry: ${DRYCC_REGISTRY}
  persistence:
    enabled: true
    size: ${VALKEY_PERSISTENCE_SIZE:-5Gi}
    storageClass: ${VALKEY_PERSISTENCE_STORAGE_CLASS:-""}

storage:
  zones: 1
  drives: 1
  replicas: 4
  imageRegistry: ${DRYCC_REGISTRY}
  persistence:
    enabled: true
    size: ${STORAGE_PERSISTENCE_SIZE:-5Gi}
    storageClass: ${STORAGE_PERSISTENCE_STORAGE_CLASS:-""}

imagebuilder:
  imageRegistry: ${DRYCC_REGISTRY}

logger:
  replicas: ${LOGGER_REPLICAS:-1}
  imageRegistry: ${DRYCC_REGISTRY}

grafana:
  imageRegistry: ${DRYCC_REGISTRY}
  persistence:
    enabled: true
    size: ${MONITOR_GRAFANA_PERSISTENCE_SIZE:-5Gi}
    storageClass: ${MONITOR_GRAFANA_PERSISTENCE_STORAGE_CLASS:-""}

passport:
  replicas: ${PASSPORT_REPLICAS:-1}
  imageRegistry: ${DRYCC_REGISTRY}
  adminUsername: ${DRYCC_ADMIN_USERNAME}
  adminPassword: ${DRYCC_ADMIN_PASSWORD}

registry:
  replicas: ${REGISTRY_REPLICAS:-1}
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
  if [[ -z "${VICTORIAMETRICS_CONFIG_FILE}" ]] ; then
    VICTORIAMETRICS_CONFIG_FILE="/tmp/drycc-victoriametrics-values.yaml"
    cat << EOF > "${VICTORIAMETRICS_CONFIG_FILE}"
victoriametrics:
  enabled: true
  vmagent:
    replicas: 1
    persistence:
      enabled: true
      size: ${VICTORIAMETRICS_VMAGENT_PERSISTENCE_SIZE:-10Gi}
      storageClass: ${VICTORIAMETRICS_VMAGENT_PERSISTENCE_STORAGE_CLASS:-""}
  vminsert:
    replicas: 1
  vmselect:
    replicas: 1
  vmstorage:
    replicas: 1
    persistence:
      enabled: true
      size: ${VICTORIAMETRICS_VMSTORAGE_PERSISTENCE_SIZE:-10Gi}
      storageClass: ${VICTORIAMETRICS_VMSTORAGE_PERSISTENCE_STORAGE_CLASS:-""}
EOF
    export VICTORIAMETRICS_CONFIG_FILE
  fi

  helm upgrade --install drycc $CHARTS_URL/workflow \
    --namespace drycc \
    --values /tmp/drycc-values.yaml \
    --values /tmp/drycc-mirror-values.yaml \
    --values ${VICTORIAMETRICS_CONFIG_FILE} \
    --create-namespace --wait --timeout 30m0s $options
  echo -e "\\033[32m---> Workflow install completed!\\033[0m"
}

function install_helmbroker {
  if [[ "${INSTALL_DRYCC_MIRROR}" == "cn" ]] ; then
    addons_base_url="https://drycc-mirrors.drycc.cc/drycc-addons/addons"
  else
    addons_base_url="https://github.com/drycc-addons/addons"
  fi
  version="latest"
  if [[ "$CHANNEL" == "stable" ]]; then
    for version in $(curl -Ls "${addons_base_url}"/releases|grep /drycc-addons/addons/releases/tag/ | sed -E 's/.*\/drycc-addons\/addons\/releases\/tag\/(v[0-9]{1,})".*/\1/g'); do
      if [[ "$version" != "latest" ]]; then
        break
      fi
    done
  fi
  addons_url="${addons_base_url}/releases/download/${version}/index.yaml"

  options=${1:-""}
  local VALKEY_PASSWORD=$(kubectl get secrets -n drycc valkey-creds -o jsonpath="{.data.password}"| base64 -d)
  local HELMBROKER_USERNAME=${HELMBROKER_USERNAME:-$(cat /proc/sys/kernel/random/uuid)}
  local HELMBROKER_PASSWORD=${HELMBROKER_PASSWORD:-$(cat /proc/sys/kernel/random/uuid)}

  echo -e "\\033[32m---> Start install helmbroker...\\033[0m"

  helm upgrade --install helmbroker $CHARTS_URL/helmbroker \
    --set valkey.enabled=false \
    --set gateway.gatewayClass=${GATEWAY_CLASS} \
    --set global.clusterDomain=${CLUSTER_DOMAIN} \
    --set global.platformDomain=${PLATFORM_DOMAIN} \
    --set global.certManagerEnabled=${CERT_MANAGER_ENABLED} \
    --set persistence.size=${HELMBROKER_PERSISTENCE_SIZE:-5Gi} \
    --set persistence.storageClass=${HELMBROKER_PERSISTENCE_STORAGE_CLASS:-"longhorn"} \
    --set username=${HELMBROKER_USERNAME} \
    --set password=${HELMBROKER_PASSWORD} \
    --set replicas=${HELMBROKER_REPLICAS} \
    --set valkeyUrl=redis://:${VALKEY_PASSWORD}@drycc-valkey.drycc.svc.${CLUSTER_DOMAIN}:16379/11 \
    --set celeryReplicas=${HELMBROKER_CELERY_REPLICAS} \
    --namespace drycc-helmbroker --create-namespace $options --wait -f - <<EOF
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
  echo -e "\\033[32m---> Helmbroker install completed!\\033[0m"
}

function upgrade {
  install_network --reset-then-reuse-values
  install_metallb --reset-then-reuse-values
  install_gateway --reset-then-reuse-values
  install_cert_manager --reset-then-reuse-values
  install_catalog --reset-then-reuse-values
  install_longhorn --reset-then-reuse-values
  install_mountpoint --reset-then-reuse-values
  install_drycc --reset-then-reuse-values
  install_helmbroker --reset-then-reuse-values
  echo -e "\\033[32m---> Upgrade complete, enjoy life...\\033[0m"
}

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

if [[ -z "$@" ]] ; then
  check_drycc
  check_metallb
  install_k3s_server
  install_helm
  install_components
  install_longhorn
  install_mountpoint
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
