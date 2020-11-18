<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="left" width="144px" height="144px"/>

#### My home Kubernetes cluster :sailboat:
_... managed by Flux_

[![Discord](https://img.shields.io/badge/discord-chat-7289DA.svg?maxAge=60&style=flat-square)](https://discord.gg/DNCynrJ)
[![k3s](https://img.shields.io/badge/k3s-v1.19.3-orange?style=flat-square)](https://k3s.io/)
[![GitHub stars](https://img.shields.io/github/stars/onedr0p/k3s-gitops?color=green&style=flat-square)](https://github.com/onedr0p/k3s-gitops/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/onedr0p/k3s-gitops?style=flat-square)](https://github.com/onedr0p/k3s-gitops/issues)
[![GitHub last commit](https://img.shields.io/github/last-commit/onedr0p/k3s-gitops?color=purple&style=flat-square)](https://github.com/onedr0p/k3s-gitops/commits/master)
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/onedr0p/k3s-gitops/lint?color=blue&style=flat-square)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=flat-square)](https://github.com/pre-commit/pre-commit)

<br/>

---

## :book:&nbsp; Overview

This repository _is_ my homelab Kubernetes cluster in a declarative state. [Flux2](https://github.com/fluxcd/flux2) watches my [cluster](./cluster/) folder and makes the changes to my cluster based on the YAML manifests.

[Renovatebot](https://github.com/renovatebot/renovate) keeps my applications up-to-date by scanning my repo and opening pull requests when it notices a new container image update.

[Actions Runner Controller](https://github.com/summerwind/actions-runner-controller) operates a self-hosted Github runner in my cluster which I use to generate and apply Sealed Secrets to my cluster. 

Feel free to open a [Github issue](https://github.com/onedr0p/k3s-gitops/issues/new) or join the k8s@home [Discord](https://discord.gg/DNCynrJ) if you have any questions.

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
| vernemq                  | 192.168.69.110 |
| blocky                   | 192.168.69.115 |
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
