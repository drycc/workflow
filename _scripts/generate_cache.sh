#!/usr/bin/env bash
set -eo pipefail
shopt -s expand_aliases

tmp=$(mktemp -d)

function clean_before_exit {
    # delay before exiting, so stdout/stderr flushes through the logging system
    rm -rf $tmp
    sleep 3
}
trap clean_before_exit EXIT
cd $tmp

helm repo add cilium https://helm.cilium.io/
helm repo add metallb https://metallb.github.io/metallb
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add longhorn https://charts.longhorn.io
helm repo add jetstack https://charts.jetstack.io
helm repo add svc-cat https://kubernetes-sigs.github.io/service-catalog
helm repo update

helm fetch cilium/cilium
helm fetch metallb/metallb
helm fetch ingress-nginx/ingress-nginx
helm fetch longhorn/longhorn
helm fetch jetstack/cert-manager
helm fetch svc-cat/catalog

for tar in `ls $tmp | grep .tgz`
do
    curl -u $CHARTMUSEUM_USERNAME:$CHARTMUSEUM_PASSWORD -F chart=@$tar "$CHARTMUSEUM_API/api/$([ -z $DRONE_TAG ] && echo testing || echo stable)/charts"
done
