set shell := ["bash", "-Eeu", "-o", "pipefail", "-c"]
set working-directory := '../'

[private]
default:
	@just --list talos

[private]
with-deps:
	@for tool in curl gum kubectl minijinja-cli op talosctl; do \
		command -v $tool >/dev/null || (echo "$tool is required" && exit 1) \
	done
	@awk --version | grep -q GNU || (echo "GNU awk is required" && exit 1)
	@yq --version | grep -q "mikefarah" || (echo "mikefarah/yq is required" && exit 1)

[doc('Apply Node')]
apply-node node mode="auto": with-deps
	@bash ./scripts/render-machine-config.sh ./talos/machineconfig.yaml.j2 ./talos/nodes/{{node}}.yaml.j2 \
		| talosctl --nodes {{node}} apply-config --mode {{mode}} --dry-run --file /dev/stdin

[doc('Download Image')]
download-image version schematic: with-deps
	@curl -fL --retry 5 --retry-delay 5 --retry-all-errors \
		-o ./talos/talos-{{version}}-{{replace_regex(schematic, '^(.{8}).*', '$1')}}.iso \
		"https://factory.talos.dev/image/{{schematic}}/{{version}}/metal-amd64.iso"

[doc('Generate Kubeconfig')]
gen-kubeconfig: with-deps
	@talosctl kubeconfig --nodes $(talosctl config info --output yaml | yq --exit-status '.endpoints[0]') --force --force-context-name main ./

[doc('Generate Schematic')]
gen-schematic: with-deps
	@curl --silent -X POST --data-binary @./talos/schematic.yaml https://factory.talos.dev/schematics | jq --raw-output '.id'

[doc('Reboot Node')]
reboot-node node mode="powercycle": with-deps
	@talosctl --nodes {{node}} reboot --mode={{mode}}

[doc('Reset Node')]
[confirm('Are you sure you want to reset?')]
reset-node node: with-deps
	@talosctl --nodes {{node}} reset --graceful=false

[doc('Shutdown Node')]
[confirm('Are you sure you want to shutdown?')]
shutdown-node node: with-deps
	@talosctl --nodes {{node}} shutdown --force

[doc('Upgrade Kubernetes')]
upgrade-k8s version: with-deps
	@talosctl --nodes $(talosctl config info --output yaml | yq --exit-status '.endpoints[0]') upgrade-k8s --to {{version}}

[doc('Upgrade Node')]
upgrade-node node mode="powercycle": with-deps
	@talosctl --nodes {{node}} upgrade \
		--image="$(yq --exit-status 'select(documentIndex == 0) | .machine.install.image' ./talos/machineconfig.yaml.j2)" \
		--reboot-mode={{mode}} --timeout=10m
