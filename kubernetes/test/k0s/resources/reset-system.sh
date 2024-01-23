#!/usr/bin/env bash
set -e
set -o noglob

[ $(id -u) -eq 0 ] || exec sudo $0 $@

# Remove containerd config
rm -rf /etc/k0s/containerd.d

# Remove local storage data
rm -rf /var/openebs/local

# Reboot
(sleep 30 && systemctl reboot)&
