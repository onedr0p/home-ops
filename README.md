# Kubernetes cluster utilizing the GitOps workflow

![Discord](https://img.shields.io/discord/673534664354430999?label=discord)

This is my Homelab's Kubernetes cluster. All workloads are in the [deployments](./deployments/) folder and sorted into folders by namespace. Investigate into each folder below to learn more about my deployments.

- [cert-manager](./deployments/cert-manager)
- [default](./deployments/default)
- [flux](./deployments/flux)
- [kube-system](./deployments/kube-system)
- [logging](./deployments/logging)
- [monitoring](./deployments/monitoring)
- [rook-ceph](./deployments/rook-ceph)
- [velero](./deployments/velero)

This repository isn't really a tutorial on how to set up a cluster because of the amount of differences you would experience in setting up a Kubernetes cluster. However I do have some things documented in the [docs](./docs/) folder.

You can also checkout my [k3s-gitops-arm](https://github.com/onedr0p/k3s-gitops-arm) repo for more of a A-Z guide on how to setup a cluster on a bunch of Raspberry Pis.

## Join the community

If you would like to join in a conversation, join here. [discord.gg/hk58BZV](https://discord.gg/hk58BZV)
