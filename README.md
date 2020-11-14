<h1 align="center">
  My home Kubernetes cluster :sailboat:
  <br />
  <br />
  <img src="https://i.imgur.com/p1RzXjQ.png">
</h1>
<br />
<div align="center">

[![Discord](https://img.shields.io/badge/discord-chat-7289DA.svg?maxAge=60&style=flat-square)](https://discord.gg/DNCynrJ) [![k3s](https://img.shields.io/badge/k3s-v1.18.8-orange?style=flat-square)](https://k3s.io/) [![GitHub stars](https://img.shields.io/github/stars/onedr0p/k3s-gitops?color=green&style=flat-square)](https://github.com/onedr0p/k3s-gitops/stargazers) [![GitHub issues](https://img.shields.io/github/issues/onedr0p/k3s-gitops?style=flat-square)](https://github.com/onedr0p/k3s-gitops/issues) [![GitHub last commit](https://img.shields.io/github/last-commit/onedr0p/k3s-gitops?color=purple&style=flat-square)](https://github.com/onedr0p/k3s-gitops/commits/master) ![GitHub Workflow Status](https://img.shields.io/github/workflow/status/onedr0p/k3s-gitops/lint?color=blue&style=flat-square) [![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=flat-square)](https://github.com/pre-commit/pre-commit)

</div>

---

# :book:&nbsp; Overview

Welcome to my home Kubernetes cluster. This repo _is_ my Kubernetes cluster in a declarative state. [Flux](https://github.com/fluxcd/flux) and [Helm Operator](https://github.com/fluxcd/helm-operator) watch my [cluster](./cluster/) folder and makes the changes to my cluster based on the yaml manifests.

You'll find this is setup for home automation using [Home Assistant](https://www.home-assistant.io/) and media automation using [Sonarr](https://sonarr.tv/), [Radarr](https://radarr.video/) and [Plex](https://www.plex.tv). I also use [Gitea](https://gitea.io/en-us/) and [Drone](https://drone.io/) for development automation too. It would take too long to describe all the technologies running so poke around my [cluster](./cluster/) directory to see what's happening.

Feel free to open a [Github issue](https://github.com/onedr0p/k3s-gitops/issues/new) or join our [Discord](https://discord.gg/DNCynrJ) if you have any questions.

---

## :wrench:&nbsp; Tools

_Below are some of the tools I find useful for working with my cluster_

| Tool                                                   | Purpose                                                                                                   |
|--------------------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| [direnv](https://github.com/direnv/direnv)             | Set `KUBECONFIG` environment variable based on present working directory                                  |
| [git-crypt](https://github.com/AGWA/git-crypt)         | Encrypt certain files in my repository that can only be decrypted with a key on my computers              |
| [go-task](https://github.com/go-task/task)             | Replacement for make and makefiles, who honestly likes that?                                              |
| [pre-commit](https://github.com/pre-commit/pre-commit) | Ensure the YAML and shell script in my repo are consistent                                                |
| [kubetail](https://github.com/johanhaleby/kubetail)    | Tail logs in Kubernetes, also check out [stern](https://github.com/wercker/stern) ([which fork? good luck](https://techgaun.github.io/active-forks/index.html#https://github.com/wercker/stern)) |

---

## :computer:&nbsp; Cluster setup

See my project over at [home-operations](https://github.com/onedr0p/home-operations) for how I provisioned my nodes and other work that supports running this cluster.

---

## :memo:&nbsp; IP addresses

_This table is a reference to IP addresses in my cluster and may not be fully up-to-date_

| Deployment               | Address        |
|--------------------------|----------------|
| nginx-ingress (external) | 192.168.69.100 |
| nginx-ingress (internal) | 192.168.69.101 |
| home-assistant           | 192.168.69.105 |
| influxdb                 | 192.168.69.109 |
| vernemq                  | 192.168.69.110 |
| blocky                   | 192.168.69.115 |
| gitea                    | 192.168.69.125 |
| qbittorrent              | 192.168.69.130 |
| plex                     | 192.168.69.140 |
| loki-syslog              | 192.168.69.155 |
| coredns                  | 192.168.69.180 |

---

## :handshake:&nbsp; Thanks

A lot of inspiration for this repo came from the following people:

- [billimek/k8s-gitops](https://github.com/billimek/k8s-gitops)
- [carpenike/k8s-gitops](https://github.com/carpenike/k8s-gitops)
- [dcplaya/k8s-gitops](https://github.com/dcplaya/k8s-gitops)
- [rust84/k8s-gitops](https://github.com/rust84/k8s-gitops)
- [blackjid/homelab-gitops](https://github.com/blackjid/homelab-gitops)
- [bjw-s/k8s-gitops](https://github.com/bjw-s/k8s-gitops)
- [toboshii/k8s-gitops](https://github.com/toboshii/k8s-gitops)
- [raspbernetes/k8s-gitops](https://github.com/raspbernetes/k8s-gitops)
- [nlopez/k8s_home](https://github.com/nlopez/k8s_home)
