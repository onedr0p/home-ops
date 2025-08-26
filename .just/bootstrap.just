set shell := ["bash", "-Eeu", "-o", "pipefail", "-c"]
set working-directory := '../'

[doc('Bootstrap')]
default: talos kubernetes kubeconfig wait namespaces resources crds apps

[private]
with-deps:
	@for tool in curl flux gum helm helmfile jq kubectl op talosctl; do \
		command -v $tool >/dev/null || (echo "$tool is required" && exit 1) \
	done
	@find --version | grep -q GNU || (echo "GNU find is required" && exit 1)
	@yq --version | grep -q "mikefarah" || (echo "mikefarah/yq is required" && exit 1)

[doc('Install Talos')]
talos: with-deps
	@bash ./scripts/bootstrap.sh talos

[doc('Install Kubernetes')]
kubernetes: with-deps
	@bash ./scripts/bootstrap.sh kubernetes

[doc('Fetch kubeconfig')]
kubeconfig: with-deps
	@bash ./scripts/bootstrap.sh kubeconfig

[doc('Wait for nodes to be not-ready')]
wait: with-deps
	@bash ./scripts/bootstrap.sh wait

[doc('Apply Namespaces')]
namespaces: with-deps
	@bash ./scripts/bootstrap.sh namespaces

[doc('Apply Resources')]
resources: with-deps
	@bash ./scripts/bootstrap.sh resources

[doc('Apply CRDs')]
crds: with-deps
	@bash ./scripts/bootstrap.sh crds

[doc('Apply Apps')]
apps: with-deps
	@bash ./scripts/bootstrap.sh apps
