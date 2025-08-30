set quiet := true
set shell := ['bash', '-eu', '-o', 'pipefail', '-c']

[private]
default:
    just --list kube

browse-pvc namespace name:
    kubectl browse-pvc --namespace {{ namespace }} --image mirror.gcr.io/alpine:latest {{ name }}

node-shell node:
    kubectl node-shell --namespace kube-system --image mirror.gcr.io/alpine:latest -x {{ node }}

prune-pods:
    for phase in Failed Pending Succeeded; do \
        kubectl delete pods -A --field-selector status.phase="${phase}" --ignore-not-found=true; \
    done

view-secret namespace name:
    kubectl view-secret --namespace {{ namespace }} {{ name }}
