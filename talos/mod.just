set default-list
set default-script
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

[confirm('Apply Talos config to ' + node + ' [y|N] ?')]
[doc('Apply Talos config to a node')]
apply-node node *args:
    just talos render-config "{{ node }}" | talosctl -n "{{ node }}" apply-config -f /dev/stdin {{ args }}

[doc('Download Talos machine image')]
download-image version node="":
    export SCHEMATIC="$(just talos schematic-id "{{ node }}")"
    curl -fL --remove-on-error --retry 5 --retry-delay 5 --retry-all-errors --progress-bar \
        -o "{{ source_directory() }}/talos-{{ version }}-${SCHEMATIC:0:8}.iso" \
        "https://factory.talos.dev/image/${SCHEMATIC}/{{ version }}/metal-amd64.iso"
    just log info "Downloaded Talos" version "{{ version }}" schematic "${SCHEMATIC}"

[confirm('Reboot node ' + node + ' [y|N] ?')]
[doc('Reboot a node')]
reboot-node node:
    talosctl -n {{ node }} reboot -m powercycle

[doc('Render Talos config for a node')]
render-config node:
    schematic="$(just talos schematic-id "{{ node }}")"
    role="controlplane"
    if [[ -f "{{ source_directory() }}/nodes/workers/{{ node }}.yaml.j2" ]]; then
        role="workers"
    fi
    talosctl machineconfig patch <(just template "{{ source_directory() }}/cluster.yaml.j2" -D "schematic=${schematic}") \
        -p @<(just template "{{ source_directory() }}/${role}.yaml.j2") \
        -p @<(just template "{{ source_directory() }}/nodes/${role}/{{ node }}.yaml.j2")

[confirm('Reset node ' + node + ' [y|N] ?')]
[doc('Reset a node')]
reset-node node *args:
    talosctl -n "{{ node }}" reset --system-labels-to-wipe STATE --system-labels-to-wipe EPHEMERAL --system-labels-to-wipe u-local-hostpath --graceful=false {{ args }}

[confirm('Shutdown node ' + node + ' [y|N] ?')]
[doc('Shutdown a node')]
shutdown-node node *args:
    talosctl -n "{{ node }}" shutdown --force {{ args }}

[confirm('Upgrade Kubernetes to ' + version + ' [y|N] ?')]
[doc('Upgrade Kubernetes version on the cluster')]
upgrade-k8s version:
    talosctl -n "$(talosctl config info -o yaml | yq -r -e '.endpoints[0]')" upgrade-k8s --to {{ version }}

[confirm('Upgrade node ' + node + ' [y|N] ?')]
[doc('Upgrade Talos version on a node')]
upgrade-node node *args:
    talosctl -n "{{ node }}" upgrade -i "$(just talos machine-image "{{ node }}")" -m powercycle --timeout=10m {{ args }}

[private]
schematic-file node="":
    file="{{ source_directory() }}/schematic.yaml.j2"
    if [[ -n "{{ node }}" ]]; then
        for f in "{{ source_directory() }}"/nodes/*/"{{ node }}".schematic.yaml.j2; do
            [[ -f "$f" ]] && file="$f"
        done
    fi
    echo "$file"

[private]
schematic-id node="":
    curl -sX POST --data-binary @<(just template "$(just talos schematic-file "{{ node }}")") "https://factory.talos.dev/schematics" | jq -r '.id'

[private]
machine-image node="":
    just template "{{ source_directory() }}/cluster.yaml.j2" -D "schematic=$(just talos schematic-id "{{ node }}")" | yq -r -e 'select(.kind == "UnattendedInstallConfig") | .installer.image'
