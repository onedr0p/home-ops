set working-directory := '../'

[private]
default:
	@just --list bootstrap --unsorted

[private]
deps:
	@command -V helm helmfile jq talosctl kubectl > /dev/null
	@awk --version | grep -q GNU || (echo "GNU awk is required" && exit 1)
	@find --version | grep -q GNU || (echo "GNU find is required" && exit 1)
	@sed --version | grep -q GNU || (echo "GNU sed is required" && exit 1)
	@tar --version | grep -q GNU || (echo "GNU tar is required" && exit 1)
	@yq --version | grep -q "mikefarah" || (echo "mikefarah/yq is required" && exit 1)

[doc('Bootstrap Everything')]
everything: talos kubernetes kubeconfig wait namespaces resources crds apps

[doc('Bootstrap Talos')]
talos: deps
	@bash ./scripts/bootstrap.sh talos

[doc('Bootstrap Kubernetes')]
kubernetes:
	@bash ./scripts/bootstrap.sh kubernetes

[doc('Fetch kubeconfig')]
kubeconfig:
	@bash ./scripts/bootstrap.sh kubeconfig

[doc('Wait for nodes to be not-ready')]
wait:
	@bash ./scripts/bootstrap.sh wait

[doc('Apply Namespaces')]
namespaces:
	@bash ./scripts/bootstrap.sh namespaces

[doc('Apply Resources')]
resources:
	@bash ./scripts/bootstrap.sh resources

[doc('Apply CRDs')]
crds:
	@bash ./scripts/bootstrap.sh crds

[doc('Apply Apps')]
apps:
	@bash ./scripts/bootstrap.sh apps
