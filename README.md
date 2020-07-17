# My home Kubernetes cluster driven by GitOps

![Kubernetes](https://i.imgur.com/p1RzXjQ.png)

[![Discord](https://img.shields.io/badge/discord-chat-7289DA.svg?maxAge=60&style=flat-square)](https://discord.gg/hk58BZV)

All workloads are in the [deployments](./deployments/) folder and sorted into folders by namespace. 

This repository isn't really a tutorial on how to set up a Kubernetes cluster, checkout my [k3s-gitops-arm](https://github.com/onedr0p/k3s-gitops-arm) repo for more of a A-Z guide on how to setup a cluster on some Raspberry Pis.

---

## Hardware configuration

All my Kubernetes master and worker nodes below are running bare metal Ubuntu 18.04.3.

|Device         |Count  |OS Disk Size|Data Disk Size|Ram    |Purpose                              |
|---------------|-------|------------|--------------|-------|-------------------------------------|
|Odroid H2      |1      |256GB NVMe  |N/A           |16GB   |k8s Master                           |
|Intel NUC8i5BEH|3      |120GB SSD   |1TB NVMe      |32GB   |k8s Workers for rook-ceph workloads  |
|Intel NUC8i7BEH|2      |750GB SSD   |N/A           |64GB   |k8s Workers for standard workloads   |
|Qnap NAS       |1      |N/A         |8x12TB WD Reds|16GB   |NAS for media and shared file storage|

---

## Services addresses

MetalLB IP Address Range:

```bash
# 192.168.42.100-192.168.42.250
```

| Deployment          | Address                                                 |
|---------------------|---------------------------------------------------------|
| nginx-ingress       | 192.168.42.100                                          |
| home-assistant      | [192.168.42.105:8123](http://192.168.42.105:8123)       |
| zwave2mqtt          | [192.168.42.106:8091](http://192.168.42.106:8091)       |
| node-red            | [192.168.42.107:1880](http://192.168.42.107:1880)       |
| influxdb            | 192.168.42.109                                          |
| vernemq             | 192.168.42.110                                          |
| blocky              | 192.168.42.115                                          |
| qbittorrent         | 192.168.42.130                                          |
| jackett             | [192.168.42.131:9117](http://192.168.42.131:9117)       |
| nzbhydra2           | [192.168.42.132:5076](http://192.168.42.132:5076)       |
| plex                | [192.168.42.140:32400](http://192.168.42.140:32400/web) |
| loki-syslog         | 192.168.42.155                                          |
| rook-ceph-dashboard | [192.168.42.160:7000](http://192.168.42.160:7000)       |

---

## Applications

Below is a high level overview of some applications that are running in my cluster.

### Blocky

Alternative to Pihole for ad-blocking on your local network. This can be scaled horizontally which makes it a perfect fit in my cluster.

### Sonarr/Radarr/Lidarr

These applications will automatically search and manage content for TV (Sonarr), Movies (Radarr) and Music (Lidarr). Once the content has been searched and added, they will check which files are missing. Depending on configurations, they will then search BitTorrent or Usenet sites for the requested files. After that these applications will then send the information over to NZBGet or qBittorrent. Each time a new episode or film is available, it is automatically searched and downloaded.

### qBittorrent/NZBGet

These applications download content from Bittorrent (qBittorrent) and Usenet (NZBGet) indexers.

### Jackett/NZBHydra2/Bazarr

These applications work alongside Sonarr, Radarr and Lidarr to manage search Bittorrent (Jackett)and Usenet (NZBHydra2) indexers. Bazarr searches popular subtitle websites for media with missing subtitles.

### Plex/Tautulli/Ombi

Plex is media server that allows you to stream your media, it also organizes it to include metadata such as trailers, ratings and reviews and more. For monitoring and tracking what is going on in Plex, there's Tautulli and for giving your family and friends a nice interface for requesting new content checkout Ombi.

---

## Credits

Huge shout out to [billimek/k8s-gitops](https://github.com/billimek/k8s-gitops) and [carpenike/k8s-gitops](https://github.com/carpenike/k8s-gitops) who continue to be a great resource of information.
