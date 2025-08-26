import './imports/common.just'

set shell := ["bash", "-Eeu", "-o", "pipefail", "-c"]
set working-directory := '../'

[private]
default:
	@just --list bootstrap --unsorted

[doc('Bootstrap Everything')]
everything: talos kubernetes kubeconfig wait namespaces resources crds apps

[doc('Bootstrap Talos')]
talos: with-deps
	@bash ./scripts/bootstrap.sh talos

[doc('Bootstrap Kubernetes')]
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
