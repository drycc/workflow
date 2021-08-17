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

function clean_before_exit {
    # delay before exiting, so stdout/stderr flushes through the logging system
    rm -rf helm-broker
    sleep 3
}
trap clean_before_exit EXIT

if [[ "${INSTALL_K3S_MIRROR}"=="cn" ]] ; then
  k3s_install_url="http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh"
else
  k3s_install_url="https://get.k3s.io"
fi
if [[ -z "${K3S_URL}" ]] ; then
  INSTALL_K3S_EXEC="server --no-flannel --cluster-cidr=10.233.0.0/16"
else
  INSTALL_K3S_EXEC="agent --no-flannel"
fi

export INSTALL_K3S_EXEC='--no-flannel'

alias install-k3s="curl -sfL "${k3s_install_url}" | sh - $@"

install-k3s

curl -sfL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash -

helm repo add cilium https://helm.cilium.io/
helm repo add longhorn https://charts.longhorn.io
helm repo add jetstack https://charts.jetstack.io
helm repo add svc-cat https://kubernetes-sigs.github.io/service-catalog
helm repo add drycc https://charts.drycc.cc/${CHANNEL:-stable}
helm repo update
git clone --dept 1 https://github.com/kyma-project/helm-broker


helm install cilium --set operator.replicas=1 cilium/cilium --namespace kube-system
helm install longhorn --create-namespace --set persistence.defaultClass=false --set persistence.defaultClassReplicaCount=1 longhorn/longhorn --namespace longhorn-system
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
helm install catalog svc-cat/catalog --set asyncBindingOperationsEnabled=true --namespace catalog --create-namespace
helm install helm-broker --set global.helm_broker.dir=/ --set global.helm_controller.dir=/ helm-broker/charts/helm-broker/  --namespace helm-broker --create-namespace


echo -e "\\033[32m---> Waiting cert-manager...\\033[0m"
while [ $(kubectl get pods -n cert-manager|grep Running|wc -l) -le 2 ]
do
    kubectl get pods -n cert-manager
    sleep 10
done

helm install drycc drycc/workflow \
  --set builder.service.type=LoadBalancer \
  --set global.platform_domain="${PLATFORM_DOMAIN}" \
  --set global.ingress_class=traefik \
  --set fluentd.daemon_environment.CONTAINER_TAIL_PARSER_TYPE="/^(?<time>.+) (?<stream>stdout|stderr)( (?<tags>.))? (?<log>.*)$/" \
  --set controller.app_storage_class=longhorn \
  --set minio.persistence.enabled=true \
  --set minio.persistence.size=5Gi \
  --set minio.persistence.storageClass="longhorn" \
  --set rabbitmq.persistence.enabled=true \
  --set rabbitmq.persistence.size=5Gi \
  --set rabbitmq.persistence.storageClass="longhorn" \
  --set influxdb.persistence.enabled=true \
  --set influxdb.persistence.size=5Gi \
  --set influxdb.persistence.storageClass="longhorn" \
  --set monitor.grafana.persistence.enabled=true \
  --set monitor.grafana.persistence.size=5Gi \
  --set monitor.grafana.persistence.storageClass="longhorn" \
  --namespace drycc \
  --create-namespace
