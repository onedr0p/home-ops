set working-directory := '../'

flux := require('flux')
kubectl := require('kubectl')
xargs := require('xargs')

[doc('Prune all unused Pods')]
prune-pods:
    @{{kubectl}} delete pods --all-namespaces --field-selector status.phase=Failed --ignore-not-found=true
    @{{kubectl}} delete pods --all-namespaces --field-selector status.phase=Pending --ignore-not-found=true
    @{{kubectl}} delete pods --all-namespaces --field-selector status.phase=Succeeded --ignore-not-found=true

[doc('Sync all Flux Kustomizations')]
sync-ks:
    @{{flux}} get ks --all-namespaces --no-header \
        | awk '{print $1, $2}' | {{xargs}} -l -P0 bash -c '{{flux}} --namespace $0 reconcile ks $1 --with-source'

[doc('Sync all Flux HelmReleases')]
sync-hr:
    @{{flux}} get hr --all-namespaces --no-header \
        | awk '{print $1, $2}' | {{xargs}} -l -P0 bash -c '{{flux}} --namespace $0 reconcile hr $1 --force --reset'

[doc('Sync all ExternalSecrets Secrets')]
sync-es:
    @{{kubectl}} get es --all-namespaces --no-headers --output=jsonpath='{range .items[*]}{.metadata.namespace} {.metadata.name}{"\n"}{end}' \
        | {{xargs}} -l -P0 bash -c '{{kubectl}} --namespace $0 annotate externalsecret $1 force-sync="$(date +%s)" --overwrite'
