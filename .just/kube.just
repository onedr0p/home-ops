set shell := ["bash", "-Eeu", "-o", "pipefail", "-c"]

[private]
default:
	@just --list kube

[private]
with-deps:
	@for tool in kubectl; do \
		command -v $tool >/dev/null || (echo "$tool is required" && exit 1) \
	done
	@awk --version | grep -q GNU || (echo "GNU awk is required" && exit 1)

[doc('Spawn a shell on a node')]
[group: 'debugging']
node-shell node: with-deps
	@kubectl node-shell -n kube-system -x {{node}}

[doc('Prune all unused Pods')]
[group: 'housekeeping']
prune-pods: with-deps
	@kubectl delete pods -A --field-selector status.phase=Failed --ignore-not-found=true
	@kubectl delete pods -A --field-selector status.phase=Pending --ignore-not-found=true
	@kubectl delete pods -A --field-selector status.phase=Succeeded --ignore-not-found=true

[doc('Reconcile all ExternalSecrets Secrets')]
[group: 'reconcile']
reconcile-es: with-deps
	@kubectl get es -A --no-headers | while read -r ns name _; do \
		kubectl -n "$ns" annotate --field-manager flux-client-side-apply --overwrite es "$name" force-sync="$(date +%s)"; \
	done

[doc('Reconcile all Flux GitRepositories')]
[group: 'reconcile']
reconcile-git: with-deps
	@kubectl get gitrepo -A --no-headers | while read -r ns name _; do \
		kubectl -n "$ns" annotate --field-manager flux-client-side-apply --overwrite gitrepo "$name" reconcile.fluxcd.io/requestedAt="$(date +%s)"; \
	done

[doc('Reconcile all Flux HelmReleases')]
[group: 'reconcile']
reconcile-hr: with-deps
	@kubectl get hr -A --no-headers | while read -r ns name _; do \
		kubectl -n "$ns" annotate --field-manager flux-client-side-apply --overwrite hr "$name" reconcile.fluxcd.io/requestedAt="$(date +%s)" reconcile.fluxcd.io/forceAt="$(date +%s)"; \
	done

[doc('Reconcile all Flux Kustomizations')]
[group: 'reconcile']
reconcile-ks: with-deps
	@kubectl get ks -A --no-headers | while read -r ns name _; do \
		kubectl -n "$ns" annotate --field-manager flux-client-side-apply --overwrite ks "$name" reconcile.fluxcd.io/requestedAt="$(date +%s)"; \
	done

[doc('Reconcile all Flux OCIRepositories')]
[group: 'reconcile']
reconcile-oci: with-deps
	@kubectl get ocirepo -A --no-headers | while read -r ns name _; do \
		kubectl -n "$ns" annotate --field-manager flux-client-side-apply --overwrite ocirepo "$name" reconcile.fluxcd.io/requestedAt="$(date +%s)"; \
	done
