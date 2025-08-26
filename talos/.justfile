set working-directory := '../'

[private]
default:
    @just --list talos

[doc('Apply Node')]
apply-node node mode="auto":
    @bash ./scripts/render-machine-config.sh ./talos/machineconfig.yaml.j2 ./talos/nodes/{{node}}.yaml.j2 \
        | talosctl --nodes {{node}} apply-config --mode {{mode}} --dry-run --file /dev/stdin

[doc('Upgrade Node')]
upgrade-node node mode="powercycle":
    @talosctl --nodes {{node}} upgrade \
        --image="$(yq --exit-status 'select(documentIndex == 0) | .machine.install.image' ./talos/machineconfig.yaml.j2)" \
        --reboot-mode={{mode}} --timeout=10m

[doc('Upgrade Kubernetes')]
upgrade-k8s version:
    @talosctl --nodes $(talosctl config info --output yaml | yq --exit-status '.endpoints[0]') upgrade-k8s --to {{version}}

[doc('Reboot Node')]
reboot-node node mode="powercycle":
    @talosctl --nodes {{node}} reboot --mode={{mode}}

[doc('Shutdown Node')]
[confirm('Are you sure you want to shutdown?')]
shutdown-node node:
    @talosctl --nodes {{node}} shutdown --force

[doc('Reset Node')]
[confirm('Are you sure you want to reset?')]
reset-node node:
    @talosctl --nodes {{node}} reset --graceful=false

[doc('Generate kubeconfig')]
gen-kubeconfig:
    @talosctl kubeconfig --nodes $(talosctl config info --output yaml | yq --exit-status '.endpoints[0]') --force --force-context-name main ./

[doc('Generate Schematic')]
gen-schematic:
    @curl --silent -X POST --data-binary @./talos/schematic.yaml https://factory.talos.dev/schematics | jq --raw-output '.id'

[doc('Download Image')]
download-image version schematic:
    @curl -fL --retry 5 --retry-delay 5 --retry-all-errors \
        -o ./talos/talos-{{version}}-{{replace_regex(schematic, '^(.{8}).*', '$1')}}.iso \
        "https://factory.talos.dev/image/{{schematic}}/{{version}}/metal-amd64.iso"
