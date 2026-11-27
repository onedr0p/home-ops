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
| `nodes/<role>/<node>.yaml.j2`           | Per-node documents (hostname, zone)                                       |
| `nodes/<role>/<node>.schematic.yaml.j2` | Optional per-node schematic override                                      |
| `schematic.yaml.j2`                     | Shared [Image Factory](https://factory.talos.dev) schematic               |
| `mise.toml`                             | Tasks (`mise run //talos:...`)                                            |

## Rendering

`mise run //talos:render-config <node>` builds the final machine config in three layers:

```
talosctl machineconfig patch <(cluster.yaml.j2) \
    -p @<(controlplane.yaml.j2 | workers.yaml.j2) \
    -p @<(nodes/<role>/<node>.yaml.j2)
```

Each layer passes through `minijinja-cli` (strict Jinja templating) before `talosctl` merges them.
The schematic ID arrives as a `-D` define. Later patches strategically merge into earlier ones:
documents with the same kind/name are deep-merged, new documents are appended.

Two conventions keep the layers honest:

- **Directory placement is the single source of truth for a node's role.** The role patch is chosen
  by which `nodes/<role>/` directory contains the node file, and `machine.type` is set by the role
  patch, not the node file. A node cannot claim one role by filename and another by content.
- **Secrets never live in this repo.** The 1Password document `talos` in the `kubernetes` vault
  holds the secrets bundle that `talosctl gen secrets` writes. The templates read its values by
  key path, for example `{{ certs.os.crt }}`.

## Schematics

The schematic defines the Image Factory build (system extensions, kernel args). The hidden
`//talos:schematic-id` task POSTs it to the factory and gets back a content-addressed ID, which is templated into
the `UnattendedInstallConfig` installer image and used by `download-image` and `upgrade-node`.

Resolution is per node: `nodes/<role>/<node>.schematic.yaml.j2` wins when present, otherwise the
shared `schematic.yaml.j2` applies. Overrides are complete files, not deltas; they exist for nodes
whose hardware diverges from the fleet. No overrides exist today.

## Gotchas

- `machine.ca` merges as a cert+key **unit**: a patch supplying only `key` blanks `crt`. This is
  why `controlplane.yaml.j2` repeats the `crt` reference alongside the key.
- The secrets bundle holds certificates and keys base64-encoded (the v1alpha1 format), but the CA
  and service account documents take PEM. When `talosctl` parses the patch, the YAML `!!binary` tag
  decodes the base64.
- If a template names a bundle key that does not exist, the `minijinja-cli` error prints the first
  100 characters of the secret values near that line.
- Rendering a worker before `workers.yaml.j2` and `nodes/workers/` exist fails loudly. Adding the
  first worker means creating `workers.yaml.j2` (with `machine: { type: worker }` and a
  `KubeAPIServerCAConfig` that lists the cluster CA certificate under `acceptedCAs`) plus
  `nodes/workers/<node>.yaml.j2`.

## Common tasks

```sh
mise run //talos:render-config <node>        # render a node's full machine config to stdout
mise run //talos:apply-node <node>           # render and apply (talosctl apply-config)
mise run //talos:upgrade-node <node>         # upgrade Talos using the node's schematic image
mise run //talos:upgrade-k8s <version>       # upgrade Kubernetes across the cluster
mise run //talos:download-image <version>    # fetch a metal ISO from the Image Factory
mise run //talos:gen-talosconfig             # write a talosconfig from the secrets bundle
mise run //talos:gen-secrets                 # replace the secrets bundle with a new one (new clusters only)
```

A control plane node that still runs the old configuration can rebuild the bundle that
`gen-secrets` replaced:

```sh
talosctl -n <node> get machineconfig v1alpha1 -o jsonpath='{.spec}' |
    talosctl gen secrets --from-controlplane-config /dev/stdin -o -
```

Verify a refactor of these templates by diffing rendered output before and after, then confirming
`render-config <node> | talosctl -n <node> apply-config -f /dev/stdin --dry-run` reports
"No changes." on every node.
