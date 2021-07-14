k scale deployment/frigate -n home --replicas 0

kubectl get pv/(kubectl get pv | grep "frigate-config[[:space:]+]" | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'
# csi-vol-e210e08c-80f5-11eb-bb77-f25ddf8c8685

kubectl get pv/(kubectl get pv | grep "frigate-config-v1[[:space:]+]" | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'
# csi-vol-de945d8c-8fc2-11eb-b291-6aaa17155076

## Toolbox

Access rook direct mount


```sh
kubectl -n rook-ceph exec -it (kubectl -n rook-ceph get pod -l "app=rook-direct-mount" -o jsonpath='{.items[0].metadata.name}') bash
```

```sh
mkdir -p /mnt/{old,new}
rbd map -p replicapool csi-vol-e210e08c-80f5-11eb-bb77-f25ddf8c8685 | xargs -I{} mount {} /mnt/old
rbd map -p replicapool csi-vol-de945d8c-8fc2-11eb-b291-6aaa17155076 | xargs -0 -I{} sh -c 'mkfs.ext4 {}; mount {} /mnt/new'
cp -rp /mnt/old/. /mnt/new
chown -R 568:568 /mnt/new
umount /mnt/old
umount /mnt/new
rbd unmap -p replicapool csi-vol-e210e08c-80f5-11eb-bb77-f25ddf8c8685 && \
rbd unmap -p replicapool csi-vol-de945d8c-8fc2-11eb-b291-6aaa17155076
```
