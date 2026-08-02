# Bootstrap

Everything needed to take freshly installed Talos nodes to a cluster that Flux
manages on its own. The entire process is driven by a single command:

```sh
just bootstrap cluster
```

Once it completes, Flux reconciles the rest of the repository and this
directory is not used again until the next rebuild.

## Prerequisites

- Tools installed via `mise install` (talosctl, kubectl, helmfile, kustomize,
  just, minijinja-cli, op, gum, yq).
- A signed-in 1Password CLI (`op`). Machine secrets never live in this repo;
  every `op://` reference in the Talos configs and bootstrap manifests is
  resolved at apply time with `op inject`.
- A valid `talosconfig`. The justfile derives the controller endpoint and node
  list from `talosctl config info`, so nothing is hardcoded here.
- The UDM configuration below, so that `k8s.internal` resolves and routes to
  the anycast API address before any node exists.

## UDM configuration

Talos itself advertises the API address `192.168.66.1/32` over BGP (see
`talos/cluster.yaml.j2`), so the Kubernetes API is reachable as soon as a
control plane node is up — no CNI or LoadBalancer required. The router side
of that arrangement lives on the UDM and must be in place before bootstrap:

### DNS record

A static A record in UniFi (Settings → Routing → DNS):

```text
k8s.internal → 192.168.66.1
```

### Peering VLAN

The Talos host BGP sessions need source addresses distinct from Cilium's
(FRR keys peers by source IP), so they peer over a dedicated VLAN:

- VLAN 67, subnet `192.168.67.0/24`, UDM at `192.168.67.1`
- Nodes at `192.168.67.10-12` (static, defined per node in `talos/nodes/`)
- Tagged on the node trunk ports; the native VLAN stays SERVERS (42)

### BGP

UniFi accepts a single FRR config upload per device (Settings → Routing →
BGP), so both peer-groups — Cilium's LoadBalancer announcements and the Talos
host speaker — live in one merged config. Re-uploading briefly bounces
established sessions:

```text
router bgp 64513
  bgp router-id 192.168.1.1
  no bgp ebgp-requires-policy

  neighbor k8s peer-group
  neighbor k8s remote-as 64514

  neighbor 192.168.42.10 peer-group k8s
  neighbor 192.168.42.11 peer-group k8s
  neighbor 192.168.42.12 peer-group k8s

  neighbor k8s-host peer-group
  neighbor k8s-host remote-as 64515

  neighbor 192.168.67.10 peer-group k8s-host
  neighbor 192.168.67.11 peer-group k8s-host
  neighbor 192.168.67.12 peer-group k8s-host

  address-family ipv4 unicast
    maximum-paths 3
    neighbor k8s next-hop-self
    neighbor k8s soft-reconfiguration inbound
    neighbor k8s-host next-hop-self
    neighbor k8s-host soft-reconfiguration inbound
  exit-address-family
exit
```

`maximum-paths 3` gives true ECMP across the three control plane nodes
(FRR's eBGP default is a single best path).

To verify: `talosctl get bgppeerstatus` per node, `vtysh -c "show bgp
summary"` on the UDM, and `192.168.66.1/32` showing three ECMP paths in
`vtysh -c "show ip route"`.

## Stages

`just bootstrap cluster` runs these stages in order (see `mod.just`):

1. **nodes** — Renders each node's Talos config (`talos/*.j2` templates plus
   1Password injection) and applies it with `talosctl apply-config --insecure`.
   Nodes that are already configured are skipped, so the stage is idempotent.
2. **k8s** — Runs `talosctl bootstrap` against the controller, retrying until
   etcd reports the cluster already exists.
3. **kubeconfig** — Fetches the kubeconfig with `talosctl kubeconfig`. The
   generated server address is `https://k8s.internal:6443`, which routes via
   the Talos anycast address and works for the remainder of the bootstrap.
4. **base** — Waits for nodes to register (they stay `Ready=False` until the
   CNI is installed), then applies:
    - `kustomize/` — bootstrap Secrets (1Password Connect credentials,
      Cloudflare tunnel ID) rendered through `op inject`, plus their
      namespaces. These exist before their controllers so nothing deadlocks on
      a missing Secret.
    - `helmfile/crds.yaml` — CRDs extracted from upstream charts
      (envoy-gateway, grafana-operator, kube-prometheus-stack) and applied
      directly. Installing CRDs out-of-band means Flux Kustomizations that
      consume CRD-backed resources don't need `dependsOn` chains.
5. **apps** — `helmfile sync` of `helmfile/apps.yaml`, the minimal release
   chain Flux needs before it can take over:

    cilium → coredns → spegel → cert-manager → external-secrets →
    onepassword-connect → flux-operator → flux-instance

    Once `flux-instance` is healthy, Flux reconciles `kubernetes/` and manages
    these same releases from then on.

## Single source of truth

The helmfiles define no chart versions or values of their own. Each release's
chart and version are read from the app's `ocirepository.yaml` and its values
from the app's `helmrelease.yaml` under `kubernetes/apps/` (see
`helmfile/templates/`). Bootstrap therefore installs exactly what Flux will
later reconcile, and Renovate updates only one place.

## Notes

- The Kubernetes API endpoint does not depend on anything installed here.
  Before Talos advertised the anycast address natively, a Cilium LoadBalancer
  Service fronted the API, which required extra helmfile hooks and a
  kubeconfig endpoint dance during bootstrap; that is gone.
- Every stage is safe to re-run. If bootstrap fails partway, fix the issue and
  run `just bootstrap cluster` again.
