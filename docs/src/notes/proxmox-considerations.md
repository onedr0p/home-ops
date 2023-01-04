# Proxmox Considerations

I am using bare metal nodes but here's some considerations when using Kubernetes on Proxmox. These are just my opinions gathered from experiance I've witnessed first or second hand. Following along will net you a very stable Kubernetes cluster on PVE.

```admonish warning
Preface: etcd is really read/write intensive and requires low iops/latency. With using the same disks and due to the way etcd works anytime a commit happens to etcd (which is probably hundreds of times per second), it will flood the same filesystem with 3x the amount of reads and writes

Now if you layer on Longhorn or rook-ceph to the same filesystem you are just asking for trouble, because that is also replicated.
```

## Single Node PVE Cluster

1. Use physical separate disks used for the PVE install, k8s VMs and Longhorn/rook-ceph
2. Don't put k8s VMs or Longhorn/rook-ceph on HDDs, only use SSDs or NVMe
3. Use k3s with a single master node (4CPU/8GB RAM/50GB disk) that is using sqlite instead of etcd and taint it.
4. Use as many worker nodes as you want but start with 3 and add more later on if you need them.
5. Consider using <ins>[local-path-provisioner](https://github.com/rancher/local-path-provisioner)</ins> over Longhorn or rook-ceph if you aren't able physically separate the disks.

## Dual node PVE Cluster

Buy another node for your PVE cluster or refer to Single Node PVE Cluster, _however if you must..._

1. Use k3s with a dual master nodes (4CPU/8GB RAM/50GB disk each) that is using postgresql/mysql/mariadb instead of etcd.
2. Put the postgresql/mysql/mariadb database on a VM on your first PVE cluster and never touch it.
3. Evenly spread out your k8s masters and workers across each PVE node
    -  In a 2 master/3 worker setup put one master on each PVE node and try to even out the workers on each PVE node.
4. Consider using <ins>[local-path-provisioner](https://github.com/rancher/local-path-provisioner)</ins> over Longhorn or rook-ceph if you aren't able physically separate the disks.

## Tripe node PVE Cluster

1. Use physical separate disks used for the PVE install, k8s VMs and Longhorn
2. Don't put k8s VMs or Longhorn on HDDs, only use SSDs or NVMe
3. Evenly spread out your k8s masters and workers across each PVE node
    - In a 3 master/3 worker setup put one master on each PVE node and one worker on each PVE node.
4. Instead of Longhron, consider setting up a <ins>[Ceph cluster on your PVE nodes](https://pve.proxmox.com/wiki/Deploy_Hyper-Converged_Ceph_Cluster)</ins> and use <ins>[Rook to consume it](https://rook.io/docs/rook/v1.10/CRDs/Cluster/external-cluster/)</ins> for stateful applications. Due to the way Ceph works in this scenerio, it is fine to use HDDs over SSDs or NVMe here.
