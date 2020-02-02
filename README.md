# My home Kubernetes cluster driven by [GitOps](https://www.weave.works/blog/what-is-gitops-really)

![Kubernetes](https://i.imgur.com/p1RzXjQ.png)

[Join](https://discord.gg/hk58BZV) Discord Community

![Discord](https://img.shields.io/discord/673534664354430999?label=discord) 

This is my Homelab's Kubernetes cluster. All workloads are in the [deployments](./deployments/) folder and sorted into folders by namespace. Investigate into each folder below to learn more about my deployments. This repository isn't really a tutorial on how to set up a cluster because of the amount of differences you would experience in setting up a Kubernetes cluster. However I do have some things documented in the [docs](./docs/) folder. You can also checkout my [k3s-gitops-arm](https://github.com/onedr0p/k3s-gitops-arm) repo for more of a A-Z guide on how to setup a cluster on a bunch of Raspberry Pis.

- [cert-manager](./deployments/cert-manager)
- [default](./deployments/default)
- [flux](./deployments/flux)
- [kube-system](./deployments/kube-system)
- [logging](./deployments/logging)
- [monitoring](./deployments/monitoring)
- [rook-ceph](./deployments/rook-ceph)
- [velero](./deployments/velero)

## Server configuration

- 1x OdroidH2 w/ 256GB NVMe and 16GB RAM for the Kubernetes master node
- 3x NUC8i5BEH w/ 1TB NVMe and 32GB RAM for the rook-ceph/storage nodes
- 2x NUC8i7BEH w/ 500GB SSD and 64GB RAM for the worker nodes
- 5x Sonnet Thunderbolt to 10Gb SFP+ for the Kubernetes worker and storage nodes
- 1x Qnap 8 bay NAS w/ 12TB drives for media and some deployment volumes
