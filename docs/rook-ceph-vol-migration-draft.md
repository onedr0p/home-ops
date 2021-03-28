k scale deployment/node-red -n home --replicas 0


kubectl get pv/(kubectl get pv | grep "node-red-config[[:space:]+]" | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'

csi-vol-39e4f299-29de-11eb-9f5c-6a7a1c175aee

kubectl get pv/(kubectl get pv | grep "node-red-config-v1[[:space:]+]" | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'

csi-vol-df2cd86e-8fc2-11eb-b291-6aaa17155076

## Toolbox

```sh
mkdir -p /mnt/{old,new}
rbd map -p replicapool csi-vol-39e4f299-29de-11eb-9f5c-6a7a1c175aee | xargs -I{} mount {} /mnt/old
rbd map -p replicapool csi-vol-df2cd86e-8fc2-11eb-b291-6aaa17155076 | xargs -0 -I{} sh -c 'mkfs.ext4 {}; mount {} /mnt/new'
cp -rp /mnt/old/* /mnt/new
chown -R 568:568 /mnt/new
umount /mnt/old
umount /mnt/new
rbd unmap -p replicapool csi-vol-39e4f299-29de-11eb-9f5c-6a7a1c175aee
rbd unmap -p replicapool csi-vol-df2cd86e-8fc2-11eb-b291-6aaa17155076
```
