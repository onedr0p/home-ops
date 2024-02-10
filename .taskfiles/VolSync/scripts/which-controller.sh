#!/usr/bin/env bash

APP=$1
NAMESPACE="${2:-default}"
CLUSTER="${3:-main}"

is_deployment() {
    kubectl --context "${CLUSTER}" -n "${NAMESPACE}" get deployment "${APP}" >/dev/null 2>&1
}

is_statefulset() {
    kubectl --context "${CLUSTER}" -n "${NAMESPACE}" get statefulset "${APP}" >/dev/null 2>&1
}

if is_deployment; then
    echo "deployment.apps/${APP}"
elif is_statefulset; then
    echo "statefulset.apps/${APP}"
else
    echo "No deployment or statefulset found for ${APP}"
    exit 1
fi
