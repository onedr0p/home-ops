k scale deployment/home-assistant -n home --replicas 0


kubectl get pv/(kubectl get pv | grep "home-assistant-config[[:space:]+]" | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'

csi-vol-bfb12f8d-408a-11eb-84a3-bad0f655a7fa

kubectl get pv/(kubectl get pv | grep "home-assistant-config-v1[[:space:]+]" | awk -F' ' '{print $1}') -n home -o json | jq -r '.spec.csi.volumeAttributes.imageName'

csi-vol-de982550-8fc2-11eb-b291-6aaa17155076

## Toolbox

```sh
mkdir -p /mnt/{old,new}
rbd map -p replicapool csi-vol-bfb12f8d-408a-11eb-84a3-bad0f655a7fa | xargs -I{} mount {} /mnt/old
rbd map -p replicapool csi-vol-de982550-8fc2-11eb-b291-6aaa17155076 | xargs -0 -I{} sh -c 'mkfs.ext4 {}; mount {} /mnt/new'
cp -rp /mnt/old/. /mnt/new
chown -R 568:568 /mnt/new
umount /mnt/old
umount /mnt/new
rbd unmap -p replicapool csi-vol-bfb12f8d-408a-11eb-84a3-bad0f655a7fa && \
rbd unmap -p replicapool csi-vol-de982550-8fc2-11eb-b291-6aaa17155076
```
