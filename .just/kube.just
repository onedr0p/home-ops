set quiet := true
set shell := ['bash', '-eu', '-o', 'pipefail', '-c']

[private]
default:
    just --list kube

[doc('Browse a PVC')]
browse-pvc namespace pvc:
    kubectl browse-pvc -n {{ namespace }} --image mirror.gcr.io/alpine:latest {{ pvc }}

[doc('Open a shell on a node')]
node-shell node:
    kubectl node-shell -n kube-system --image mirror.gcr.io/alpine:latest -x {{ node }}

[doc('Prune pods in Failed, Pending, or Succeeded state')]
prune-pods:
    for phase in Failed Pending Succeeded; do \
        kubectl delete pods -A --field-selector status.phase="$phase" --ignore-not-found=true; \
    done

[doc('View a secret')]
view-secret namespace secret:
    kubectl view-secret -n {{ namespace }} {{ secret }}
