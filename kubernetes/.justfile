set working-directory := '../'

[private]
default:
    @just --list kube --unsorted

[doc('Prune all unused Pods')]
prune-pods:
    @kubectl delete pods --all-namespaces --field-selector status.phase=Failed --ignore-not-found=true
    @kubectl delete pods --all-namespaces --field-selector status.phase=Pending --ignore-not-found=true
    @kubectl delete pods --all-namespaces --field-selector status.phase=Succeeded --ignore-not-found=true

[doc('Sync all Flux Kustomizations')]
sync-ks:
    @kubectl get ks --all-namespaces --no-headers | awk '{print $1, $2}' \
        | xargs -l bash -c 'kubectl --namespace $0 annotate --field-manager=flux-client-side-apply --overwrite ks $1 reconcile.fluxcd.io/requestedAt="$(date +%s)"'

[doc('Sync all Flux HelmReleases')]
sync-hr:
    @kubectl get hr --all-namespaces --no-headers | awk '{print $1, $2}' \
        | xargs -l bash -c 'kubectl --namespace $0 annotate --field-manager=flux-client-side-apply --overwrite hr $1 reconcile.fluxcd.io/requestedAt="$(date +%s)" reconcile.fluxcd.io/forceAt="$(date +%s)"'

[doc('Sync all ExternalSecrets Secrets')]
sync-es:
    @kubectl get es --all-namespaces --no-headers | awk '{print $1, $2}' \
        | xargs -l bash -c 'kubectl --namespace $0 annotate --field-manager=flux-client-side-apply --overwrite es $1 force-sync="$(date +%s)"'

[doc('Spawn a shell on a node')]
node-shell node:
    @kubectl node-shell --namespace kube-system -x {{node}}
