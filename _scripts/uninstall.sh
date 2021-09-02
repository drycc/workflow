#!/usr/bin/env bash
set -eo pipefail
shopt -s expand_aliases

/usr/local/bin/k3s-killall.sh
/usr/local/bin/k3s-uninstall.sh

rm -rf /etc/rancher
rm -rf /usr/local/bin/helm ~/.config/helm
