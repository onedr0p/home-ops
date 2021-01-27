#!/usr/bin/env bash
set -euo pipefail

rm /build/ubuntu-20.04.1-live-server-amd64-autoinstall-masters.iso
rm /build/ubuntu-20.04.1-live-server-amd64-autoinstall-workers.iso

if [ ! -f /build/ubuntu-20.04.1-live-server-amd64.iso ]; then
    curl -L -o /build/ubuntu-20.04.1-live-server-amd64.iso https://releases.ubuntu.com/20.04/ubuntu-20.04.1-live-server-amd64.iso
fi

7z x /build/ubuntu-20.04.1-live-server-amd64.iso -oiso

mkdir -p iso/nocloud/
touch iso/nocloud/meta-data
rm -rf 'iso/[BOOT]/'
md5sum iso/README.diskdefines > iso/md5sum.txt
sed -i 's|iso/|./|g' iso/md5sum.txt
sed -i 's|---|autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---|g' iso/boot/grub/grub.cfg
sed -i 's|---|autoinstall ds=nocloud;s=/cdrom/nocloud/ ---|g' iso/isolinux/txt.cfg

cp autoinstall-masters.yml iso/nocloud/user-data

xorriso -as mkisofs -r \
    -V Ubuntu\ masters\ amd64 \
    -o /build/ubuntu-20.04.1-live-server-amd64-autoinstall-masters.iso \
    -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
    -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
    -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin  \
    iso/boot iso

cp autoinstall-workers.yml iso/nocloud/user-data

xorriso -as mkisofs -r \
    -V Ubuntu\ workers\ amd64 \
    -o /build/ubuntu-20.04.1-live-server-amd64-autoinstall-workers.iso \
    -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
    -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
    -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin  \
    iso/boot iso
