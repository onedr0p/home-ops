# Manual Data Backup

## Create the toolbox container

!!! info "Ran from your workstation"

```sh
kubectl -n rook-ceph exec -it (kubectl -n rook-ceph get pod -l "app=rook-direct-mount" -o jsonpath='{.items[0].metadata.name}') bash
```

!!! info "Ran from the `rook-ceph-toolbox`"

```sh
mkdir -p /mnt/nfsdata
mkdir -p /mnt/data
mount -t nfs -o "nfsvers=4.1,hard" 192.168.1.81:/Data /mnt/nfsdata
```

## Backup data to a NFS share

!!! info "Ran from your workstation"

- Pause the Flux Helm Release

```sh
flux suspend hr home-assistant -n home
```

- Scale the application down to zero pods

```sh
kubectl scale deploy/home-assistant --replicas 0 -n home
```

- Get the `csi-vol-*` string

```sh
kubectl get pv/(kubectl get pv | grep home-assistant-config-v1 | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'
```

!!! info "Ran from the `rook-ceph-toolbox`"

```sh
rbd map -p replicapool csi-vol-ebb786c7-9a6f-11eb-ae97-9a71104156fa \
    | xargs -I{} mount {} /mnt/data
tar czvf /mnt/nfsdata/Backups/home-assistant.tar.gz -C /mnt/data/ .
umount /mnt/data
rbd unmap -p replicapool csi-vol-ebb786c7-9a6f-11eb-ae97-9a71104156fa
```
