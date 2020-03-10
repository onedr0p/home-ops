# My home Kubernetes cluster driven by [GitOps](https://www.weave.works/blog/what-is-gitops-really)

![Kubernetes](https://i.imgur.com/p1RzXjQ.png)

[![Discord](https://img.shields.io/badge/discord-chat-7289DA.svg?maxAge=60&style=flat-square)](https://discord.gg/hk58BZV)

All workloads are in the [deployments](./deployments/) folder and sorted into folders by namespace. 

This repository isn't really a tutorial on how to set up a Kubernetes cluster, checkout my [k3s-gitops-arm](https://github.com/onedr0p/k3s-gitops-arm) repo for more of a A-Z guide on how to setup a cluster on some Raspberry Pis.

Huge shout out to [billimek/k8s-gitops](https://github.com/billimek/k8s-gitops) and [carpenike/k8s-gitops](https://github.com/carpenike/k8s-gitops) who continue to be a great resource of information.

## Deployment Namespaces

- [cert-manager](./deployments/cert-manager)
- [default](./deployments/default)
- [flux](./deployments/flux)
- [kube-system](./deployments/kube-system)
- [logging](./deployments/logging)
- [monitoring](./deployments/monitoring)
- [rook-ceph](./deployments/rook-ceph)

## k3s or k8s

[k3s](https://github.com/rancher/k3s) was my choice in Kubernetes distros because of how easy and quick it is to get going with [k3sup](https://github.com/alexellis/k3sup).

## Server Configuration

All my Kubernetes worker and master nodes below are running bare metal Ubuntu 18.04.3. Using a Hypervisor seemed like a bit overkill, all the devices would be running 1 VM anyways.

- 1x OdroidH2 w/ 256GB NVMe and 16GB RAM for the Kubernetes master node
- 3x NUC8i5BEH w/ 1TB NVMe and 32GB RAM for the rook-ceph/storage nodes
- 2x NUC8i7BEH w/ 500GB SSD and 64GB RAM for the worker nodes
- 5x Sonnet Thunderbolt to 10Gb SFP+ for the Intel NUC Kubernetes worker and storage nodes
- 1x Qnap 8 bay NAS w/ 12TB drives for media and some deployment volumes

## Load Balancer IPs

[MetalLB](https://metallb.universe.tf/) IP Address Range: `192.168.42.100-192.168.42.250`

|Deployment|IP Address|
|---------------|--------------|
|nginx-ingress  |192.168.42.100|
|blocky         |192.168.42.115|
|qbittorrent    |192.168.42.130|
|plex           |192.168.42.140|
|influxdb       |192.168.42.150|
|loki-syslog    |192.168.42.155|
