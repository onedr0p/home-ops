# Rook-Ceph Maintenance

!!! note "Work in progress"
    This document is a work in progress.

[Main article](https://rook.io/docs/rook/v1.5/ceph-common-issues.html)

## Accessing volumes

Sometimes I am required to access the data in the `pvc`, below is an example on how I access the `pvc` data for my `zigbee2mqtt` deployment.

First start by scaling the app deployment to 0 replicas:

```sh
kubectl scale deploy/zigbee2mqtt --replicas 0 -n home
```

Get the `rbd` image name for the app:

```sh
kubectl get pv/(kubectl get pv | grep zigbee2mqtt-data | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'
```

Exec into the `rook-direct-mount` toolbox:

```sh
kubectl -n rook-ceph exec -it (kubectl -n rook-ceph get pod -l "app=rook-direct-mount" -o jsonpath='{.items[0].metadata.name}') bash
```

Create a directory to mount the volume to:

```sh
mkdir -p /mnt/data
```

!!! hint "Mounting a NFS share"
    This can be useful if you want to move data from or to a `nfs` share

    Create a directory to mount the `nfs` share to:

    ```sh
    mkdir -p /mnt/nfsdata
    ```

    Mount the `nfs` share:

    ```sh
    mount -t nfs -o "tcp,intr,rw,noatime,nodiratime,rsize=65536,wsize=65536,hard" 192.168.1.40:/volume1/Data /mnt/nfsdata
    ```

List all the `rbd` block device names:

```sh
rbd list --pool replicapool
```

Map the `rbd` block device to a `/dev/rbdX` device:

```sh
rbd map -p replicapool csi-vol-e4a2e40f-2795-11eb-80c7-2298c6796a25
```

Mount the `/dev/rbdX` device:

```sh
mount /dev/rbdX /mnt/data
```

At this point you'll be able to access the volume data under `/mnt/data`, you can change files in any way.

!!! hint "Backing up or restoring data from a NFS share"
    Restoring data:

    ```sh
    rm -rf /mnt/data/*
    tar xvf /mnt/nfsdata/backups/zigbee2mqtt.tar.gz -C /mnt/data
    chown -R 568:568 /mnt/data/
    ```

    Backing up data:

    ```sh
    tar czvf /mnt/nfsdata/backups/zigbee2mqtt.tar.gz -C /mnt/data/ .
    ```

When done you can unmount `/mnt/data` and unmap the `rbd` device:

```sh
umount /mnt/data
rbd unmap -p replicapool csi-vol-e4a2e40f-2795-11eb-80c7-2298c6796a25
```

Lastly you need to scale the deployment replicas back up to 1:

```sh
kubectl scale deploy/zigbee2mqtt --replicas 1 -n home
```

## Handling crashes

Sometimes rook-ceph will report a `HEALTH_WARN` even when the health is fine, in order to get ceph to report back healthy do the following...

```sh
# list all the crashes
ceph crash ls
# if you want to read the message
ceph crash info <id>
# archive crash report
ceph crash archive <id>
# or, archive all crash reports
ceph crash archive-all
```
