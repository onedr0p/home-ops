#!/usr/bin/env bash

set -euo pipefail

# Set default values for the 'gum log' command
readonly LOG_ARGS=("log" "--time=rfc3339" "--formatter=text" "--structured" "--level")

# Verify required CLI tools are installed
function check_dependencies() {
    local deps=("gum" "jq" "kubectl" "kustomize" "op" "talosctl" "yq")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "${dep}" &>/dev/null; then
            missing+=("${dep}")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        if ! command -v gum &>/dev/null; then
            printf "%s \033[1;95m%s\033[0m Missing required dependencies \033[0;30mdependencies=\033[0m\"%s\"\n" \
                "$(date --iso-8601=seconds)" "FATAL" "${missing[*]}"
            exit 1
        fi
        gum "${LOG_ARGS[@]}" fatal "Missing required dependencies" dependencies "${missing[*]}"
    fi

    gum "${LOG_ARGS[@]}" debug "Dependencies are installed" dependencies "${deps[*]}"
}

# Talos requires the nodes to be 'Ready=False' before applying resources
function wait_for_nodes() {
    gum "${LOG_ARGS[@]}" debug "Waiting for nodes to be available"

    # Skip waiting if all nodes are 'Ready=True'
    if kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then
        gum "${LOG_ARGS[@]}" info "Nodes are available and ready, skipping wait for nodes"
        return
    fi

    # Wait for all nodes to be 'Ready=False'
    until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do
        gum "${LOG_ARGS[@]}" info "Nodes are not available, waiting for nodes to be available. Retrying in 10 seconds..."
        sleep 10
    done
}

# Applications in the helmfile require Prometheus custom resources (e.g. servicemonitors)
function apply_prometheus_crds() {
    gum "${LOG_ARGS[@]}" debug "Applying Prometheus CRDs"

    # renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator
    local -r version=v0.80.0
    local resources crds

    # Fetch resources using kustomize build
    if ! resources=$(kustomize build "https://github.com/prometheus-operator/prometheus-operator/?ref=${version}" 2>/dev/null) || [[ -z "${resources}" ]]; then
        gum "${LOG_ARGS[@]}" fatal "Failed to fetch Prometheus CRDs, check the version or the repository URL"
    fi

    # Extract only CustomResourceDefinitions
    if ! crds=$(echo "${resources}" | yq '. | select(.kind == "CustomResourceDefinition")' 2>/dev/null) || [[ -z "${crds}" ]]; then
        gum "${LOG_ARGS[@]}" fatal "No CustomResourceDefinitions found in the fetched resources"
    fi

    # Check if the CRDs are up-to-date
    if echo "${crds}" | kubectl diff --filename - &>/dev/null; then
        gum "${LOG_ARGS[@]}" info "Prometheus CRDs are up-to-date"
        return
    fi

    # Apply the CRDs
    if echo "${crds}" | kubectl apply --server-side --filename - &>/dev/null; then
        gum "${LOG_ARGS[@]}" info "Prometheus CRDs applied successfully"
    else
        gum "${LOG_ARGS[@]}" fatal "Failed to apply Prometheus CRDs"
    fi
}

