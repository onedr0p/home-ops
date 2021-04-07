#!/usr/bin/env sh
set -o nounset
set -o errexit
# space delimited secrets to copy
SECRETS="devbu-io-tls"
# source namespace to reflect secret from
NAMESPACE_SOURCE="networking"
# space delimited namespace where to reflect the secrets to
NAMESPACE_DEST="kasten-io media"
for secret in ${SECRETS}; do
    secret_source_content="$(kubectl get secret "${secret}" -n "${NAMESPACE_SOURCE}" -o json | jq 'del(.metadata.managedFields, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)')"
    secret_source_checksum="$(echo "${secret_source_content}" | jq 'del(.metadata.namespace)' | md5sum | awk '{ print $1 }')"
    echo "source checksum: ${secret_source_checksum}"
    for namespace in ${NAMESPACE_DEST}; do
        if kubectl get secret "${secret}" -n "${namespace}" >/dev/null 2>&1; then
            secret_dest_content="$(kubectl get secret "${secret}" -n "${namespace}" -o json | jq 'del(.metadata.managedFields, .metadata.creationTimestamp, .metadata.resourceVersion, .metadata.uid)')"
            secret_dest_checksum="$(echo "${secret_dest_content}" | jq 'del(.metadata.namespace)' | md5sum | awk '{ print $1 }')"
            echo "dest checksum: ${secret_dest_checksum}"
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
