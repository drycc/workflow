#!/usr/bin/env bash
set -eo pipefail
shopt -s expand_aliases

/usr/local/bin/k3s-killall.sh
/usr/local/bin/k3s-uninstall.sh

if [[ -n "${K3S_DATA_DIR}" ]] ; then
    rm -rf  "${K3S_DATA_DIR}/rancher"
fi

if [[ -n "${LONGHORN_DATA_PATH}" ]] ; then
    rm -rf  "${LONGHORN_DATA_PATH}/longhorn"
fi

rm -rf /etc/rancher
rm -rf /var/lib/longhorn
rm -rf /usr/local/bin/helm ~/.config/helm
