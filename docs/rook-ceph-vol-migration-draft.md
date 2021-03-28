k scale deployment/zwave2mqtt -n home --replicas 0


kubectl get pv/(kubectl get pv | grep "zwave2mqtt-config[[:space:]+]" | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'

csi-vol-24abe999-2684-11eb-80c7-2298c6796a25

kubectl get pv/(kubectl get pv | grep "zwave2mqtt-config-v1[[:space:]+]" | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'

csi-vol-df7336f7-8fc2-11eb-b291-6aaa17155076

## Toolbox

```sh
mkdir -p /mnt/{old,new}
rbd map -p replicapool csi-vol-24abe999-2684-11eb-80c7-2298c6796a25 | xargs -I{} mount {} /mnt/old
rbd map -p replicapool csi-vol-df7336f7-8fc2-11eb-b291-6aaa17155076 | xargs -0 -I{} sh -c 'mkfs.ext4 {}; mount {} /mnt/new'
cp -rp /mnt/old/. /mnt/new
chown -R 568:568 /mnt/new
umount /mnt/old
umount /mnt/new
rbd unmap -p replicapool csi-vol-24abe999-2684-11eb-80c7-2298c6796a25 && \
rbd unmap -p replicapool csi-vol-df7336f7-8fc2-11eb-b291-6aaa17155076
```
