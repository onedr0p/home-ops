# Talos

Declarative [Talos Linux](https://www.talos.dev) machine configuration for the cluster, built from
composable multi-document patches. Nothing in this directory is applied automatically; configs are
rendered on demand and pushed to nodes with `talosctl`.

## Layout

| Path                                    | Purpose                                                                   |
| --------------------------------------- | ------------------------------------------------------------------------- |
| `cluster.yaml.j2`                       | Documents applied to every node                                           |
| `controlplane.yaml.j2`                  | Control-plane-only documents, including `machine.type`                    |
| `workers.yaml.j2`                       | Worker-only documents (does not exist yet; created with the first worker) |
| `nodes/<role>/<node>.yaml.j2`           | Per-node documents (hostname, addresses, BGP router ID, zone)             |
| `nodes/<role>/<node>.schematic.yaml.j2` | Optional per-node schematic override                                      |
| `schematic.yaml.j2`                     | Shared [Image Factory](https://factory.talos.dev) schematic               |
| `mod.just`                              | Recipes (`just talos ...`)                                                |

## Rendering

`just talos render-config <node>` builds the final machine config in three layers:

```
talosctl machineconfig patch <(cluster.yaml.j2) \
    -p @<(controlplane.yaml.j2 | workers.yaml.j2) \
    -p @<(nodes/<role>/<node>.yaml.j2)
```

Each layer passes through `minijinja-cli` (strict Jinja templating; the schematic ID arrives as a
`-D` define) and `op inject` (1Password secret resolution) before `talosctl` merges them. Later patches strategically merge into
earlier ones: documents with the same kind/name are deep-merged, new documents are appended.

Two conventions keep the layers honest:

- **Directory placement is the single source of truth for a node's role.** The role patch is chosen
  by which `nodes/<role>/` directory contains the node file, and `machine.type` is set by the role
  patch, not the node file. A node cannot claim one role by filename and another by content.
- **Secrets never live in this repo.** All sensitive values are `op://kubernetes/talos/...`
  references resolved at render time.

## Schematics

The schematic defines the Image Factory build (system extensions, kernel args). `just talos
schematic-id` POSTs it to the factory and gets back a content-addressed ID, which is templated into
the `UnattendedInstallConfig` installer image and used by `download-image` and `upgrade-node`.

Resolution is per node: `nodes/<role>/<node>.schematic.yaml.j2` wins when present, otherwise the
shared `schematic.yaml.j2` applies. Overrides are complete files, not deltas; they exist for nodes
whose hardware diverges from the fleet. No overrides exist today.

## Gotchas

- `machine.ca` and `cluster.ca` merge as a cert+key **unit**: a patch supplying only `key` blanks
  `crt`. This is why `controlplane.yaml.j2` repeats the `crt` references alongside the keys.
- Rendering a worker before `workers.yaml.j2` and `nodes/workers/` exist fails loudly. Adding the
  first worker means creating `workers.yaml.j2` (with `machine: { type: worker }` and a `ca` block
  carrying `crt` only) plus `nodes/workers/<node>.yaml.j2`.

## Common tasks

```sh
just talos render-config <node>        # render a node's full machine config to stdout
just talos apply-node <node>           # render and apply (talosctl apply-config)
just talos upgrade-node <node>         # upgrade Talos using the node's schematic image
just talos upgrade-k8s <version>       # upgrade Kubernetes across the cluster
just talos download-image <version>    # fetch a metal ISO from the Image Factory
```

Verify a refactor of these templates by diffing rendered output before and after, then confirming
`render-config <node> | talosctl -n <node> apply-config -f /dev/stdin --dry-run` reports
"No changes." on every node.
