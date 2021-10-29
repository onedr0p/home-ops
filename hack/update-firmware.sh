#!/usr/bin/env bash

cd /tmp

wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.12/amd64/linux-headers-5.12.0-051200_5.12.0-051200.202104252130_all.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.12/amd64/linux-headers-5.12.0-051200-generic_5.12.0-051200.202104252130_amd64.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.12/amd64/linux-image-unsigned-5.12.0-051200-generic_5.12.0-051200.202104252130_amd64.deb
wget -c https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.12/amd64/linux-modules-5.12.0-051200-generic_5.12.0-051200.202104252130_amd64.deb

dpkg -i *.deb

curl -L -o "/lib/firmware/i915/bxt_guc_49.0.1.bin" "https://anduin.linuxfromscratch.org/sources/linux-firmware/i915/bxt_guc_49.0.1.bin"
curl -L -o "/lib/firmware/i915/cml_guc_49.0.1.bin" "https://anduin.linuxfromscratch.org/sources/linux-firmware/i915/cml_guc_49.0.1.bin"
curl -L -o "/lib/firmware/i915/dg1_dmc_ver2_02.bin" "https://anduin.linuxfromscratch.org/sources/linux-firmware/i915/dg1_dmc_ver2_02.bin"
curl -L -o "/lib/firmware/i915/ehl_guc_49.0.1.bin" "https://anduin.linuxfromscratch.org/sources/linux-firmware/i915/ehl_guc_49.0.1.bin"
curl -L -o "/lib/firmware/i915/glk_guc_49.0.1.bin" "https://anduin.linuxfromscratch.org/sources/linux-firmware/i915/glk_guc_49.0.1.bin"
curl -L -o "/lib/firmware/i915/icl_guc_49.0.1.bin" "https://anduin.linuxfromscratch.org/sources/linux-firmware/i915/icl_guc_49.0.1.bin"
curl -L -o "/lib/firmware/i915/kbl_guc_49.0.1.bin" "https://anduin.linuxfromscratch.org/sources/linux-firmware/i915/kbl_guc_49.0.1.bin"
curl -L -o "/lib/firmware/i915/skl_guc_49.0.1.bin" "https://anduin.linuxfromscratch.org/sources/linux-firmware/i915/skl_guc_49.0.1.bin"
curl -L -o "/lib/firmware/i915/tgl_guc_49.0.1.bin" "https://anduin.linuxfromscratch.org/sources/linux-firmware/i915/tgl_guc_49.0.1.bin"
curl -L -o "/lib/firmware/i915/tgl_huc_7.5.0.bin" "https://anduin.linuxfromscratch.org/sources/linux-firmware/i915/tgl_huc_7.5.0.bin"

update-initramfs -u -k all
