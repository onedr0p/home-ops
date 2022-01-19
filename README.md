<div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My home operations repository :octocat:

_... managed with Flux, Renovate and GitHub Actions_ :robot:

</div>

<br/>

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label=discord&logo=discord&logoColor=white)](https://discord.gg/k8s-at-home)
[![k3s](https://img.shields.io/badge/k3s-v1.23.1-brightgreen?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k3s.io/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white&style=for-the-badge)](https://github.com/pre-commit/pre-commit)
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/onedr0p/home-ops/Schedule%20-%20Renovate?label=renovate&logo=renovatebot&style=for-the-badge)
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

🔸 _[Click here](./ansible/) to see my Ansible playbooks and roles._

### Core Components

- [projectcalico/calico](https://github.com/projectcalico/calico): Internal Kubernetes networking plugin.
- [rook/rook](https://github.com/projectcalico/calico): Distributed block storage for peristent storage.
- [mozilla/sops](https://toolkit.fluxcd.io/guides/mozilla-sops/): Manages secrets for Kubernetes, Ansible and Terraform.
- [kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in a cloud DNS provider.
- [jetstack/cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for services in my Kubernetes cluster.
- [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx/): Ingress controller to expose HTTP traffic to pods over DNS.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [cluster](./cluster/) folder (see Directories below) and makes the changes to my cluster based on the YAML manifests.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created. When some PRs are merged [Flux](https://github.com/fluxcd/flux2) applies the changes to my cluster.

### Directories

The Git repository contains the following directories under [cluster](./cluster/) and are ordered below by how [Flux](https://github.com/fluxcd/flux2) will apply them.

- **base**: directory is the entrypoint to [Flux](https://github.com/fluxcd/flux2).
- **crds**: directory contains custom resource definitions (CRDs) that need to exist globally in your cluster before anything else exists.
- **core**: directory (depends on **crds**) are important infrastructure applications (grouped by namespace) that should never be pruned by [Flux](https://github.com/fluxcd/flux2).
- **apps**: directory (depends on **core**) is where your common applications (grouped by namespace) could be placed, [Flux](https://github.com/fluxcd/flux2) will prune resources here if they are not tracked by Git anymore.

### Networking

- HAProxy configured on Opnsense for the Kubernetes Control Plane Load Balancer.
- Calico configured with `externalIPs` to expose Kubernetes services with their own IP over BGP.

| Name                                         | CIDR              |
|----------------------------------------------|-------------------|
| Kubernetes Nodes                             | `192.168.42.0/24` |
| Kubernetes external services (Calico w/ BGP) | `192.168.69.0/24` |
| Kubernetes pods                              | `10.69.0.0/16`    |
| Kubernetes services                          | `10.96.0.0/16`    |

### Persistent Volume Data Backup and Recovery

This is a hard topic to explain because there isn't a single great tool to work with rook-ceph. There's [Velero](https://github.com/vmware-tanzu/velero), [Benji](https://github.com/elemental-lf/benji), [Gemini](https://github.com/FairwindsOps/gemini), and others but they all have different amount of issues or nuances which makes them unsable for me. Right now I am using [Kasten K10 by Veeam](https://www.kasten.io/product/) which does a good job of snapshotting Ceph block volumes and exports the data to durable storage (S3 / NFS).

There is also the manual method of scaling down the application and using the rook-ceph toolbox to mount the PV which allows you to tar up the volume data and send it to a NFS server. This method works great if all other options do not work.

---

## :globe_with_meridians:&nbsp; DNS

### Ingress Controller

I have port forwarded ports `80` and `443` to the load balancer IP of my ingress controller that's running in my Kubernetes cluster.

[Cloudflare](https://www.cloudflare.com/) works as a proxy to hide my homes WAN IP and also as a firewall. All the traffic coming into my ingress controller on port `80` and `443` comes from Cloudflare, which means in `Opnsense` I block all IPs not originating from the [Cloudflares list of IP ranges](https://www.cloudflare.com/ips/).

🔸 _Cloudflare is also configured to GeoIP block all countries except a few I have whitelisted_

### Internal DNS
[CoreDNS](https://github.com/coredns/coredns) is deployed on `Opnsense` with the [k8s_gateway](https://github.com/ori-edge/k8s_gateway) external plugin. With this setup, `CoreDNS` has direct access to my clusters ingress records and serves DNS for them in my internal network.

🔸 _I maintain a build of `CoreDNS` for FreeBSD over at [onedr0p/opnsense-coredns](https://github.com/onedr0p/opnsense-coredns) that includes the `k8s_gateway` plugin._

### External DNS

[external-dns](https://github.com/kubernetes-sigs/external-dns) is deployed in my cluster and configure to sync DNS records to [Cloudflare](https://www.cloudflare.com/). The only ingresses `external-dns` looks at to gather DNS records are ones that I explicitly set an annotation of `external-dns/is-public: "true"`

🔸 _[Click here](./terraform/cloudflare) to see how else I manage Cloudflare._

### Dynamic DNS

My home IP can change at any given time and in order to keep my WAN IP address up to date on Cloudflare I have deployed a [CronJob](./cluster/apps/networking/cloudflare-ddns) in my cluster. This periodically checks and updates the `A` record `ipv4.domain.tld`.

---

## :zap:&nbsp; Network Attached Storage

:construction: Work in Progress :construction:

---

## :wrench:&nbsp; Hardware

| Device                    | Count | OS Disk Size | Data Disk Size       | Ram  | Operating System | Purpose                      |
|---------------------------|-------|--------------|----------------------|------|------------------|------------------------------|
| Protectli FW6D            | 1     | 500GB mSATA  | N/A                  | 64GB | Opnsense 22.x    | Router                       |
| Intel NUC8i3BEK           | 3     | 256GB NVMe   | N/A                  | 16GB | Ubuntu 20.04     | Kubernetes (k3s) Masters     |
| Intel NUC8i5BEH           | 3     | 240GB SSD    | 1TB NVMe (rook-ceph) | 32GB | Ubuntu 20.04     | Kubernetes (k3s) Workers     |
| PowerEdge T340            | 1     | 120GB SSD    | 8x12TB RAIDz2        | 32GB | Ubuntu 21.10     | Shared file storage          |
| Lenovo SA120              | 1     | N/A          | 8x12TB               | N/A  | N/A              | DAS                          |
| Raspberry Pi              | 1     | 32GB SD Card | N/A                  | 4GB  | PiKVM            | Network KVM                  |
| TESmart 8 Port KVM Switch | 1     | N/A          | N/A                  | N/A  | N/A              | Network KVM switch for PiKVM |

---

## :handshake:&nbsp; Graditude and Thanks

Thanks to all the people who donate their time to the [Kubernetes @Home](https://github.com/k8s-at-home/) community. A lot of inspiration for my cluster came from the people that have shared their clusters over at [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes).

---

## :scroll:&nbsp; Changelog

See [commit history](https://github.com/onedr0p/home-ops/commits/main)

---

## :lock_with_ink_pen:&nbsp; License

See [LICENSE](./LICENSE)
