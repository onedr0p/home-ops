# NAS

My NAS configuation as documentation currently using Ubuntu 22.04

## Packages

1. Add Fish PPA

    ```sh
    sudo apt-add-repository ppa:fish-shell/release-3
    ```

2. Install Packages

    ```sh
    sudo apt install -y apt-transport-https ca-certificates containernetworking-plugins curl ffmpeg figlet fish fzf gettext git htop ifenslave iputils-ping net-tools lolcat mailutils msmtp msmtp-mta nano neofetch ntpdate podman psmisc rclone software-properties-common tmux tree uidmap unzip zfs-zed zfsutils-linux dmraid gdisk hdparm lvm2 nfs-common nfs-kernel-server nvme-cli open-iscsi samba samba-vfs-modules smartmontools socat
    ```

## Networking

1. Add or replace file `/etc/netplan/00-installer-config.yaml`

    ```yaml
    network:
      version: 2
      bonds:
        bond0:
          interfaces: [eports]
          mtu: 9000
          dhcp4: true
          parameters:
            mode: 802.3ad
            lacp-rate: fast
            transmit-hash-policy: layer2+3
            mii-monitor-interval: 100
      ethernets:
        eports:
        mtu: 9000
        match:
          name: "enp6*"
        optional: true
    ```

2. Add or replace file `/etc/modules-load.d/modules.conf`

    ```text
    # /etc/modules: kernel modules to load at boot time.
    #
    # This file contains the names of kernel modules that should be loaded
    # at boot time, one per line. Lines beginning with "#" are ignored.
    bonding
    ```

## ZFS

### Mirrored Zpool

1. Create initial pool and set configuration

    ```sh
    sudo zpool create -o ashift=12 -f eros mirror \
        /dev/disk/by-id/scsi-SATA_WDC_WD120EDGZ-11_9LHWA5KG \
        /dev/disk/by-id/scsi-SATA_WDC_WD120EMFZ-11_9MG0AHZA
    sudo zfs set atime=off eros
    sudo zfs set compression=lz4 eros
    ```

2. Attach more mirrors

    ```sh
    sudo zpool add eros mirror \
        /dev/disk/by-id/scsi-SATA_ST12000VN0007-2G_ZCH0F1CH \
        /dev/disk/by-id/scsi-SATA_WDC_WD120EMFZ-11_X1G3B01L
    ```

3. Add spares

    ```sh
    sudo zpool add -f eros spare \
        /dev/disk/by-id/scsi-SATA_WDC_WD120EMFZ-11_QGGETR5T
    ```

### Datasets

1. Create datasets

    ```sh
    sudo zfs create eros/Apps
    sudo zfs create eros/Apps/Frigate
    sudo zfs create eros/Media
    ```

2. Share dataset over NFS

    ```sh
    sudo zfs set \
        sharenfs="no_subtree_check,all_squash,anonuid=568,anongid=100,rw=@192.168.42.0/24,rw=@192.168.1.0/24,ro=192.168.150.21,ro=192.168.150.28" \
        eros/Media
    sudo zfs set \
        sharenfs="no_subtree_check,all_squash,anonuid=568,anongid=100,rw=@192.168.42.0/24,rw=@192.168.1.0/24" \
        eros/Apps/Frigate
    ```

3. Dataset Permissions

    ```sh
    sudo chmod 770 /eros/Media
    sudo chown -R devin:users /eros/Media
    ```

### Snapshots

