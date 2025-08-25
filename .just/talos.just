set working-directory := '../'

tmpdir := `mktemp -d`

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

[doc('Generate kubeconfig')]
gen-kubeconfig:
    @talosctl kubeconfig --nodes $(talosctl config info --output yaml | yq --exit-status '.endpoints[0]') --force --force-context-name main ./

[doc('Generate Schematic')]
gen-schematic:
    @curl --silent -X POST --data-binary @./talos/schematic.yaml https://factory.talos.dev/schematics | jq --raw-output '.id'

[doc('Download Image')]
download-image version schematic:
    @curl -o ./talos/talos-{{version}}-{{schematic}}.iso \
        "https://factory.talos.dev/image/{{schematic}}/{{version}}/metal-amd64.iso"
