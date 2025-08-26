set shell := ["bash", "-Eeu", "-o", "pipefail", "-c"]
set working-directory := '../'

[private]
deps:
	@for tool in curl flux gum helm helmfile jq kubectl op talosctl; do \
		command -v $tool >/dev/null || (echo "$tool is required" && exit 1) \
	done
	@awk --version | grep -q GNU || (echo "GNU awk is required" && exit 1)
	@find --version | grep -q GNU || (echo "GNU find is required" && exit 1)
	@sed --version | grep -q GNU || (echo "GNU sed is required" && exit 1)
	@yq --version | grep -q "mikefarah" || (echo "mikefarah/yq is required" && exit 1)

[doc('Bootstrap')]
default: deps talos kubernetes kubeconfig wait namespaces resources crds apps

[doc('Install Talos')]
talos: deps
	@bash ./scripts/bootstrap.sh talos

[doc('Install Kubernetes')]
kubernetes: deps
	@bash ./scripts/bootstrap.sh kubernetes

[doc('Fetch kubeconfig')]
kubeconfig: deps
	@bash ./scripts/bootstrap.sh kubeconfig

[doc('Wait for nodes to be not-ready')]
wait: deps
	@bash ./scripts/bootstrap.sh wait

[doc('Apply Namespaces')]
namespaces: deps
	@bash ./scripts/bootstrap.sh namespaces

[doc('Apply Resources')]
resources: deps
	@bash ./scripts/bootstrap.sh resources

[doc('Apply CRDs')]
crds: deps
	@bash ./scripts/bootstrap.sh crds

[doc('Apply Apps')]
apps: deps
	@bash ./scripts/bootstrap.sh apps
