<div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My home Kubernetes cluster :sailboat:
_... managed with Flux and Renovate_ :robot:

</div>

<br/>

<div align="center">

[![Discord](https://img.shields.io/badge/discord-chat-7289DA.svg?maxAge=60&style=for-the-badge)](https://discord.gg/sTMX7Vh)
[![k3s](https://img.shields.io/badge/k3s-v1.21.2-orange?style=for-the-badge)](https://k3s.io/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit)
[![renovate](https://img.shields.io/badge/renovate-enabled-green?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjUgNSAzNzAgMzcwIj48Y2lyY2xlIGN4PSIxODkiIGN5PSIxOTAiIHI9IjE4NCIgZmlsbD0iI2ZlMiIvPjxwYXRoIGZpbGw9IiM4YmIiIGQ9Ik0yNTEgMjU2bC0zOC0zOGExNyAxNyAwIDAxMC0yNGw1Ni01NmMyLTIgMi02IDAtN2wtMjAtMjFhNSA1IDAgMDAtNyAwbC0xMyAxMi05LTggMTMtMTNhMTcgMTcgMCAwMTI0IDBsMjEgMjFjNyA3IDcgMTcgMCAyNGwtNTYgNTdhNSA1IDAgMDAwIDdsMzggMzh6Ii8+PHBhdGggZmlsbD0iI2Q1MSIgZD0iTTMwMCAyODhsLTggOGMtNCA0LTExIDQtMTYgMGwtNDYtNDZjLTUtNS01LTEyIDAtMTZsOC04YzQtNCAxMS00IDE1IDBsNDcgNDdjNCA0IDQgMTEgMCAxNXoiLz48cGF0aCBmaWxsPSIjYjMwIiBkPSJNMjg1IDI1OGw3IDdjNCA0IDQgMTEgMCAxNWwtOCA4Yy00IDQtMTEgNC0xNiAwbC02LTdjNCA1IDExIDUgMTUgMGw4LTdjNC01IDQtMTIgMC0xNnoiLz48cGF0aCBmaWxsPSIjYTMwIiBkPSJNMjkxIDI2NGw4IDhjNCA0IDQgMTEgMCAxNmwtOCA3Yy00IDUtMTEgNS0xNSAwbC05LThjNSA1IDEyIDUgMTYgMGw4LThjNC00IDQtMTEgMC0xNXoiLz48cGF0aCBmaWxsPSIjZTYyIiBkPSJNMjYwIDIzM2wtNC00Yy02LTYtMTctNi0yMyAwLTcgNy03IDE3IDAgMjRsNCA0Yy00LTUtNC0xMSAwLTE2bDgtOGM0LTQgMTEtNCAxNSAweiIvPjxwYXRoIGZpbGw9IiNiNDAiIGQ9Ik0yODQgMzA0Yy00IDAtOC0xLTExLTRsLTQ3LTQ3Yy02LTYtNi0xNiAwLTIybDgtOGM2LTYgMTYtNiAyMiAwbDQ3IDQ2YzYgNyA2IDE3IDAgMjNsLTggOGMtMyAzLTcgNC0xMSA0em0tMzktNzZjLTEgMC0zIDAtNCAybC04IDdjLTIgMy0yIDcgMCA5bDQ3IDQ3YTYgNiAwIDAwOSAwbDctOGMzLTIgMy02IDAtOWwtNDYtNDZjLTItMi0zLTItNS0yeiIvPjxwYXRoIGZpbGw9IiMxY2MiIGQ9Ik0xNTIgMTEzbDE4LTE4IDE4IDE4LTE4IDE4em0xLTM1bDE4LTE4IDE4IDE4LTE4IDE4em0tOTAgODlsMTgtMTggMTggMTgtMTggMTh6bTM1LTM2bDE4LTE4IDE4IDE4LTE4IDE4eiIvPjxwYXRoIGZpbGw9IiMxZGQiIGQ9Ik0xMzQgMTMxbDE4LTE4IDE4IDE4LTE4IDE4em0tMzUgMzZsMTgtMTggMTggMTgtMTggMTh6Ii8+PHBhdGggZmlsbD0iIzJiYiIgZD0iTTExNiAxNDlsMTgtMTggMTggMTgtMTggMTh6bTU0LTU0bDE4LTE4IDE4IDE4LTE4IDE4em0tODkgOTBsMTgtMTggMTggMTgtMTggMTh6bTEzOS04NWwyMyAyM2M0IDQgNCAxMSAwIDE2TDE0MiAyNDBjLTQgNC0xMSA0LTE1IDBsLTI0LTI0Yy00LTQtNC0xMSAwLTE1bDEwMS0xMDFjNS01IDEyLTUgMTYgMHoiLz48cGF0aCBmaWxsPSIjM2VlIiBkPSJNMTM0IDk1bDE4LTE4IDE4IDE4LTE4IDE4em0tNTQgMThsMTgtMTcgMTggMTctMTggMTh6bTU1LTUzbDE4LTE4IDE4IDE4LTE4IDE4em05MyA0OGwtOC04Yy00LTUtMTEtNS0xNiAwTDEwMyAyMDFjLTQgNC00IDExIDAgMTVsOCA4Yy00LTQtNC0xMSAwLTE1bDEwMS0xMDFjNS00IDEyLTQgMTYgMHoiLz48cGF0aCBmaWxsPSIjOWVlIiBkPSJNMjcgMTMxbDE4LTE4IDE4IDE4LTE4IDE4em01NC01M2wxOC0xOCAxOCAxOC0xOCAxOHoiLz48cGF0aCBmaWxsPSIjMGFhIiBkPSJNMjMwIDExMGwxMyAxM2M0IDQgNCAxMSAwIDE2TDE0MiAyNDBjLTQgNC0xMSA0LTE1IDBsLTEzLTEzYzQgNCAxMSA0IDE1IDBsMTAxLTEwMWM1LTUgNS0xMSAwLTE2eiIvPjxwYXRoIGZpbGw9IiMxYWIiIGQ9Ik0xMzQgMjQ4Yy00IDAtOC0yLTExLTVsLTIzLTIzYTE2IDE2IDAgMDEwLTIzTDIwMSA5NmExNiAxNiAwIDAxMjIgMGwyNCAyNGM2IDYgNiAxNiAwIDIyTDE0NiAyNDNjLTMgMy03IDUtMTIgNXptNzgtMTQ3bC00IDItMTAxIDEwMWE2IDYgMCAwMDAgOWwyMyAyM2E2IDYgMCAwMDkgMGwxMDEtMTAxYTYgNiAwIDAwMC05bC0yNC0yMy00LTJ6Ii8+PC9zdmc+)](https://github.com/renovatebot/renovate)

</div>

<br/>

## :book:&nbsp; Overview

This repository _is_ my home Kubernetes cluster in a declarative state. [Flux](https://github.com/fluxcd/flux2) watches my [cluster](./cluster/) folder and makes the changes to my cluster based on the YAML manifests.

Feel free to open a [Github issue](https://github.com/onedr0p/home-cluster/issues/new/choose) or join the [k8s@home Discord](https://discord.gg/sTMX7Vh) if you have any questions.

This repository is built off the [k8s-at-home/template-cluster-k3s](https://github.com/k8s-at-home/template-cluster-k3s) repository.

---

## :sparkles:&nbsp; Cluster setup

My cluster is [k3s](https://k3s.io/) provisioned overtop Ubuntu 21.04 using the [Ansible](https://www.ansible.com/) galaxy role [ansible-role-k3s](https://github.com/PyratLabs/ansible-role-k3s). This is a semi hyper-converged cluster, workloads and block storage are sharing the same available resources on my nodes.

See my [server/ansible](./server/ansible/) directory for my playbooks and roles.

## :art:&nbsp; Cluster components

  - [calico](https://docs.projectcalico.org/about/about-calico): For internal cluster networking using BGP configured on Opnsense.
  - [rook-ceph](https://rook.io/): Provides persistent volumes, allowing any application to consume RBD block storage.
  - [SOPS](https://toolkit.fluxcd.io/guides/mozilla-sops/): Encrypts secrets which is safe to store - even to a public repository.
  - [external-dns](https://github.com/kubernetes-sigs/external-dns): Creates DNS entries in a separate [coredns](https://github.com/coredns/coredns) deployment which is backed by my clusters [etcd](https://github.com/etcd-io/etcd) deployment.
  - [cert-manager](https://cert-manager.io/docs/): Configured to create TLS certs for all ingress services automatically using LetsEncrypt.
  - [kube-vip](https://github.com/kube-vip/kube-vip): HA solution for Kubernetes control plane

---

## :open_file_folder:&nbsp; Repository structure

The Git repository contains the following directories under `cluster` and are ordered below by how Flux will apply them.

- **base** directory is the entrypoint to Flux
- **crds** directory contains custom resource definitions (CRDs) that need to exist globally in your cluster before anything else exists
- **core** directory (depends on **crds**) are important infrastructure applications (grouped by namespace) that should never be pruned by Flux
- **apps** directory (depends on **core**) is where your common applications (grouped by namespace) could be placed, Flux will prune resources here if they are not tracked by Git anymore

```
./cluster
├── ./apps
├── ./base
├── ./core
└── ./crds
```

---

## :robot:&nbsp; Automate all the things!

- [Github Actions](https://docs.github.com/en/actions) for checking code formatting
- Rancher [System Upgrade Controller](https://github.com/rancher/system-upgrade-controller) to apply updates to k3s
- [Renovate](https://github.com/renovatebot/renovate) with the help of the [k8s-at-home/renovate-helm-releases](https://github.com/k8s-at-home/renovate-helm-releases) Github action keeps my application charts and container images up-to-date

---

## :spider_web:&nbsp; Networking

_Currently when using BGP on Opnsense, services do not get properly load balanced. This is due to Opnsense not supporting multipath in the BSD kernel._

In my network Calico is configured with BGP on my [Opnsense](https://opnsense.org/) router. With BGP enabled, I advertise a load balancer using `externalIPs` on my Kubernetes services.

| Name                        | CIDR              |
|-----------------------------|-------------------|
| Management                  | `192.168.1.0/24`  |
| Servers                     | `192.168.42.0/24` |
| k8s external services (BGP) | `192.168.69.0/24` |
| k8s pods                    | `10.69.0.0/16`    |
| k8s services                | `10.96.0.0/16`    |

## :man_shrugging:&nbsp; DNS

To prefix this, I should mention that I only use one domain name for internal and externally facing applications. Also this is the most complicated thing to explain but I will try to sum it up.

On [Opnsense](https://opnsense.org/) under `Services: Unbound DNS: Overrides` I have a `Domain Override` set to my domain with the address pointing to my _in-cluster-non-cluster service_ CoreDNS load balancer IP. This allows me to use [Split-horizon DNS](https://en.wikipedia.org/wiki/Split-horizon_DNS). [external-dns](https://github.com/kubernetes-sigs/external-dns) reads my clusters `Ingress`'s and inserts DNS records containing the sub-domain and load balancer IP (of traefik) into the _in-cluster-non-cluster service_ CoreDNS service and into Cloudflare depending on if an annotation is present on the ingress. See the diagram below for a visual representation.

<div align="center">
<img src="https://user-images.githubusercontent.com/213795/116820353-91f6e480-ab42-11eb-9109-95e485df9249.png" align="center" />
</div>

---

## :gear:&nbsp; Hardware

| Device                  | Count | OS Disk Size | Data Disk Size       | Ram  | Purpose                       |
|-------------------------|-------|--------------|----------------------|------|-------------------------------|
| Intel NUC8i3BEK         | 3     | 256GB NVMe   | N/A                  | 16GB | k3s Masters (embedded etcd)   |
| Intel NUC8i5BEH         | 1     | 240GB SSD    | 1TB NVMe (rook-ceph) | 32GB | k3s Workers                   |
| Intel NUC8i7BEH         | 2     | 240GB SSD    | 1TB NVMe (rook-ceph) | 32GB | k3s Workers                   |
| Qnap NAS (rocinante)    | 1     | N/A          | 8x12TB RAID6         | 16GB | Shared file storage           |

---

## :wrench:&nbsp; Tools

| Tool                                                                                            | Purpose                                                                   |
|-------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------|
| [direnv](https://github.com/direnv/direnv)                                                      | Sets `KUBECONFIG` environment variable based on present working directory |
| [go-task](https://github.com/go-task/task)                                                      | Alternative to makefiles, who honestly likes that?                        |
| [pre-commit](https://github.com/pre-commit/pre-commit)                                          | Enforce code consistency and verifies no secrets are pushed               |
| [kubetail](https://github.com/johanhaleby/kubetail) / [stern](https://github.com/stern/stern) | Tail logs in Kubernetes                                                   |
---

## :handshake:&nbsp; Thanks

A lot of inspiration for my cluster came from the people that have shared their clusters over at [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes)
