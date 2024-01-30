#!/usr/bin/env bash
set -e
set -o noglob

[ $(id -u) -eq 0 ] || exec sudo $0 $@

remove_interfaces() {
  ip link show 2>/dev/null | grep 'cilium' | while read ignore iface ignore; do
      iface=${iface%%@*}
      [ -z "$iface" ] || (ip link delete $iface || true)
  done
}

reset_iptables() {
    iptables -t nat -F
    iptables -t mangle -F
    iptables -t filter -F
    iptables -t raw -F
    iptables -X
    ip6tables -t nat -F
    ip6tables -t mangle -F
    ip6tables -t filter -F
    ip6tables -t raw -F
    ip6tables -X
}

do_unmount_and_remove() {
    set +x
    while read -r _ path _; do
        case "$path" in $1*) echo "$path" ;; esac
    done < /proc/self/mounts | sort -r | xargs -r -t -n 1 sh -c 'umount -f "$0" && rm -rf "$0"'
    set -x
}

do_unmount_and_remove '/run/netns/cni-'
ip netns show 2>/dev/null | grep cni- | xargs -r -t -n 1 ip netns delete
remove_interfaces
reset_iptables
rm -rf /var/lib/cni
rm -rf /etc/cni/net.d
