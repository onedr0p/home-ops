import './imports/common.just'

set shell := ["bash", "-Eeu", "-o", "pipefail", "-c"]
set working-directory := '../'

[private]
default:
	@just --list kubernetes

[doc('Spawn a shell on a node')]
node-shell node: with-deps
	@kubectl node-shell --namespace kube-system -x {{node}}

[doc('Prune all unused Pods')]
prune-pods: with-deps
	@kubectl delete pods --all-namespaces --field-selector status.phase=Failed --ignore-not-found=true
	@kubectl delete pods --all-namespaces --field-selector status.phase=Pending --ignore-not-found=true
	@kubectl delete pods --all-namespaces --field-selector status.phase=Succeeded --ignore-not-found=true

[doc('Sync all ExternalSecrets Secrets')]
sync-es: with-deps
	@kubectl get es --all-namespaces --no-headers | awk '{print $1, $2}' \
		| xargs -l bash -c 'kubectl --namespace $0 annotate --field-manager=flux-client-side-apply --overwrite es $1 force-sync="$(date +%s)"'

[doc('Sync all Flux GitRepositories')]
sync-git: with-deps
	@kubectl get gitrepository --all-namespaces --no-headers | awk '{print $1, $2}' \
		| xargs -l bash -c 'kubectl --namespace $0 annotate --field-manager=flux-client-side-apply --overwrite gitrepository $1 reconcile.fluxcd.io/requestedAt="$(date +%s)"'

[doc('Sync all Flux HelmReleases')]
sync-hr: with-deps
	@kubectl get hr --all-namespaces --no-headers | awk '{print $1, $2}' \
		| xargs -l bash -c 'kubectl --namespace $0 annotate --field-manager=flux-client-side-apply --overwrite hr $1 reconcile.fluxcd.io/requestedAt="$(date +%s)" reconcile.fluxcd.io/forceAt="$(date +%s)"'

[doc('Sync all Flux Kustomizations')]
sync-ks: with-deps
	@kubectl get ks --all-namespaces --no-headers | awk '{print $1, $2}' \
		| xargs -l bash -c 'kubectl --namespace $0 annotate --field-manager=flux-client-side-apply --overwrite ks $1 reconcile.fluxcd.io/requestedAt="$(date +%s)"'

[doc('Sync all Flux OCIRepositories')]
sync-oci: with-deps
	@kubectl get ocirepository --all-namespaces --no-headers | awk '{print $1, $2}' \
		| xargs -l bash -c 'kubectl --namespace $0 annotate --field-manager=flux-client-side-apply --overwrite ocirepository $1 reconcile.fluxcd.io/requestedAt="$(date +%s)"'
