set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']
set working-directory := '.'

[private]
default:
    just -l talos

[doc('Apply Talos config')]
apply node *args:
    topf apply --confirm --nodes-filter '^{{ node }}$' {{ args }}

[doc('Reset a Talos node to maintenance mode')]
reset node *args:
    topf reset --nodes-filter '^{{ node }}$' {{ args }}

[doc('Upgrade a Talos node')]
upgrade node *args:
    topf upgrade --nodes-filter '^{{ node }}$' {{ args }}

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

[doc('Download Talos machine image(s); optional node filter')]
[script]
download-image node="" *args:
    VERSION="v$(yq -e '.talosVersion' topf.yaml)"
    SCHEMATICS="$(topf schematic-ids {{ if node != '' { "--nodes-filter '^" + node + "$'" } else { '' } }} {{ args }})"
    [[ -z "$SCHEMATICS" ]] && just log fatal "No schematic IDs returned from topf"
    while IFS= read -r SCHEMATIC; do
        curl -fL --remove-on-error --retry 5 --retry-delay 5 --retry-all-errors --progress-bar \
            -o "talos-${VERSION}-${SCHEMATIC:0:8}.iso" \
            "https://factory.talos.dev/image/${SCHEMATIC}/${VERSION}/metal-amd64.iso"
        just log info "Downloaded Talos" version "${VERSION}" schematic "${SCHEMATIC}"
    done <<< "$SCHEMATICS"
