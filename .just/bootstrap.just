import './imports/deps.just'

set shell := ["bash", "-Eeu", "-o", "pipefail", "-c"]
set working-directory := '../'

[private]
default:
	@just --list bootstrap --unsorted

[doc('Bootstrap Everything')]
everything: talos kubernetes kubeconfig wait namespaces resources crds apps

[doc('Bootstrap Talos')]
talos: deps
	@bash ./scripts/bootstrap.sh talos

[doc('Bootstrap Kubernetes')]
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
