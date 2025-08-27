set shell := ["bash", "-Eeu", "-o", "pipefail", "-c"]

[private]
default:
	@just --list sync

[private]
with-deps:
	@for tool in kubectl; do \
		command -v $tool >/dev/null || (echo "$tool is required" && exit 1) \
	done

[doc('Sync all ExternalSecrets Secrets')]
es: with-deps
	@kubectl get es -A --no-headers | while read -r ns name _; do \
		kubectl -n "${ns}" annotate --field-manager flux-client-side-apply --overwrite es "${name}" force-sync="$(date +%s)"; \
	done

[doc('Sync all Flux GitRepositories')]
git: with-deps
	@kubectl get gitrepo -A --no-headers | while read -r ns name _; do \
		kubectl -n "${ns}" annotate --field-manager flux-client-side-apply --overwrite gitrepo "${name}" reconcile.fluxcd.io/requestedAt="$(date +%s)"; \
	done

[doc('Sync all Flux HelmReleases')]
hr: with-deps
	@kubectl get hr -A --no-headers | while read -r ns name _; do \
		kubectl -n "${ns}" annotate --field-manager flux-client-side-apply --overwrite hr "${name}" reconcile.fluxcd.io/requestedAt="$(date +%s)" reconcile.fluxcd.io/forceAt="$(date +%s)"; \
	done

[doc('Sync all Flux Kustomizations')]
ks: with-deps
	@kubectl get ks -A --no-headers | while read -r ns name _; do \
		kubectl -n "${ns}" annotate --field-manager flux-client-side-apply --overwrite ks "${name}" reconcile.fluxcd.io/requestedAt="$(date +%s)"; \
	done

[doc('Sync all Flux OCIRepositories')]
oci: with-deps
	@kubectl get ocirepo -A --no-headers | while read -r ns name _; do \
		kubectl -n "${ns}" annotate --field-manager flux-client-side-apply --overwrite ocirepo "${name}" reconcile.fluxcd.io/requestedAt="$(date +%s)"; \
	done
