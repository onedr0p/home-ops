# Opnsense | PXE

!!! note "Work in progress"
    This document is a work in progress.

## Setting up TFTP

- Enable `dnsmasq` in the Opnsense services settings (set port to `63`)
- Copy over `pxe.conf` to `/usr/local/etc/dnsmasq.conf.d/pxe.conf`
- SSH into opnsense and run the following commands...

```console
$ mkdir -p /var/lib/tftpboot/pxelinux/
$ wget https://releases.ubuntu.com/20.04/ubuntu-20.04.2-live-server-amd64.iso -O /var/lib/tftpboot/ubuntu-20.04.2-live-server-amd64.iso
$ mount -t cd9660 /dev/`mdconfig -f /var/lib/tftpboot/ubuntu-20.04.2-live-server-amd64.iso` /mnt
$ cp /mnt/casper/vmlinuz /var/lib/tftpboot/pxelinux/
$ cp /mnt/casper/initrd /var/lib/tftpboot/pxelinux/
$ umount /mnt
$ wget http://archive.ubuntu.com/ubuntu/dists/focal/main/uefi/grub2-amd64/current/grubnetx64.efi.signed -O /var/lib/tftpboot/pxelinux/pxelinux.0
```

- Copy `grub/grub.conf` into `/var/lib/tftpboot/grub/grub.conf`
- Copy `nodes/` into `/var/lib/tftpboot/nodes`
