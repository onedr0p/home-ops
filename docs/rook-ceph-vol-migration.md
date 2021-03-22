k scale deployment/gonic -n media --replicas 0


kubectl get pv/(kubectl get pv | grep "gonic-config[[:space:]+]" | awk -F' ' '{print $1}') -n media -o json | jq -r '.spec.csi.volumeAttributes.imageName'

csi-vol-7a58567c-5eaf-11eb-84a6-4e3b23e9bdcb

kubectl get pv/(kubectl get pv | grep "gonic-config-v1[[:space:]+]" | awk -F' ' '{print $1}') -n media -o json | jq -r '.spec.csi.volumeAttributes.imageName'

csi-vol-98bde548-8b0a-11eb-b291-6aaa17155076

## Toolbox

```sh
mkdir -p /mnt/{old,new}
rbd map -p replicapool csi-vol-7a58567c-5eaf-11eb-84a6-4e3b23e9bdcb | xargs -I{} mount {} /mnt/old
rbd map -p replicapool csi-vol-98bde548-8b0a-11eb-b291-6aaa17155076 | xargs -0 -I{} sh -c 'mkfs.ext4 {}; mount {} /mnt/new'
cp -rp /mnt/old/* /mnt/new
chown -R 568:568 /mnt/new
umount /mnt/old
umount /mnt/new
rbd unmap -p replicapool csi-vol-7a58567c-5eaf-11eb-84a6-4e3b23e9bdcb
rbd unmap -p replicapool csi-vol-98bde548-8b0a-11eb-b291-6aaa17155076
```
