# :sailboat:&nbsp; My home Kubernetes cluster managed by GitOps

<h1 align="center">
  <img src="https://i.imgur.com/p1RzXjQ.png">
</h1>

<div align="center">

[![Discord](https://img.shields.io/badge/discord-chat-7289DA.svg?maxAge=60&style=flat-square)](https://discord.gg/DNCynrJ) [![k3s](https://img.shields.io/badge/k3s-v1.18.8-orange?style=flat-square)](https://k3s.io/) [![GitHub stars](https://img.shields.io/github/stars/onedr0p/k3s-gitops?color=green&style=flat-square)](https://github.com/onedr0p/k3s-gitops/stargazers) [![GitHub issues](https://img.shields.io/github/issues/onedr0p/k3s-gitops?style=flat-square)](https://github.com/onedr0p/k3s-gitops/issues) [![GitHub last commit](https://img.shields.io/github/last-commit/onedr0p/k3s-gitops?color=purple&style=flat-square)](https://github.com/onedr0p/k3s-gitops/commits/master) ![GitHub Workflow Status](https://img.shields.io/github/workflow/status/onedr0p/k3s-gitops/lint?color=blue&style=flat-square) [![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=flat-square)](https://github.com/pre-commit/pre-commit)

</div>

---

## :book:&nbsp; Overview

Welcome to my home Kubernetes cluster. This repo _is_ my Kubernetes cluster in a declarative state. [Flux](https://github.com/fluxcd/flux) and [Helm Operator](https://github.com/fluxcd/helm-operator) watch my [deployments](./deployments/) folder and makes the changes to my cluster based on the yaml manifests.

You'll find this is setup for home automation using [Home Assistant](https://www.home-assistant.io/) and media automation using [Sonarr](https://sonarr.tv/), [Radarr](https://radarr.video/) and [Plex](https://www.plex.tv/sign-in/?forwardUrl=https%3A%2F%2Fwww.plex.tv%2F). I also use [Gitea](https://gitea.io/en-us/) and [Drone](https://drone.io/) for development automation too. It would take too long to describe all the technologies running so poke around my [deployments](./deployments/) directory to see what's happening. 

Feel free to open a [Github issue](https://github.com/onedr0p/k3s-gitops/issues/new) or join our [Discord](https://discord.gg/DNCynrJ) if you have any questions.

---

### :computer:&nbsp; Hardware configuration

_All my Kubernetes master and worker nodes below are running bare metal Ubuntu 20.04.x_

| Device                  | Count | OS Disk Size | Data Disk Size      | Ram  | Purpose                                |
|-------------------------|-------|--------------|---------------------|------|----------------------------------------|
| Odroid H2               | 1     | 256GB NVMe   | N/A                 | 16GB | k8s Master                             |
| Intel NUC8i5BEH         | 3     | 120GB SSD    | 1TB NVMe (longhorn) | 32GB | k8s Workers                            |
| Intel NUC8i7BEH         | 2     | 750GB SSD    | 1TB NVMe (longhorn) | 64GB | k8s Workers                            |
| Qnap NAS (rocinante)    | 1     | N/A          | 8x12TB RAID6        | 16GB | Media and shared file storage          |
| Synology NAS (serenity) | 1     | N/A          | 8x12TB RAID6        | 4GB  | Media and shared file storage          |
| Raspberry Pi 4          | 1     | 64GB         | N/A                 | 8 GB | Wireguard VPN & General Purpose Device |

---

### :memo:&nbsp; Load Balancer IP addresses

_This table is a reference to Load Balancer IP addresses in my deployments and may not be fully up-to-date_

| Deployment               | Address        |
|--------------------------|----------------|
| nginx-ingress (external) | 192.168.42.100 |
| nginx-ingress (internal) | 192.168.42.101 |
| home-assistant           | 192.168.42.105 |
| influxdb                 | 192.168.42.109 |
| vernemq                  | 192.168.42.110 |
| blocky                   | 192.168.42.115 |
| gitea                    | 192.168.42.125 |
| qbittorrent              | 192.168.42.130 |
| plex                     | 192.168.42.140 |
| loki-syslog              | 192.168.42.155 |
| powerdns                 | 192.168.42.180 |

---

## :handshake:&nbsp; Thanks

A lot of inspiration for this repo came from the following people:

- [billimek/k8s-gitops](https://github.com/billimek/k8s-gitops)
- [carpenike/k8s-gitops](https://github.com/carpenike/k8s-gitops)
- [dcplaya/k8s-gitops](https://github.com/dcplaya/k8s-gitops)
- [rust84/k8s-gitops](https://github.com/rust84/k8s-gitops)
- [blackjid/homelab-gitops](https://github.com/blackjid/homelab-gitops)
- [bjw-s/k8s-gitops](https://github.com/bjw-s/k8s-gitops)
- [nlopez/k8s_home](https://github.com/nlopez/k8s_home)