# The application namespaces are created before applying the resources
function apply_namespaces() {
    gum "${LOG_ARGS[@]}" debug "Applying namespaces"

    local -r apps_dir="${KUBERNETES_DIR}/apps"

    if [[ ! -d "${apps_dir}" ]]; then
        gum "${LOG_ARGS[@]}" fatal "Directory does not exist" directory "${apps_dir}"
    fi

    for app in "${apps_dir}"/*/; do
        namespace=$(basename "${app}")

        # Check if the namespace resources are up-to-date
        if kubectl get namespace "${namespace}" &>/dev/null; then
            gum "${LOG_ARGS[@]}" info "Namespace resource is up-to-date" resource "${namespace}"
            continue
        fi

        # Apply the namespace resources
        if kubectl create namespace "${namespace}" --dry-run=client --output=yaml \
            | kubectl apply --server-side --filename - &>/dev/null;
        then
            gum "${LOG_ARGS[@]}" info "Namespace resource applied" resource "${namespace}"
        else
            gum "${LOG_ARGS[@]}" fatal "Failed to apply namespace resource" resource "${namespace}"
        fi
    done
}

# Secrets to be applied before the helmfile charts are installed
function apply_secrets() {
    gum "${LOG_ARGS[@]}" debug "Applying secrets"

    local -r secrets_file="${KUBERNETES_DIR}/bootstrap/apps/resources/secrets.yaml.tpl"
    local resources

    if [[ ! -f "${secrets_file}" ]]; then
        gum "${LOG_ARGS[@]}" fatal "File does not exist" file "${secrets_file}"
    fi

    # Inject secrets into the template
    if ! resources=$(op inject --in-file "${secrets_file}" 2>/dev/null) || [[ -z "${resources}" ]]; then
        gum "${LOG_ARGS[@]}" fatal "Failed to inject secrets" file "${secrets_file}"
    fi

    # Check if the secret resources are up-to-date
    if echo "${resources}" | kubectl diff --filename - &>/dev/null; then
        gum "${LOG_ARGS[@]}" info "Secret resources are up-to-date"
        return
    fi

    # Apply secret resources
    if echo "${resources}" | kubectl apply --server-side --filename - &>/dev/null; then
        gum "${LOG_ARGS[@]}" info "Secret resources applied"
    else
        gum "${LOG_ARGS[@]}" fatal "Failed to apply secret resources"
    fi
}

# Disks in use by rook-ceph must be wiped before Rook is installed
function wipe_rook_disks() {
    gum "${LOG_ARGS[@]}" debug "Wiping Rook disks"

    if [[ -z "${ROOK_DISK:-}" ]]; then
        gum "${LOG_ARGS[@]}" fatal "Environment variable not set" env_var ROOK_DISK
    fi

    # Skip disk wipe if Rook is detected running in the cluster
    if kubectl --namespace rook-ceph get kustomization rook-ceph &>/dev/null; then
        gum "${LOG_ARGS[@]}" warn "Rook is detected running in the cluster, skipping disk wipe"
        return
    fi

    if ! nodes=$(talosctl config info --output json 2>/dev/null | jq --raw-output '.nodes | join(" ")') || [[ -z "${nodes}" ]]; then
        gum "${LOG_ARGS[@]}" fatal "No Talos nodes found"
    fi

    gum "${LOG_ARGS[@]}" debug "Talos nodes discovered" nodes "${nodes}"

    # Wipe disks on each node that match the ROOK_DISK environment variable
    for node in ${nodes}; do
        if ! disks=$(talosctl --nodes "${node}" get disk --output json 2>/dev/null \
            | jq --raw-output --slurp '. | map(select(.spec.model == env.ROOK_DISK) | .metadata.id) | join(" ")') || [[ -z "${nodes}" ]];
        then
            gum "${LOG_ARGS[@]}" fatal "No disks found" node "${node}" model "${ROOK_DISK:-}"
        fi

        gum "${LOG_ARGS[@]}" debug "Talos node and disk discovered" node "${node}" disks "${disks}"

        # Wipe each disk on the node
        for disk in ${disks}; do
            if talosctl --nodes "${node}" wipe disk "${disk}" &>/dev/null; then
                gum "${LOG_ARGS[@]}" info "Disk wiped" node "${node}" disk "${disk}"
            else
                gum "${LOG_ARGS[@]}" fatal "Failed to wipe disk" node "${node}" disk "${disk}"
            fi
        done
    done
}

function success() {
    gum "${LOG_ARGS[@]}" info "Cluster is ready for installing helmfile apps"
}

function main() {
    check_dependencies
    wait_for_nodes
    apply_prometheus_crds
    apply_namespaces
    apply_secrets
    wipe_rook_disks
    success
}

main "$@"
