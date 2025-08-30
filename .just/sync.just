set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

[private]
default:
    just -l sync

[doc('Sync ExternalSecrets')]
es:
    kubectl get es --no-headers -A | while read -r ns name _; do \
        kubectl -n "$ns" annotate --field-manager flux-client-side-apply --overwrite es "$name" force-sync="$(date +%s)"; \
    done

[doc('Sync GitRepositories')]
git:
    kubectl get gitrepo --no-headers -A | while read -r ns name _; do \
        kubectl -n "$ns" annotate --field-manager flux-client-side-apply --overwrite gitrepo "$name" reconcile.fluxcd.io/requestedAt="$(date +%s)"; \
    done

[doc('Sync HelmReleases')]
hr:
    kubectl get hr --no-headers -A | while read -r ns name _; do \
        kubectl -n "$ns" annotate --field-manager flux-client-side-apply --overwrite hr "$name" reconcile.fluxcd.io/requestedAt="$(date +%s)" reconcile.fluxcd.io/forceAt="$(date +%s)"; \
    done

[doc('Sync Kustomizations')]
ks:
    kubectl get ks --no-headers -A | while read -r ns name _; do \
        kubectl -n "$ns" annotate --field-manager flux-client-side-apply --overwrite ks "$name" reconcile.fluxcd.io/requestedAt="$(date +%s)"; \
    done

[doc('Sync OCIRepositories')]
oci:
    kubectl get ocirepo --no-headers -A | while read -r ns name _; do \
        kubectl -n "$ns" annotate --field-manager flux-client-side-apply --overwrite ocirepo "$name" reconcile.fluxcd.io/requestedAt="$(date +%s)"; \
    done
