set shell := ['bash', '-eu', '-o', 'pipefail', '-c']

[private]
default:
    @just --list kube

[doc('Spawn a shell on a node')]
node-shell node:
    @kubectl node-shell -n kube-system -x {{node}}

[doc('Prune all unused Pods')]
prune-pods:
    @for phase in Failed Pending Succeeded; do \
        kubectl delete pods -A --field-selector status.phase="${phase}" --ignore-not-found=true; \
    done
