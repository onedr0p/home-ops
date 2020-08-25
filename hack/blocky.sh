#!/usr/bin/env bash

ACTION="${1}"
DURATION="${2}"

NAMESPACE="networking"
BLOCKY_PODS=$(kubectl get pods -n "${NAMESPACE}" -o=jsonpath="{range .items[*]}{.metadata.name} " -l app.kubernetes.io/name=blocky)

for pod in $BLOCKY_PODS; do
    case "${ACTION}" in
    status)
        kubectl -n "${NAMESPACE}" exec -it "${pod}" -- /app/blocky blocking status
        ;;
    enable)
        kubectl -n "${NAMESPACE}" exec -it "${pod}" -- /app/blocky blocking enable
        ;;
    disable)
        if [ -z "${DURATION}" ]; then
            kubectl -n "${NAMESPACE}" exec -it "${pod}" -- /app/blocky blocking disable
        else
            kubectl -n "${NAMESPACE}" exec -it "${pod}" -- /app/blocky blocking disable --duration "${DURATION}"
        fi
        ;;
    esac
done
