# My home Kubernetes cluster driven by GitOps

![Kubernetes](https://i.imgur.com/p1RzXjQ.png)

[![Discord](https://img.shields.io/badge/discord-chat-7289DA.svg?maxAge=60&style=flat-square)](https://discord.gg/DNCynrJ)

All my workloads are in the [deployments](./deployments/) directory and sorted by namespace.

---

## Hardware configuration

_All my Kubernetes master and worker nodes below are running bare metal Ubuntu 19.04_

| Device                  | Count | OS Disk Size | Data Disk Size      | Ram  | Purpose                       |
|-------------------------|-------|--------------|---------------------|------|-------------------------------|
| Odroid H2               | 1     | 256GB NVMe   | N/A                 | 16GB | k8s Master                    |
| Intel NUC8i5BEH         | 3     | 120GB SSD    | 1TB NVMe (longhorn) | 32GB | k8s Workers                   |
| Intel NUC8i7BEH         | 2     | 750GB SSD    | 1TB NVMe (longhorn) | 64GB | k8s Workers                   |
| Qnap NAS (rocinante)    | 1     | N/A          | 8x12TB RAID6        | 16GB | Media and shared file storage |
| Synology NAS (serenity) | 1     | N/A          | 8x12TB RAID6        | 4GB  | Media and shared file storage |

---

## Services addresses

_MetalLB IP Range 192.168.42.100-192.168.42.250_

| Deployment                     | Address                                                 |
|--------------------------------|---------------------------------------------------------|
| nginx-ingress (external)       | 192.168.42.100                                          |
| nginx-ingress (internal)       | 192.168.42.101                                          |
| home-assistant                 | [192.168.42.105:8123](http://192.168.42.105:8123)       |
| influxdb                       | 192.168.42.109                                          |
| vernemq                        | 192.168.42.110                                          |
| blocky                         | 192.168.42.115                                          |
| qbittorrent                    | 192.168.42.130                                          |
| plex                           | [192.168.42.140:32400](http://192.168.42.140:32400/web) |
| loki-syslog                    | 192.168.42.155                                          |
| powerdns                       | 192.168.42.180                                          |

---

## Similar repositories

- [billimek/k8s-gitops](https://github.com/billimek/k8s-gitops)
- [carpenike/k8s-gitops](https://github.com/carpenike/k8s-gitops)
- [dcplaya/k8s-gitops](https://github.com/dcplaya/k8s-gitops)
- [rust84/k8s-gitops](https://github.com/rust84/k8s-gitops)
- [blackjid/homelab-gitops](https://github.com/blackjid/homelab-gitops)
- [nlopez/k8s_home](https://github.com/nlopez/k8s_home)
