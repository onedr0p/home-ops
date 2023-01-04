# Proxmox Considerations

I am using bare metal nodes but here's some considerations when using Proxmox.

## Single Node PVE Cluster

1. Use physical separate disks used for the PVE install, k8s VMs and Longhorn/rook-ceph
2. Don't put k8s VMs or Longhorn/rook-ceph on HDDs, only use SSDs or NVMe
3. Use k3s with a single master node (4CPU/8GB RAM/50GB disk) that is using sqlite instead of etcd and taint it.
4. Use as many worker nodes as you want but start with 3 and add more later on if you need them.

## Dual node PVE Cluster

1. Buy another node for your PVE cluster or refer to Single Node PVE Cluster.

## Tripe node PVE Cluster

1. Use physical separate disks used for the PVE install, k8s VMs and Longhorn
2. Don't put k8s VMs or Longhorn on HDDs, only use SSDs or NVMe
3. Evenly spread out your k8s masters and workers across each PVE node
    - In a 3 master/3 worker setup put one master on each PVE node and one worker on each PVE node.
4. Instead of Longhron, consider setting up a <ins>[Ceph cluster on your PVE nodes](https://pve.proxmox.com/wiki/Deploy_Hyper-Converged_Ceph_Cluster)</ins> and use <ins>[Rook to consume it](https://rook.io/docs/rook/v1.10/CRDs/Cluster/external-cluster/)</ins> for stateful applications. Due to the way Ceph works in this scenerio, it is fine to use HDDs over SSDs or NVMe here.
