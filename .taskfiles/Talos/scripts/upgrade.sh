#!/usr/bin/env bash

CLUSTER="${1}"
NODE="${2}"
TALOS_STANZA="${3}"
ROLLOUT="${4:-false}"

FROM_VERSION=$(kubectl --context "${CLUSTER}" get node "${NODE}" --output jsonpath='{.metadata.labels.feature\.node\.kubernetes\.io/system-os_release\.VERSION_ID}')
TO_VERSION=${TALOS_STANZA##*:}

echo "Checking if Talos needs to be upgraded on node '${NODE}' in cluster '${CLUSTER}' ..."
if [ "${FROM_VERSION}" == "${TO_VERSION}" ]; then
    echo "Talos is already up to date on version '${FROM_VERSION}', skipping upgrade ..."
    exit 0
fi

echo "Waiting for all jobs to complete before upgrading Talos on node '${NODE}' in cluster '${CLUSTER}' ..."
until kubectl --context "${CLUSTER}" wait --timeout=5m \
    --for=condition=Complete jobs --all --all-namespaces;
do
    echo "Waiting for all jobs to complete before upgrading Talos on node '${NODE}' in cluster '${CLUSTER}' ..."
    sleep 10
done

if [ "${ROLLOUT}" != "true" ]; then
    echo "Suspending Flux Kustomizations in cluster '${CLUSTER}' ..."
    flux --context "${CLUSTER}" suspend kustomization --all
    echo "Setting CNPG maintenance mode in cluster '${CLUSTER}' ..."
    kubectl cnpg --context "${CLUSTER}" maintenance set --reusePVC --all-namespaces
fi

echo "Upgrading Talos on node '${NODE}' in cluster '${CLUSTER}' to ${TO_VERSION}..."
talosctl --context "${CLUSTER}" --nodes "${NODE}" upgrade \
    --image="factory.talos.dev/installer/${TALOS_STANZA}" \
        --wait=true --timeout=10m --preserve=true

echo "Waiting for Talos to be healthy on node '${NODE}' in cluster '${CLUSTER}' ..."
talosctl --context "${CLUSTER}" --nodes "${NODE}" health \
    --wait-timeout=10m --server=false

echo "Waiting for Ceph health to be OK on node '${NODE}' in cluster '${CLUSTER}' ..."
until kubectl --context "${CLUSTER}" wait --timeout=5m \
    --for=jsonpath=.status.ceph.health=HEALTH_OK cephcluster \
        --all --all-namespaces;
do
    echo "Waiting for Ceph health to be OK on node '${NODE}' in cluster '${CLUSTER}' ..."
    sleep 10
done

if [ "${ROLLOUT}" != "true" ]; then
    echo "Resuming Flux Kustomizations in cluster '${CLUSTER}' ..."
    flux --context "${CLUSTER}" resume kustomization --all
    echo "Unsetting CNPG maintenance mode in cluster '${CLUSTER}' ..."
    kubectl cnpg --context "${CLUSTER}" maintenance unset --reusePVC --all-namespaces
fi
