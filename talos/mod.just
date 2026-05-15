set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']
set working-directory := '.'

[private]
default:
    just -l talos

[doc('Apply Talos config (pass --nodes-filter <regex> to scope)')]
apply *args:
    topf apply --confirm {{ args }}

[doc('Reset Talos node(s) to maintenance mode (use --nodes-filter)')]
reset *args:
    topf reset {{ args }}

[doc('Upgrade Talos on node(s) (use --nodes-filter)')]
upgrade *args:
    topf upgrade {{ args }}

[doc('List nodes and their current state')]
nodes:
    topf nodes

[doc('Output non-sensitive cluster information')]
clusterinfo:
    topf clusterinfo

[doc('Generate a temporary admin kubeconfig')]
kubeconfig:
    topf kubeconfig

[doc('Generate and save talosconfig from the secrets bundle')]
talosconfig:
    topf talosconfig

[confirm('Reboot node ' + node + ' [y|N] ?')]
[doc('Reboot a node')]
reboot-node node:
    talosctl -n {{ node }} reboot -m powercycle

[confirm('Shutdown node ' + node + ' [y|N] ?')]
[doc('Shutdown a node')]
shutdown-node node *args:
    talosctl -n "{{ node }}" shutdown --force {{ args }}

[confirm('Upgrade Kubernetes to ' + version + ' [y|N] ?')]
[doc('Upgrade Kubernetes version on the cluster')]
upgrade-k8s version:
    talosctl -n "$(talosctl config info -o yaml | yq -e '.endpoints[0]')" upgrade-k8s --to {{ version }}

[doc('Download Talos machine image (uses schematicId from topf.yaml)')]
[script]
download-image version:
    SCHEMATIC="$(yq -e '.schematicId' topf.yaml)"
    curl -fL --remove-on-error --retry 5 --retry-delay 5 --retry-all-errors --progress-bar \
        -o "talos-{{ version }}-${SCHEMATIC:0:8}.iso" \
        "https://factory.talos.dev/image/${SCHEMATIC}/{{ version }}/metal-amd64.iso"
    just log info "Downloaded Talos" version "{{ version }}" schematic "${SCHEMATIC}"

[doc('Compute schematic ID from schematic.yaml and write it to topf.yaml')]
[script]
schematic-id:
    schematic="$(curl -sX POST --data-binary @schematic.yaml "https://factory.talos.dev/schematics" | jq -r '.id')"
    if [[ ! "$schematic" =~ ^[0-9a-f]{64}$ ]]; then
        just log fatal "Invalid schematic ID returned from factory" value "$schematic"
    fi
    yq -i ".schematicId = \"$schematic\" | .schematicId style=\"\"" topf.yaml
    just log info "Updated schematicId in topf.yaml" id "$schematic"
