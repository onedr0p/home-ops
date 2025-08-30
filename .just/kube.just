set quiet := true
set shell := ['bash', '-eu', '-o', 'pipefail', '-c']

[private]
default:
    just --list kube

browse-pvc namespace pvc:
    kubectl browse-pvc --namespace {{ namespace }} --image docker.io/library/alpine:latest {{ pvc }}

node-shell node:
    kubectl node-shell -n kube-system -x {{ node }}

prune-pods:
    for phase in Failed Pending Succeeded; do \
        kubectl delete pods -A --field-selector status.phase="${phase}" --ignore-not-found=true; \
    done
