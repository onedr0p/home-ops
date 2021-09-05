# Home Cluster

This repository _is_ my home Kubernetes cluster in a declarative state. [Flux](https://github.com/fluxcd/flux2) watches my [cluster](./cluster/) folder and makes the changes to my cluster based on the YAML manifests.

Feel free to open a [Github issue](https://github.com/onedr0p/home-cluster/issues/new/choose) or join the [k8s@home Discord](https://discord.gg/sTMX7Vh) if you have any questions.

This repository is built off the [k8s-at-home/template-cluster-k3s](https://github.com/k8s-at-home/template-cluster-k3s) repository.

## Cluster setup

My cluster is [k3s](https://k3s.io/) provisioned overtop Ubuntu 21.04 using the [Ansible](https://www.ansible.com/) galaxy role [ansible-role-k3s](https://github.com/PyratLabs/ansible-role-k3s). This is a semi hyper-converged cluster, workloads and block storage are sharing the same available resources on my nodes while I have a separate server for (NFS) file storage.

See my [ansible](./ansible/) directory for my playbooks and roles.

## Cluster components

- [calico](https://docs.projectcalico.org/about/about-calico): For internal cluster networking using BGP configured on Opnsense.
- [rook-ceph](https://rook.io/): Provides persistent volumes, allowing any application to consume RBD block storage.
- [Mozilla SOPS](https://toolkit.fluxcd.io/guides/mozilla-sops/): Encrypts secrets which is safe to store - even to a public repository.
- [external-dns](https://github.com/kubernetes-sigs/external-dns): Creates DNS entries in a separate [coredns](https://github.com/coredns/coredns) deployment which is backed by my clusters [etcd](https://github.com/etcd-io/etcd) deployment.
- [cert-manager](https://cert-manager.io/docs/): Configured to create TLS certs for all ingress services automatically using LetsEncrypt.
- [kube-vip](https://github.com/kube-vip/kube-vip): HA solution for Kubernetes control plane
- [Kasten](https://www.kasten.io): Data backup and recovery

## Repository structure

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

## Automate all the things!

- [Github Actions](https://docs.github.com/en/actions) for checking code formatting
- Rancher [System Upgrade Controller](https://github.com/rancher/system-upgrade-controller) to apply updates to k3s
- [Renovate](https://github.com/renovatebot/renovate) with the help of the [k8s-at-home/renovate-helm-releases](https://github.com/k8s-at-home/renovate-helm-releases) Github action keeps my application charts and container images up-to-date

## Hardware

| Device          | Count | OS Disk Size | Data Disk Size       | Ram  | Purpose                     |
|-----------------|-------|--------------|----------------------|------|-----------------------------|
| Intel NUC8i3BEK | 3     | 256GB NVMe   | N/A                  | 16GB | k3s Masters (embedded etcd) |
| Intel NUC8i5BEH | 1     | 240GB SSD    | 1TB NVMe (rook-ceph) | 32GB | k3s Workers                 |
| Intel NUC8i7BEH | 2     | 240GB SSD    | 1TB NVMe (rook-ceph) | 32GB | k3s Workers                 |
| PowerEdge T340  | 1     | 120GB SSD    | 8x12TB RAIDz2        | 32GB | Shared file storage         |

## Tools

| Tool                                                   | Purpose                                                      |
| ------------------------------------------------------ | ------------------------------------------------------------ |
| [direnv](https://github.com/direnv/direnv)             | Sets environment variable based on present working directory |
| [go-task](https://github.com/go-task/task)             | Alternative to makefiles, who honestly likes that?           |
| [pre-commit](https://github.com/pre-commit/pre-commit) | Enforce code consistency and verifies no secrets are pushed  |
| [stern](https://github.com/stern/stern)                | Tail logs in Kubernetes                                      |

## Thanks

A lot of inspiration for my cluster came from the people that have shared their clusters over at [awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes)
