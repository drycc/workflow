#!/usr/bin/env bash
set -eo pipefail
shopt -s expand_aliases

ip link delete cilium_host
ip link delete cilium_net
ip link delete cilium_vxlan
ip link delete nodelocaldns

/usr/local/bin/k3s-killall.sh

if [[ -x /usr/local/bin/k3s-uninstall.sh ]] ; then
    /usr/local/bin/k3s-uninstall.sh
fi

if [[ -x /usr/local/bin/k3s-agent-uninstall.sh ]] ; then
    /usr/local/bin/k3s-agent-uninstall.sh
fi

if [[ -n "${K3S_DATA_DIR}" ]] ; then
    rm -rf  "${K3S_DATA_DIR}/rancher"
fi

iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat && iptables -P FORWARD ACCEPT

rm -rf /etc/rancher
rm -rf /etc/cni/net.d/*
rm -rf /var/lib/rancher/
rm -rf /usr/local/bin/*runsc* /usr/local/bin/crun
rm -rf /usr/local/bin/helm ~/.config/helm
