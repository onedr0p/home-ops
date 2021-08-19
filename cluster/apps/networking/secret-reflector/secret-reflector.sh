#!/usr/bin/env sh

set -o nounset
set -o errexit
# space delimited secrets to copy
secrets="${SECRETS}"
# source namespace to reflect secret from
namespace_source="networking"
# space delimited namespace where to reflect the secrets to
namespace_destination="kasten-io media"
for secret in ${secrets}; do
    secret_source_content="$(kubectl get secret "${secret}" -n "${namespace_source}" -o json | jq 'del(.metadata.managedFields, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)')"
    secret_source_checksum="$(echo "${secret_source_content}" | jq 'del(.metadata.namespace)' | md5sum | awk '{ print $1 }')"
    for namespace in ${namespace_destination}; do
        if kubectl get secret "${secret}" -n "${namespace}" >/dev/null 2>&1; then
            secret_dest_content="$(kubectl get secret "${secret}" -n "${namespace}" -o json | jq 'del(.metadata.managedFields, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)')"
            secret_dest_checksum="$(echo "${secret_dest_content}" | jq 'del(.metadata.namespace)' | md5sum | awk '{ print $1 }')"
            if [ "${secret_source_checksum}" != "${secret_dest_checksum}" ]; then
                echo "${secret_source_content}" | \
                    jq -r --arg namespace "$namespace" '.metadata.namespace = $namespace' | \
                    kubectl replace -n "${namespace}" -f -
            fi
        else
            echo "${secret_source_content}" | \
                jq -r --arg namespace "$namespace" '.metadata.namespace = $namespace' | \
                kubectl apply -n "${namespace}" -f -
        fi
    done
done
