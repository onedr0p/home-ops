<div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My home operations repository :octocat:

_... managed with Flux, Renovate and GitHub Actions_ 🤖

</div>

<div align="center">

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label&logo=discord&logoColor=white&color=blue)](https://discord.gg/k8s-at-home)
[![Kubernetes](https://img.shields.io/badge/v1.25-blue?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k3s.io/)
[![Renovate](https://img.shields.io/github/actions/workflow/status/onedr0p/home-ops/renovate.yaml?branch=main&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/onedr0p/home-ops/actions/workflows/renovate.yaml)

[![Home-Internet](https://img.shields.io/uptimerobot/status/m784591389-ddbc4c84041a70eb6f6a3fb4?color=brightgreeen&label=Home%20Internet&style=for-the-badge&logo=opnSense&logoColor=white)](https://uptimerobot.com)
[![Plex](https://img.shields.io/uptimerobot/status/m784591338-cbf3205bc18109108eb0ea8e?logo=plex&logoColor=white&color=brightgreeen&label=Plex&style=for-the-badge)](https://ln.devbu.io/Fl5ME)
[![Home-Assistant](https://img.shields.io/uptimerobot/status/m786203807-32ce99612d7b2d01b89c4315?logo=homeassistant&logoColor=white&color=brightgreeen&label=Home%20Assistant&style=for-the-badge)](https://ln.devbu.io/ApwUP)
[![Grafana](https://img.shields.io/uptimerobot/status/m792427620-04fcdd7089a84863ec9f398d?logo=grafana&logoColor=white&color=brightgreeen&label=Grafana&style=for-the-badge)](https://ln.devbu.io/tu0B6)

</div>

---

<div align="center">

[<img src="https://grafana.devbu.io/render/d-solo/efa86fd1d0c121a26444b636a3f509a8/kubernetes-compute-resources-cluster?orgId=1&from=now-1d%2Fd&to=now-1d%2Fd&panelId=1&width=200&height=100&theme=dark" width="200px" alt="cpu"/>](https://ln.devbu.io/TiTWl)
[<img src="https://grafana.devbu.io/render/d-solo/efa86fd1d0c121a26444b636a3f509a8/kubernetes-compute-resources-cluster?orgId=1&from=now-1d%2Fd&to=now-1d%2Fd&panelId=4&width=200&height=100&theme=light" width="200px" alt="memory"/>](https://ln.devbu.io/TiTWl)
[<img src="https://grafana.devbu.io/render/d-solo/000000012/apc-smart-ups-1500?orgId=1&from=now-1d%2Fd&to=now-1d%2Fd&panelId=2&width=200&height=100&theme=dark" width="200px" alt="power"/>](https://ln.devbu.io/xG72B)

</div>

---

## 📖 Overview

This is a mono repository for my home infrastructure and Kubernetes cluster. I try to adhere to Infrastructure as Code (IaC) and GitOps practices using the tools like [Ansible](https://www.ansible.com/), [Terraform](https://www.terraform.io/), [Kubernetes](https://kubernetes.io/), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate) and [GitHub Actions](https://github.com/features/actions).

---

## ⛵ Kubernetes

There is a template over at [onedr0p/flux-cluster-template](https://github.com/onedr0p/flux-cluster-template) if you wanted to try and follow along with some of the practices I use here.

### Installation

My cluster is [k3s](https://k3s.io/) provisioned overtop bare-metal Fedora Server using the [Ansible](https://www.ansible.com/) galaxy role [ansible-role-k3s](https://github.com/PyratLabs/ansible-role-k3s). This is a semi hyper-converged cluster, workloads and block storage are sharing the same available resources on my nodes while I have a separate server for (NFS) file storage.

🔸 _[Click here](./ansible/) to see my Ansible playbooks and roles._

### Core Components

- [actions-runner-controller](https://github.com/actions/actions-runner-controller): Self-hosted Github runners.
- [calico](https://github.com/projectcalico/calico): Internal Kubernetes networking plugin.
- [cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for services in my Kubernetes cluster.
- [external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in a cloud DNS provider.
- [external-secrets](https://github.com/external-secrets/external-secrets/): Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx/): Ingress controller to expose HTTP traffic to pods over DNS.
- [rook](https://github.com/rook/rook): Distributed block storage for peristent storage.
- [sops](https://toolkit.fluxcd.io/guides/mozilla-sops/): Managed secrets for Kubernetes, Ansible and Terraform which are commited to Git.
- [tf-controller](https://github.com/weaveworks/tf-controller): Additional Flux component used to run Terraform from within a Kubernetes cluster.
- [volsync](https://github.com/backube/volsync) and [snapscheduler](https://github.com/backube/snapscheduler): Backup and recovery of persistent volume claims.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [kubernetes](./kubernetes/) folder (see Directories below) and makes the changes to my cluster based on the YAML manifests.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created. When some PRs are merged [Flux](https://github.com/fluxcd/flux2) applies the changes to my cluster.

### Directories

This Git repository contains the following directories under [kubernetes](./kubernetes/).

```sh
📁 kubernetes      # Kubernetes cluster defined as code
├─📁 bootstrap     # Flux installation
├─📁 flux          # Main Flux configuration of repository
└─📁 apps          # Apps deployed into my cluster grouped by namespace (see below)
```

### Cluster layout

Below is a a high level look at the layout of how my directory structure with Flux works. In this brief example you are able to see that `authelia` will not be able to run until `glauth` and  `cloudnative-pg` are running. It also shows that the `Cluster` custom resource depends on the `cloudnative-pg` Helm chart. This is needed because `cloudnative-pg` installs the `Cluster` custom resource definition in the Helm chart.

```python
# Key: <kind> :: <metadata.name>
GitRepository :: home-ops-kubernetes
    Kustomization :: cluster
        Kustomization :: cluster-apps
            Kustomization :: cluster-apps-authelia
                DependsOn:
                    Kustomization :: cluster-apps-glauth
                    Kustomization :: cluster-apps-cloudnative-pg-cluster
                HelmRelease :: authelia
                    DependsOn:
                        HelmRelease :: cloudnative-pg
                        HelmRelease :: glauth
            Kustomization :: cluster-apps-glauth
                HelmRelease :: glauth
            Kustomization :: cluster-apps-cloudnative-pg
                HelmRelease :: cloudnative-pg
            Kustomization :: cluster-apps-cloudnative-pg-cluster
                DependsOn:
                    Kustomization :: cluster-apps-cloudnative-pg
                Cluster :: postgres
```

### Networking

| Name                                          | CIDR              |
|-----------------------------------------------|-------------------|
| Management VLAN                               | `192.168.1.0/24`  |
| Kubernetes Nodes VLAN                         | `192.168.42.0/24` |
| Kubernetes external services (Calico w/ BGP)  | `192.168.69.0/24` |
| Kubernetes pods                               | `10.42.0.0/16`    |
| Kubernetes services                           | `10.43.0.0/16`    |

- HAProxy configured on my `Opnsense` router for the Kubernetes Control Plane Load Balancer.
- Calico configured with `externalIPs` to expose Kubernetes services with their own IP over BGP (w/ECMP) which is configured on my router.

---

## ☁️ Cloud Dependencies

While most of my infrastructure and workloads are selfhosted I do rely upon the cloud for certain key parts of my setup.

- [GitHub](https://github.com/) for hosting this repository and continuous integration/deployments.
- Domain, DNS and proxy management with [Cloudflare](https://www.cloudflare.com/).
- [1Password](https://1password.com/) paid family plan for the [External Secrets Operator](https://external-secrets.io/).
- Terraform state is handled using a free [Terraform Cloud](https://www.terraform.io/) account.
- Offsite application backups are sync to [B2 Storage](https://www.backblaze.com/b2).
- [UptimeRobot](https://uptimerobot.com/) for monitoring internet connectivity and external facing applications.
- [GCP](https://cloud.google.com/) for voice interactions with Home Assistant over Google Assistant.

_There are absolutely selfhosted alternatives that I could use for some of these but I find the maintenance burden too high of cost for running alternatives at home._

<details>
  <summary>Click here to read a bit more of my thoughts on this</summary>
For example, instead of 1Password you want to deploy HashiCorp Vault to use with the External Secrets Operator. In my opinion that shouldn't run in the same Kubernetes cluster where it is being used because it's a very critical piece of infrastructure. In this scenerio it would probably be best to deploy HC Vault to another computer in your home or use a free Oracle Cloud VM but now you just incurred the cost of maintaining that critical piece of infrastructure elsewhere.
</details>


---

## 🌐 DNS

### Ingress Controller

Over WAN, I have port forwarded ports `80` and `443` to the load balancer IP of my ingress controller that's running in my Kubernetes cluster.

[Cloudflare](https://www.cloudflare.com/) works as a proxy to hide my homes WAN IP and also as a firewall. When not on my home network, all the traffic coming into my ingress controller on port `80` and `443` comes from Cloudflare. In `Opnsense` I block all IPs not originating from the [Cloudflares list of IP ranges](https://www.cloudflare.com/ips/).

🔸 _Cloudflare is also configured to GeoIP block all countries except a few I have whitelisted_

### Internal DNS

[coredns](https://github.com/coredns/coredns) is deployed on my `Opnsense` router and all DNS queries for **my** domains are forwarded to [k8s_gateway](https://github.com/ori-edge/k8s_gateway) that is running in my cluster. With this setup `k8s_gateway` has direct access to my clusters ingresses and services and serves DNS for them in my internal network.

### Ad Blocking

[AdGuard Home](https://github.com/AdguardTeam/AdGuardHome) is deployed on my `Opnsense` router which has a upstream server pointing the `coredns` instance I mentioned above. `Adguard Home` listens on my `MANAGEMENT`, `SERVER`, `IOT` and `GUEST` networks on port `53` meanwhile `coredns` only listens on `127.0.0.1:53`. In my firewall rules I have NAT port redirection forcing all the networks to use the `Adguard Home` DNS server.

### External DNS

[external-dns](https://github.com/kubernetes-sigs/external-dns) is deployed in my cluster and configure to sync DNS records to [Cloudflare](https://www.cloudflare.com/). The only ingresses `external-dns` looks at to gather DNS records to put in `Cloudflare` are ones that I explicitly set an annotation of `external-dns.home.arpa/enabled: "true"`

🔸 _[Click here](./terraform/cloudflare) to see how else I manage Cloudflare with Terraform._

### Dynamic DNS

My home IP can change at any given time and in order to keep my WAN IP address up to date on Cloudflare. I have deployed a [CronJob](./kubernetes/apps/networking/cloudflare-ddns) in my cluster, this periodically checks and updates the `A` record `ipv4.domain.tld`.

---

## 🔧 Hardware

<details>
  <summary>Click to see da rack!</summary>

  <img src="https://user-images.githubusercontent.com/213795/172947261-65a82dcd-3274-45bd-aabf-140d60a04aa9.png" align="center" width="200px" alt="rack"/>
</details>

| Device                    | Count | OS Disk Size | Data Disk Size              | Ram  | Operating System | Purpose             |
|---------------------------|-------|--------------|-----------------------------|------|------------------|---------------------|
| Protectli FW6D            | 1     | 500GB mSATA  | -                           | 16GB | Opnsense         | Router              |
| Intel NUC8i3BEK           | 3     | 256GB NVMe   | -                           | 32GB | Fedora           | Kubernetes Masters  |
| Intel NUC8i5BEH           | 3     | 240GB SSD    | 1TB NVMe (rook-ceph)        | 64GB | Fedora           | Kubernetes Workers  |
| PowerEdge T340            | 1     | 2TB SSD      | 8x12TB ZFS (mirrored vdevs) | 64GB | Ubuntu           | NFS + Backup Server |
| Lenovo SA120              | 1     | -            | 6x12TB (+2 hot spares)      | -    | -                | DAS                 |
| Raspberry Pi              | 1     | 32GB (SD)    | -                           | 4GB  | PiKVM            | Network KVM         |
| TESmart 8 Port KVM Switch | 1     | -            | -                           | -    | -                | Network KVM (PiKVM) |
| APC SMT1500RM2U w/ NIC    | 1     | -            | -                           | -    | -                | UPS                 |
| Unifi USP PDU Pro         | 1     | -            | -                           | -    | -                | PDU                 |

---

## 🤝 Gratitude and Thanks

Thanks to all the people who donate their time to the [Kubernetes @Home](https://discord.gg/k8s-at-home) Discord community. A lot of inspiration for my cluster comes from the people that have shared their clusters using the [k8s-at-home](https://github.com/topics/k8s-at-home) GitHub topic. Be sure to check out the [Kubernetes @Home search](https://nanne.dev/k8s-at-home-search/) for ideas on how to deploy applications or get ideas on what you can deploy.

---

## 📜 Changelog

See _awful_ [commit history](https://github.com/onedr0p/home-ops/commits/main)

---

## 🔏 License

See [LICENSE](./LICENSE)
