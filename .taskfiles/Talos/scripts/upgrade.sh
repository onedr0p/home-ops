#!/usr/bin/env bash

CLUSTER="${1}"
NODE="${2}"
TALOS_STANZA="${3}"
ROLLOUT="${4}"

if [ -z "${NODE}" ]; then
    echo "Node name not specified"
    exit 1
fi

until kubectl --context "${CLUSTER}" wait --for=condition=Complete --timeout=10m jobs --all --all-namespaces;
do
    echo "Waiting for jobs to complete ..."
    sleep 10
done

if [ "${ROLLOUT}" != "true" ]; then
    flux --context "${CLUSTER}" suspend kustomization --all
    kubectl cnpg --context "${CLUSTER}" maintenance set --reusePVC --all-namespaces
fi

talosctl --context "${CLUSTER}" --nodes "${NODE}" upgrade \
    --image="factory.talos.dev/installer/${TALOS_STANZA}" \
    --preserve=true --wait --timeout=10m

talosctl --context "${CLUSTER}" --nodes "${NODE}" health \
    --wait-timeout=10m --server=false

until kubectl --context "${CLUSTER}" wait --timeout=10m --for=jsonpath=.status.ceph.health=HEALTH_OK cephcluster --all --all-namespaces;
do
    echo "Waiting for Ceph health to be OK ..."
    sleep 10
done

if [ "${ROLLOUT}" != "true" ]; then
    flux --context "${CLUSTER}" resume kustomization --all
fi
