k scale deployment/radarr -n media --replicas 0


kubectl get pv/(kubectl get pv | grep "radarr-config[[:space:]+]" | awk -F' ' '{print $1}') -n media -o json | jq -r '.spec.csi.volumeAttributes.imageName'

csi-vol-c171519e-2523-11eb-80c7-2298c6796a25

kubectl get pv/(kubectl get pv | grep "radarr-config-v1[[:space:]+]" | awk -F' ' '{print $1}') -n media -o json | jq -r '.spec.csi.volumeAttributes.imageName'

csi-vol-9a3e6a10-8b0a-11eb-b291-6aaa17155076


## Toolbox

```sh
mkdir -p /mnt/{old,new}
rbd map -p replicapool csi-vol-c171519e-2523-11eb-80c7-2298c6796a25 | xargs -I{} mount {} /mnt/old
rbd map -p replicapool csi-vol-9a3e6a10-8b0a-11eb-b291-6aaa17155076 | xargs -0 -I{} sh -c 'mkfs.ext4 {}; mount {} /mnt/new'
cp -rp /mnt/old/* /mnt/new
chown -R 568:568 /mnt/new
umount /mnt/old
umount /mnt/new
rbd unmap -p replicapool csi-vol-c171519e-2523-11eb-80c7-2298c6796a25
rbd unmap -p replicapool csi-vol-9a3e6a10-8b0a-11eb-b291-6aaa17155076
```
