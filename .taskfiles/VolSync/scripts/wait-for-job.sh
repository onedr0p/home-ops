#!/usr/bin/env bash

JOB=$1
NAMESPACE="${2:-default}"
CLUSTER="${3:-main}"

[[ -z "${JOB}" ]] && echo "Job name not specified" && exit 1
while true; do
    STATUS="$(kubectl --context "${CLUSTER}" -n "${NAMESPACE}" get pod -l job-name="${JOB}" -o jsonpath='{.items[*].status.phase}')"
    if [ "${STATUS}" == "Pending" ]; then
        break
    fi
    sleep 1
done
