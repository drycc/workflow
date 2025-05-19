#!/usr/bin/env bash
set -eo pipefail
shopt -s expand_aliases

# clean cilium
ip link delete cilium_host > /dev/null 2>&1 || true
ip link delete cilium_net > /dev/null 2>&1 || true
ip link delete cilium_vxlan > /dev/null 2>&1 || true
ip link delete nodelocaldns > /dev/null 2>&1 || true
iptables-save | grep -iv cilium | iptables-restore || true
ip6tables-save | grep -iv cilium | ip6tables-restore || true

if [[ -x /usr/local/bin/k3s-killall.sh ]] ; then
    /usr/local/bin/k3s-killall.sh
fi

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

rm -rf /etc/cni
rm -rf /etc/rancher
rm -rf /var/lib/rancher
rm -rf /usr/local/bin/crun
rm -rf /usr/local/bin/helm ~/.config/helm

rm -rf /opt/kata /usr/local/bin/containerd-shim-kata-v2 /usr/local/bin/kata-collect-data.sh /usr/local/bin/kata-runtime
