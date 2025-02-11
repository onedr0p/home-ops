#!/usr/bin/env bash

set -euo pipefail

# Set default values for the `gum log` command
readonly LOG_ARGS=("--time=rfc3339" "--prefix=prepare" "--formatter=text" "--structured" "--level")

# Talos requires the nodes to be `Ready=False` before applying resources
function wait_for_nodes() {
    gum log "${LOG_ARGS[@]}" debug "Waiting for nodes to be available"

    # Skip waiting if all nodes are `Ready=True`
    if kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then
        gum log "${LOG_ARGS[@]}" info "Nodes are available and ready, skipping the wait of nodes"
        return
    fi
    # Wait for all nodes to be `Ready=False`
    until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do
        gum log "${LOG_ARGS[@]}" info "Nodes are not available, waiting for nodes to be available"
        sleep 10
    done
}

# Applications in the helmfile require Prometheus custom resources (e.g. servicemonitors)
function apply_prometheus_crds() {
    gum log "${LOG_ARGS[@]}" debug "Applying Prometheus CRDs"

    # renovate: datasource=github-releases depName=prometheus-operator/prometheus-operator
    local -r version=v0.80.0

    local -r crds=(
        "alertmanagerconfigs" "alertmanagers" "podmonitors" "probes"
        "prometheusagents" "prometheuses" "prometheusrules"
        "scrapeconfigs" "servicemonitors" "thanosrulers"
    )

    # Apply Prometheus custom resources if they do not exist
    for crd in "${crds[@]}"; do
        if kubectl get crd "${crd}.monitoring.coreos.com" &>/dev/null; then
            gum log "${LOG_ARGS[@]}" info "Prometheus CRD is up-to-date" resource "${crd}"
            continue
        fi
        if kubectl apply --server-side \
            --filename "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${version}/example/prometheus-operator-crd/monitoring.coreos.com_${crd}.yaml" &>/dev/null
        then
            gum log "${LOG_ARGS[@]}" info "Prometheus CRD applied" resource "${crd}"
        else
            gum log "${LOG_ARGS[@]}" error "Failed to apply Prometheus CRD" resource "${crd}"
            exit 1
        fi
    done
}

# The application namespaces are created before applying the resources
function apply_namespaces() {
    gum log "${LOG_ARGS[@]}" debug "Applying namespaces"

    local -r apps_dir="${KUBERNETES_DIR}/apps"

    if [[ ! -d "${apps_dir}" ]]; then
        gum log "${LOG_ARGS[@]}" error "Directory does not exist" directory "${apps_dir}"
        exit 1
    fi

    # Apply namespaces if they do not exist
    for app in "${apps_dir}"/*/; do
        namespace=$(basename "${app}")

        if kubectl get namespace "${namespace}" &>/dev/null; then
            gum log "${LOG_ARGS[@]}" info "Namespace resource is up-to-date" resource "${namespace}"
            continue
        fi

        if kubectl create namespace "${namespace}" --dry-run=client --output=yaml \
            | kubectl apply --server-side --filename - &>/dev/null;
        then
            gum log "${LOG_ARGS[@]}" info "Namespace resource applied" resource "${namespace}"
        else
            gum log "${LOG_ARGS[@]}" error "Failed to apply namespace resource" resource "${namespace}"
            exit 1
        fi
    done
}

# Secrets applied before the helmfile charts are installed
function apply_secrets() {
    gum log "${LOG_ARGS[@]}" debug "Applying secrets"

    local -r secrets_file="${KUBERNETES_DIR}/bootstrap/apps/resources/secrets.yaml.tpl"

    if [[ ! -f "${secrets_file}" ]]; then
        gum log "${LOG_ARGS[@]}" error "File does not exist" file "${secrets_file}"
        exit 1
    fi

    # Check if the bootstrap templates are up-to-date
    if op inject --in-file "${secrets_file}" | kubectl diff --filename - &>/dev/null; then
        gum log "${LOG_ARGS[@]}" info "Secret resources are up-to-date"
        return
    fi

    # Apply bootstrap templates
    if op inject --in-file "${secrets_file}" | kubectl apply --server-side --filename - &>/dev/null; then
        gum log "${LOG_ARGS[@]}" info "Secret resources applied"
    else
        gum log "${LOG_ARGS[@]}" error "Failed to apply secret resources"
        exit 1
    fi
}

# Disks in use by rook-ceph must be wiped before Rook is installed
function wipe_rook_disks() {
    gum log "${LOG_ARGS[@]}" debug "Wiping Rook disks"

    if [[ -z "${ROOK_DISK:-}" ]]; then
        gum log "${LOG_ARGS[@]}" error "Environment variable not set" env_var ROOK_DISK
        exit 1
    fi

    # Skip disk wipe if Rook is detected running in the cluster
    if kubectl --namespace rook-ceph get kustomization rook-ceph &>/dev/null; then
        gum log "${LOG_ARGS[@]}" warn "Rook is detected running in the cluster, skipping disk wipe"
        return
    fi

    # Wipe disks matching the ROOK_DISK environment variable
    for node in $(talosctl config info --output json | jq --raw-output '.nodes | .[]'); do
        disk=$(
            talosctl --nodes "${node}" get disks --output json \
                | jq --raw-output 'select(.spec.model == env.ROOK_DISK) | .metadata.id' \
                | xargs
        )

        gum log "${LOG_ARGS[@]}" info "Discovered Talos node and disk" node "${node}" disk "${disk}"

        if [[ -n "${disk}" ]]; then
            if talosctl --nodes "${node}" wipe disk "${disk}" &>/dev/null; then
                gum log "${LOG_ARGS[@]}" info "Disk wiped" node "${node}" disk "${disk}"
            else
                gum log "${LOG_ARGS[@]}" error "Failed to wipe disk" node "${node}" disk "${disk}"
                exit 1
            fi
        else
            gum log "${LOG_ARGS[@]}" warn "No disks found" node "${node}" model "${ROOK_DISK:-}"
        fi
    done
}

function main() {
    wait_for_nodes
    apply_prometheus_crds
    apply_namespaces
    apply_secrets
    wipe_rook_disks
}

main "$@"
