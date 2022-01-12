<div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My home Kubernetes cluster :sailboat:

_... managed with Flux and Renovate_ :robot:

</div>

<br/>

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label=discord&logo=discord&logoColor=white)](https://discord.gg/k8s-at-home)
[![k3s](https://img.shields.io/badge/k3s-v1.23.1-brightgreen?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k3s.io/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit)
[![renovate](https://img.shields.io/badge/renovate-enabled-brightgreen?style=for-the-badge&logo=renovatebot&logoColor=white)](https://github.com/renovatebot/renovate)
[![read-my-docs](https://img.shields.io/badge/read%20my-docs-brightgreen?logo=read-the-docs&logoColor=white&style=for-the-badge)](https://onedr0p.github.io/home-ops/)
[![Lines of code](https://img.shields.io/tokei/lines/github/onedr0p/home-ops?style=for-the-badge&color=brightgreen&label=lines&logo=codefactor&logoColor=white)](https://github.com/onedr0p/home-ops/graphs/contributors)

</div>

<div align="center">

[![Home-Internet](https://img.shields.io/uptimerobot/status/m784591389-ddbc4c84041a70eb6f6a3fb4?color=important&label=home%20internet&style=flat-square&logo=opnSense&logoColor=white)](https://uptimerobot.com)
[![My-Plex](https://img.shields.io/uptimerobot/status/m784591338-cbf3205bc18109108eb0ea8e?logo=plex&logoColor=white&color=important&label=my%20plex&style=flat-square)](https://plex.tv)
[![My-Home-Assistant](https://img.shields.io/uptimerobot/status/m786203807-32ce99612d7b2d01b89c4315?logo=homeassistant&logoColor=white&color=important&label=my%20home%20assistant&style=flat-square)](https://www.home-assistant.io/)

</div>

---

## :book:&nbsp; Overview

This is a mono repository for my home infrastructure and Kubernetes cluster. I try to adhere to Infrastructure as Code (IaC) and GitOps practices using the tools like [Ansible](https://www.ansible.com/), [Terraform](https://www.terraform.io/), [Kubernetes](https://kubernetes.io/), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions)

---

## :sailboat:&nbsp; Kubernetes

### Installation

My cluster is [k3s](https://k3s.io/) provisioned overtop Ubuntu 20.04 using the [Ansible](https://www.ansible.com/) galaxy role [ansible-role-k3s](https://github.com/PyratLabs/ansible-role-k3s). This is a semi hyper-converged cluster, workloads and block storage are sharing the same available resources on my nodes while I have a separate server for (NFS) file storage.

See my [ansible](./ansible/) directory for my playbooks and roles.

### Core Components

- [projectcalico/calico](https://github.com/projectcalico/calico): Internal Kubernetes networking plugin
- [rook/rook](https://github.com/projectcalico/calico): Distributed block storage for RWO volumes
- [mozilla/sops](https://toolkit.fluxcd.io/guides/mozilla-sops/): Manages secrets for Kubernetes, Ansible and Terraform.
- [kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in a cloud DNS provider.
- [jetstack/cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for services in my Kubernetes cluster.
- [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx/): Ingress controller to expose HTTP traffic to pods over DNS.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [cluster](./cluster/) folder (see Directories below) and makes the changes to my cluster based on the YAML manifests.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created. When some PRs are merged [Flux](https://github.com/fluxcd/flux2) applies the changes to my cluster.

### Directories

The Git repository contains the following directories under [cluster](./cluster/) and are ordered below by how [Flux](https://github.com/fluxcd/flux2) will apply them.

- **base**: directory is the entrypoint to [Flux](https://github.com/fluxcd/flux2)
- **crds**: directory contains custom resource definitions (CRDs) that need to exist globally in your cluster before anything else exists
- **core**: directory (depends on **crds**) are important infrastructure applications (grouped by namespace) that should never be pruned by [Flux](https://github.com/fluxcd/flux2)
- **apps**: directory (depends on **core**) is where your common applications (grouped by namespace) could be placed, [Flux](https://github.com/fluxcd/flux2) will prune resources here if they are not tracked by Git anymore

---

## :wrench:&nbsp; Hardware

| Device                    | Count | OS Disk Size | Data Disk Size       | Ram  | Purpose                      |
|---------------------------|-------|--------------|----------------------|------|------------------------------|
| Intel NUC8i3BEK           | 3     | 256GB NVMe   | N/A                  | 16GB | Kubernetes Masters           |
| Intel NUC8i5BEH           | 3     | 240GB SSD    | 1TB NVMe (rook-ceph) | 32GB | Kubernetes Workers           |
| PowerEdge T340            | 1     | 120GB SSD    | 8x12TB RAIDz2        | 32GB | Shared file storage          |
| Lenovo SA120              | 1     |              | 8x12TB               |      | DAS                          |
| Raspberry Pi              | 1     | 32GB SD Card | N/A                  | 4GB  | PiKVM                        |
| TESmart 8 Port KVM Switch | 1     | N/A          | N/A                  | N/A  | Network KVM switch for PiKVM |

---

## :handshake:&nbsp; Thanks

Thanks to all the people who donate their time to the [Kubernetes @Home](https://github.com/k8s-at-home/) community. A lot of inspiration for my cluster came from the people that have shared their clusters over at [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes).
