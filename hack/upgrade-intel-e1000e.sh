#!/usr/bin/env bash
set -euo pipefail

# Install Intel e1000e driver
# https://downloadcenter.intel.com/download/15817/Intel-Network-Adapter-Driver-for-PCIe-Intel-Gigabit-Ethernet-Network-Connections-Under-Linux-?v=t
# Run with sudo
# Reboot after completion


echo "Downloading and extracting driver package..."
wget https://downloadmirror.intel.com/15817/eng/e1000e-3.8.4.tar.gz
tar zxf e1000e-3.8.4.tar.gz

echo "Installing build dependencies..."
apt-get install -y build-essential linux-headers-$(uname -r)
cd e1000e-3.8.4/src/

echo "Building module and updating initramfs..."
make install
update-initramfs -u

if [[ -f /etc/modules-load.d/e1000e.conf ]]; then
    echo "e1000e is already loaded"
else
    echo "Adding e1000e to modules file"
    echo e1000e | tee /etc/modules-load.d/e1000e.conf
fi

if [[ $(modinfo -F version e1000e) == "3.8.4-NAPI" ]]; then
    echo "Driver successfully installed!"
else
    echo "Something went wrong..."
    exit 1
fi

exit 0
