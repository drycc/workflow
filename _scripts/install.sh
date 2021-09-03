#!/usr/bin/env bash
set -eo pipefail
shopt -s expand_aliases

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

function clean_before_exit {
    # delay before exiting, so stdout/stderr flushes through the logging system
    sleep 3
}
trap clean_before_exit EXIT

if [[ "${INSTALL_K3S_MIRROR}" == "cn" ]] ; then
  mkdir -p /etc/rancher/k3s
  cat << EOF > "/etc/rancher/k3s/registries.yaml"
mirrors:
  "docker.io":
    endpoint:
      - "http://hub-mirror.c.163.com"
      - "https://registry-1.docker.io"
EOF
  k3s_install_url="http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh"
else
  k3s_install_url="https://get.k3s.io"
fi
if [[ -z "${K3S_URL}" ]] ; then
  INSTALL_K3S_EXEC="server --flannel-backend=none --disable=traefik --disable=servicelb --cluster-cidr=10.233.0.0/16"
else
  INSTALL_K3S_EXEC="agent --flannel-backend=none"
fi

alias install-k3s="curl -sfL "${k3s_install_url}" |sh - $@"
export INSTALL_K3S_EXEC
install-k3s
mount bpffs -t bpf /sys/fs/bpf

curl -sfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash -

helm repo add cilium https://helm.cilium.io/
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add longhorn https://charts.longhorn.io
helm repo add jetstack https://charts.jetstack.io
helm repo add svc-cat https://kubernetes-sigs.github.io/service-catalog
helm repo add drycc https://charts.drycc.cc/${CHANNEL:-stable}
helm repo update

helm install cilium --set operator.replicas=1 cilium/cilium --namespace kube-system
helm install metallb bitnami/metallb --namespace kube-system -f - <<EOF
configInline:
  address-pools:
   - name: default
     protocol: layer2
     addresses:
     - ${METALLB_ADDRESS_POOLS:-172.16.0.0/12}
EOF
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace kube-system
helm install longhorn --create-namespace --set persistence.defaultClass=false --set persistence.defaultClassReplicaCount=1 longhorn/longhorn --namespace longhorn-system
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
helm install catalog svc-cat/catalog --set asyncBindingOperationsEnabled=true --namespace catalog --create-namespace --wait

echo -e "\\033[32m---> Waiting cert-manager...\\033[0m"
while [ $(kubectl get pods -n cert-manager|grep Running|wc -l) -le 2 ]
do
    kubectl get pods -n cert-manager
    sleep 10
done

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

HELMBROKER_USERNAME=$(cat /proc/sys/kernel/random/uuid)
HELMBROKER_PASSWORD=$(cat /proc/sys/kernel/random/uuid)

echo -e "\\033[32m---> Start installing helmbroker...\\033[0m"

helm install helmbroker drycc/helmbroker \
  --set platform_domain="cluster.local" \
  --set persistence.storageClass="longhorn" \
  --set persistence.size=${HELMBROKER_PERSISTENCE_SIZE:-5Gi} \
  --set platform_domain=${PLATFORM_DOMAIN} \
  --set username=${HELMBROKER_USERNAME} \
  --set password=${HELMBROKER_PASSWORD} \
  --set environment.HELMBROKER_CELERY_BROKER="amqp://${RABBITMQ_USERNAME}:${RABBITMQ_PASSWORD}@drycc-rabbitmq-0.drycc-rabbitmq.drycc.svc.cluster.local:5672/drycc" \
  --namespace drycc --create-namespace --wait

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
  url: http://${HELMBROKER_USERNAME}:${HELMBROKER_PASSWORD}@drycc-helmbroker.${PLATFORM_DOMAIN}
EOF

echo -e "\\033[32m---> Please save the following information for future use.\\033[0m"
echo -e "\\033[32m---> Rabbitmq username: $RABBITMQ_USERNAME\\033[0m"
echo -e "\\033[32m---> Rabbitmq password: $RABBITMQ_PASSWORD\\033[0m"
echo -e "\\033[32m---> Helmbroker username: $HELMBROKER_USERNAME\\033[0m"
echo -e "\\033[32m---> Helmbroker password: $HELMBROKER_PASSWORD\\033[0m"
echo -e "\\033[32m---> Installation complete, enjoy life...\\033[0m"