1. Install zrepl by following [these](https://zrepl.github.io/installation/apt-repos.html) instructions.

2. Add or replace the file `/etc/zrepl/zrepl.yml`

    ```yaml
    global:
      logging:
        - type: syslog
          format: human
          level: warn
      monitoring:
        - type: prometheus
          listen: :9811
          listen_freebind: true

    jobs:
      - name: daily
        type: snap
        filesystems:
          "eros<": true
        snapshotting:
          type: cron
          cron: "0 3 * * *"
          prefix: zrepl_daily_
          timestamp_format: dense
        pruning:
          keep:
            - type: last_n
              count: 7
              regex: "^zrepl_daily_.*$"
    ```

3. Start and enable zrepl

    ```sh
    sudo systemctl enable --now zrepl.service
    ```

4. Give a local user access to a specific datasets snapshots

    ```sh
    sudo zfs allow -u jeff send,snapshot,hold eros/Media
    ```

## NFS

### Force NFS 4 and update threads

1. Add or replace file `/etc/nfs.conf.d/local.conf`

    ```text
    [nfsd]
    vers2 = n
    vers3 = n
    threads = 16

    [mountd]
    manage-gids = 1
    ```

### Non ZFS NFS Shares

1. Add or replace file `/etc/exports.d/local.exports`

    ```text
    /share/PVCs 192.168.1.0/24(sec=sys,rw,no_subtree_check,all_squash,anonuid=568,anongid=100)
    /share/PVCs 192.168.42.0/24(sec=sys,rw,no_subtree_check,all_squash,anonuid=568,anongid=100)
    ```

2. Dataset Permissions

    ```sh
    sudo chmod 770 /share/PVCs
    sudo chown -R devin:users /share/PVCs
    ```

3. Reload exports

    ```sh
    sudo exportfs -arv
    ```

## Time Machine

1. Install required tools

    ```sh
    sudo apt install samba samba-vfs-modules
    ```

2. Create ZFS datasets and update permissions

    ```sh
    sudo zfs create eros/TimeMachine
    sudo zfs create eros/TimeMachine/devin
    sudo zfs create eros/TimeMachine/louie
    sudo chown -R devin:users /eros/TimeMachine
    sudo chmod -R 770 /eros/TimeMachine
    ```

3. Set a smb password for user

    ```sh
    sudo smbpasswd -a devin
    ```

4. Add or replace file `/etc/samba/smb.conf`

    ```text
    [global]
    min protocol = SMB2
    ea support = yes
    vfs objects = fruit streams_xattr
    fruit:aapl = yes
    fruit:metadata = stream
    fruit:model = MacSamba
    fruit:posix_rename = yes
    fruit:veto_appledouble = no
    fruit:nfs_aces = no
    fruit:wipe_intentionally_left_blank_rfork = yes
    fruit:delete_empty_adfiles = yes
    spotlight = no

    [devin]
    comment = Devin's Time Machine
    fruit:time machine = yes
    fruit:time machine max size = 1050G
    path = /eros/TimeMachine/devin
    browseable = yes
    write list = devin
    create mask = 0600
    directory mask = 0700
    case sensitive = true
    default case = lower
    preserve case = no
    short preserve case = no

    [louie]
    comment = Louie's Time Machine
    fruit:time machine = yes
    fruit:time machine max size = 1050G
    path = /eros/TimeMachine/louie
    browseable = yes
    write list = devin
    create mask = 0600
    directory mask = 0700
    case sensitive = true
    default case = lower
    preserve case = no
    short preserve case = no
    ```

5. Restart samba

    ```sh
    sudo systemctl restart smbd.service
    ```

6. Set up Time Machine on MacOS

    ```sh
    sudo tmutil setdestination -a smb://devin:${smbpasswd}@expanse.turbo.ac/devin
    ```

## System

1. Disable apparmor

    ```sh
    sudo systemctl stop apparmor
    sudo systemctl mask apparmor
    ```

2. Disable mitigations and apparmor in grub

    ```sh
    sudo nano /etc/default/grub
    # GRUB_CMDLINE_LINUX="apparmor=0 mitigations=off"
    sudo update-grub
    sudo reboot
    ```

3. Disable swap

    ```sh
    sudo swapoff -a
    sudo sed -i '/ swap / s/^/#/' /etc/fstab
    ```

## Notifications

```admonish info
Restart msmtpd after changing: `sudo systemctl restart msmtpd.service`
```

1. Add or replace file `/etc/aliases`

    ```text
    mailer-daemon: postmaster@
    postmaster: root@
    nobody: root@
    hostmaster: root@
    usenet: root@
    news: root@
    webmaster: root@
    www: root@
    ftp: root@
    abuse: root@
    noc: root@
    security: root@
    root: devin@buhl.casa
    ```

```admonish info
Restart msmtpd after changing: `sudo systemctl restart msmtpd.service`
```

2. Add or replace file `/etc/msmtprc`

    ```text
    defaults
    auth off
    tls  off
    tls_trust_file /etc/ssl/certs/ca-certificates.crt
    logfile /var/log/msmtp

    account        maddy
    host           smtp-relay.turbo.ac
    port           25
    from           devin@buhl.casa
    tls_starttls   off

    account default: maddy

    aliases /etc/aliases
    ```

```admonish info
Restart smartd after changing: `sudo systemctl restart smartd.service`
```

3. Add or replace file `/etc/smartd.conf`

    ```text
    DEVICESCAN -a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 4,35,40 -m devin+alerts@buhl.casa
    ```

```admonish info
Restart zed after changing: `sudo systemctl restart zed.service`
```

4. Add or replace file `/etc/zfs/zed.d/zed.rc`

    ```text
    ZED_DEBUG_LOG="/var/log/zed.debug.log"
    ZED_EMAIL_ADDR="devin@buhl.casa"
    ZED_EMAIL_PROG="mail"
    ZED_EMAIL_OPTS="-s '@SUBJECT@' @ADDRESS@ -r devin+alerts@buhl.casa"
    ZED_NOTIFY_VERBOSE=1
    ZED_NOTIFY_DATA=1
    ZED_USE_ENCLOSURE_LEDS=1
    ```

## Misc

### Replace a Drive

```admonish info
Enable autoexpand on the pool with `sudo zpool set autoexpand=on eros`
```

```sh
sudo zpool offline eros /dev/disk/by-id/scsi-SATA_ST12000VN0007-2G_ZCH0F1CH
sudo zpool replace eros /dev/disk/by-id/scsi-SATA_ST12000VN0007-2G_ZCH0F1CH /dev/disk/by-id/scsi-SATA_ST22000NM001E-3H_ZX201HJC
```

When resilvering is complete detach the drive...

```sh
sudo zpool detach eros /dev/disk/by-id/scsi-SATA_ST12000VN0007-2G_ZCH0F1CH
```

### Badblocks

```admonish warning
This command is **very destructive** and should only be used to check for bad sectors, this also take ashile so be sure to start it in a `screen`
```

```sh
sudo badblocks -b 4096 -wsv /dev/disk/by-id/scsi-SATA_ST12000VN0007-2G_ZJV01MC5
```

### Shred

```admonish warning
This command is **very destructive** and should only be used to completely wipe the drive, this also take ashile so be sure to start it in a `screen`
```

```sh
sudo shred -vfz -n 4 /dev/disk/by-id/scsi-SATA_ST12000VN0007-2G_ZJV01MC5
```

### Lenovo SA120

Due to the loudness of the fans, they can be adjusted by using [AndrewX192/lenovo-sa120-fanspeed-utility](https://github.com/AndrewX192/lenovo-sa120-fanspeed-utility.git).
