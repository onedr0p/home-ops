set shell := ["bash", "-Eeu", "-o", "pipefail", "-c"]

scripts_dir := justfile_dir() + '/scripts'
talos_dir := justfile_dir() + '/talos'

[private]
default:
	@just --list talos

[private]
with-deps:
	@for tool in curl gum jq kubectl minijinja-cli op talosctl; do \
		command -v $tool >/dev/null || (echo "$tool is required" && exit 1) \
	done
	@awk --version | grep -q GNU || (echo "GNU awk is required" && exit 1)
	@yq --version | grep -q "mikefarah" || (echo "mikefarah/yq is required" && exit 1)

[doc('Apply Node')]
apply-node node mode="auto": with-deps
	@bash {{scripts_dir}}/render-machine-config.sh {{talos_dir}}/machineconfig.yaml.j2 {{talos_dir}}/nodes/{{node}}.yaml.j2 \
		| talosctl -n {{node}} apply-config -m {{mode}} --dry-run -f /dev/stdin

[doc('Download Image')]
download-image version schematic: with-deps
	@curl -fL --retry 5 --retry-delay 5 --retry-all-errors \
		-o {{talos_dir}}/talos-{{version}}-{{replace_regex(schematic, '^(.{8}).*', '$1')}}.iso \
		"https://factory.talos.dev/image/{{schematic}}/{{version}}/metal-amd64.iso"

[doc('Generate Kubeconfig')]
generate-kubeconfig: with-deps
	@talosctl kubeconfig -n "$(talosctl config info -o yaml | yq -e '.endpoints[0]')" -f --force-context-name main {{justfile_dir()}}

[doc('Generate Schematic')]
generate-schematic-id: with-deps
	@curl -sX POST --data-binary @./talos/schematic.yaml https://factory.talos.dev/schematics | jq -r '.id'

[doc('Reboot Node')]
reboot-node node mode="powercycle": with-deps
	@talosctl -n {{node}} reboot -m {{mode}}

[doc('Reset Node')]
[confirm]
reset-node node: with-deps
	@talosctl -n {{node}} reset --graceful=false

[doc('Shutdown Node')]
shutdown-node node: with-deps
	@talosctl -n {{node}} shutdown --force

[doc('Upgrade Kubernetes')]
upgrade-k8s version: with-deps
	@talosctl -n $(talosctl config info -o yaml | yq -e '.endpoints[0]') upgrade-k8s --to {{version}}

[doc('Upgrade Node')]
upgrade-node node mode="powercycle": with-deps
	@talosctl -n {{node}} upgrade \
		-i "$(yq -e 'select(documentIndex == 0) | .machine.install.image' {{talos_dir}}/machineconfig.yaml.j2)" \
		-m {{mode}} --timeout=10m
