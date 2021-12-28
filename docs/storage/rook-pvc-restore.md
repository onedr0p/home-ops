# Manual Data Restore

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

## Restore data from a NFS share

!!! info "Ran from your workstation"

- Apply the PVC

```sh
kubectl apply -f cluster/apps/home/home-assistant/config-pvc.yaml
```

- Get the `csi-vol-*` string

```sh
kubectl get pv/(kubectl get pv | grep home-assistant-config-v1 | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'
```

!!! info "Ran from the `rook-ceph-toolbox`"

```sh
rbd map -p replicapool csi-vol-f7a3b0db-d073-11eb-8ec1-4e450ed3a212 \
    | xargs -I{} sh -c 'mkfs.ext4 {}'
rbd map -p replicapool csi-vol-f7a3b0db-d073-11eb-8ec1-4e450ed3a212 \
    | xargs -I{} mount {} /mnt/data
tar xvf /mnt/nfsdata/Backups/home-assistant.tar.gz -C /mnt/data
umount /mnt/data
rbd unmap -p replicapool csi-vol-f7a3b0db-d073-11eb-8ec1-4e450ed3a212
rbd unmap -p replicapool csi-vol-f7a3b0db-d073-11eb-8ec1-4e450ed3a212
```
