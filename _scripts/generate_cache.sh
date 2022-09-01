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
helm repo add traefik https://helm.traefik.io/traefik
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm fetch cilium/cilium
helm fetch metallb/metallb
helm fetch traefik/traefik
helm fetch jetstack/cert-manager

for tar in `ls $tmp | grep .tgz`
do
    helm push $tar oci://$DRYCC_REGISTRY/$([ -z $DRONE_TAG ] && echo charts-testing || echo charts)
done
