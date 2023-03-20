# NAS

Outside of using [Ansible](https://github.com/ansible/ansible) for configuring the OS, there are some manual steps I did to set up ZFS on Ubuntu.

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
        /dev/disk/by-id/scsi-SATA_ST12000VN0007-2G_ZCH0B3D2 \
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
    sudo zfs create eros/Apps/MinIO
    sudo zfs create eros/Media
    ```

2. Share dataset over NFS
    ```sh
    sudo zfs set \
        sharenfs="no_subtree_check,all_squash,anonuid=568,anongid=100,rw=@192.168.42.0/24,rw=@192.168.1.0/24,ro=192.168.150.21,ro=192.168.150.28" \
        eros/Media
    sudo zfs set \
        sharenfs="no_subtree_check,all_squash,anonuid=568,anongid=100,rw=@192.168.42.0/24,rw=@192.168.1.0/24" \
        eros/Apps/MinIO
    ```

3. Dataset Permissions
    ```sh
    sudo chmod 770 /eros/Media
    sudo chown -R devin:users /eros/Media
    ```

### Snapshots

Install zrepl by following [these](https://zrepl.github.io/installation/apt-repos.html) instructions.

1. Add or replace the file `/etc/zrepl/zrepl.yml`
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

2. Start and enable zrepl
    ```sh
    sudo systemctl enable --now zrepl.service
    ```

3. Give a local user access to a specific datasets snapshots
    ```sh
    sudo zfs allow -u jeff send,snapshot,hold eros/Media
    ```

## NFS

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

## Misc

### Badblocks

```admonish warning
This command is **very destructive** and should only be used to check for bad sectors
```

```sh
sudo badblocks -b 4096 -wsv /dev/disk/by-id/scsi-SATA_ST12000VN0007-2G_ZJV01MC5
```

### Lenovo SA120

Due to the loudness of the fans, they can be adjusted by using [AndrewX192/lenovo-sa120-fanspeed-utility](https://github.com/AndrewX192/lenovo-sa120-fanspeed-utility.git).
