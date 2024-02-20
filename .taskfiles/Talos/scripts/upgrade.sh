#!/usr/bin/env bash

CLUSTER="${1}"
NODE="${2}"
TALOS_STANZA="${3}"
ROLLOUT="${4:-false}"

echo "Waiting for all jobs to complete before upgrading Talos ..."
until kubectl --context "${CLUSTER}" wait --timeout=5m \
    --for=condition=Complete jobs --all --all-namespaces;
do
    echo "Waiting for jobs to complete ..."
    sleep 10
done

if [ "${ROLLOUT}" != "true" ]; then
    echo "Suspending Flux Kustomizations ..."
    flux --context "${CLUSTER}" suspend kustomization --all
    echo "Setting CNPG maintenance mode ..."
    kubectl cnpg --context "${CLUSTER}" maintenance set --reusePVC --all-namespaces
fi

echo "Upgrading Talos on node ${NODE} in cluster ${CLUSTER} ..."
talosctl --context "${CLUSTER}" --nodes "${NODE}" upgrade \
    --image="factory.talos.dev/installer/${TALOS_STANZA}" \
        --wait=true --timeout=10m --preserve=true

echo "Waiting for Talos to be healthy ..."
talosctl --context "${CLUSTER}" --nodes "${NODE}" health \
    --wait-timeout=10m --server=false

echo "Waiting for Ceph health to be OK ..."
until kubectl --context "${CLUSTER}" wait --timeout=5m \
    --for=jsonpath=.status.ceph.health=HEALTH_OK cephcluster \
        --all --all-namespaces;
do
    echo "Waiting for Ceph health to be OK ..."
    sleep 10
done

if [ "${ROLLOUT}" != "true" ]; then
    echo "Unsetting CNPG maintenance mode ..."
    flux --context "${CLUSTER}" resume kustomization --all
fi
