set shell := ['bash', '-eu', '-o', 'pipefail', '-c']

scripts_dir := justfile_dir() + '/scripts'
talos_dir := justfile_dir() + '/talos'
temp_dir := `mktemp -d`

controller := `talosctl config info -o yaml | yq -e '.endpoints[0]'`

[private]
default:
    @just --list talos

[doc('Apply Node')]
apply-node node *args:
    @just talos render-config "{{node}}" | talosctl -n "{{node}}" apply-config -f /dev/stdin {{args}}

[doc('Download Image')]
download-image version schematic:
    @gum spin -s line --title "Downloading Talos {{version}} ..." -- \
    curl -sfL --remove-on-error --retry 5 --retry-delay 5 --retry-all-errors \
        -o "{{talos_dir}}/talos-{{version}}-{{replace_regex(schematic, '^(.{8}).*', '$1')}}.iso" \
        "https://factory.talos.dev/image/{{schematic}}/{{version}}/metal-amd64.iso"
    @just log info "Downloaded Talos" version "{{version}}" schematic "{{schematic}}"

[doc('Generate Kubeconfig')]
generate-kubeconfig:
    @talosctl kubeconfig -n "{{controller}}" -f --force-context-name main {{justfile_dir()}}

[doc('Generate Schematic Id')]
generate-schematic-id:
    @curl -sX POST --data-binary "@{{talos_dir}}/schematic.yaml" \
        "https://factory.talos.dev/schematics" | jq -r '.id'

[doc('Reboot Node')]
reboot-node node:
    @talosctl -n {{node}} reboot -m powercycle

[doc('Render Config')]
render-config node:
    @minijinja-cli -D "machinetype=$(just talos machine-type {{node}})" \
        "{{talos_dir}}/machineconfig.yaml.j2" | op inject >"{{temp_dir}}/base.yaml"
    @minijinja-cli -D "machinetype=$(just talos machine-type {{node}})" \
        "{{talos_dir}}/nodes/{{node}}.yaml.j2" | op inject >"{{temp_dir}}/patch.yaml"
    @talosctl machineconfig patch "{{temp_dir}}/base.yaml" -p "@{{temp_dir}}/patch.yaml"

[doc('Reset Node')]
[confirm]
reset-node node:
    @talosctl -n "{{node}}" reset --graceful=false

[doc('Shutdown Node')]
shutdown-node node:
    @talosctl -n "{{node}}" shutdown --force

[doc('Upgrade Kubernetes')]
upgrade-k8s version:
    @talosctl -n "{{controller}}" upgrade-k8s --to {{version}}

[doc('Upgrade Node')]
upgrade-node node:
    @talosctl -n "{{node}}" upgrade -i "$(just talos machine-image)" -m powercycle --timeout=10m

[private]
machine-type node:
    @minijinja-cli "{{talos_dir}}/nodes/{{node}}.yaml.j2" | yq -e '.machine.type // ""'

[private]
machine-image:
    @minijinja-cli "{{talos_dir}}/machineconfig.yaml.j2" | yq -e '.machine.install.image // ""'
