#!/usr/bin/env bash
set -Eeuo pipefail

export ROOT_DIR="$(git rev-parse --show-toplevel)"

# Log messages with structured output
function log() {
    local lvl="${1:?}" msg="${2:?}"
    shift 2
    gum log --time=rfc3339 --structured --level "${lvl}" "[${FUNCNAME[1]}] ${msg}" "$@"
}

# Apply the Talos configuration to all the nodes
function install_talos() {
    log info "Installing Talos configuration"

    local machineconfig_file="${ROOT_DIR}/talos/machineconfig.yaml.j2"

    if [[ ! -f ${machineconfig_file} ]]; then
        log fatal "No Talos machine files found for machineconfig" "file" "${machineconfig_file}"
    fi

    # Check if Talos nodes are present
    if ! nodes=$(talosctl config info --output yaml | yq --exit-status '.nodes | join (" ")') || [[ -z "${nodes}" ]]; then
        log fatal "No Talos nodes found"
    fi

    # Check that all nodes have a Talos configuration file
    for node in ${nodes}; do
        local node_file="${ROOT_DIR}/talos/nodes/${node}.yaml.j2"

        if [[ ! -f "${node_file}" ]]; then
            log fatal "No Talos machine files found for node" "node" "${node}" "file" "${node_file}"
        fi
    done

    # Apply the Talos configuration to the nodes
    for node in ${nodes}; do
        local node_file="${ROOT_DIR}/talos/nodes/${node}.yaml.j2"

        log info "Applying Talos node configuration" "node" "${node}"

        if ! machine_config=$(bash "${ROOT_DIR}/scripts/render-machine-config.sh" "${machineconfig_file}" "${node_file}" 2>/dev/null) || [[ -z "${machine_config}" ]]; then
            log fatal "Failed to render Talos node configuration" "node" "${node}" "file" "${node_file}"
        fi

        log debug "Talos node configuration rendered successfully" "node" "${node}"

        if ! output=$(echo "${machine_config}" | talosctl --nodes "${node}" apply-config --insecure --file /dev/stdin 2>&1); then
            if [[ "${output}" == *"certificate required"* ]]; then
                log warn "Talos node is already configured, skipping apply of config" "node" "${node}"
                continue
            fi
            log fatal "Failed to apply Talos node configuration" "node" "${node}" "output" "${output}"
        fi

        log info "Talos node configuration applied successfully" "node" "${node}"
    done
}

# Bootstrap Talos on a controller node
function install_kubernetes() {
    log info "Installing Kubernetes"

    if ! controller=$(talosctl config info --output yaml | yq --exit-status '.endpoints[0]') || [[ -z "${controller}" ]]; then
        log fatal "No Talos controller found"
    fi

    log debug "Talos controller discovered" "controller" "${controller}"

    until output=$(talosctl --nodes "${controller}" bootstrap 2>&1 || true) && [[ "${output}" == *"AlreadyExists"* ]]; do
        log info "Talos bootstrap in progress, waiting 5 seconds..." "controller" "${controller}"
        sleep 5
    done

    log info "Kubernetes installed successfully" "controller" "${controller}"
}

# Fetch the kubeconfig to local machine
function fetch_kubeconfig() {
    log info "Fetching kubeconfig"

    if ! controller=$(talosctl config info --output yaml | yq --exit-status '.endpoints[0]') || [[ -z "${controller}" ]]; then
        log fatal "No Talos controller found"
    fi

    if ! talosctl kubeconfig --nodes "${controller}" --force --force-context-name main "$(basename "${KUBECONFIG}")" &>/dev/null; then
        log fatal "Failed to fetch kubeconfig"
    fi

    log info "Kubeconfig fetched successfully"
}

# Talos requires the nodes to be 'Ready=False' before applying resources
function wait_for_nodes() {
    log info "Waiting for nodes to be available"

    # Skip waiting if all nodes are 'Ready=True'
    if kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then
        log info "Nodes are available and ready, skipping wait for nodes"
        return
    fi

    # Wait for all nodes to be 'Ready=False'
    until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do
        log info "Nodes are not available, waiting for nodes to be available. Retrying in 5 seconds..."
        sleep 5
    done
}

# Apply namespaces to the cluster
function apply_namespaces() {
    log info "Applying namespaces"

    local -r apps_dir="${ROOT_DIR}/kubernetes/apps"

    if [[ ! -d "${apps_dir}" ]]; then
        log error "Directory does not exist" "directory" "${apps_dir}"
    fi

    find "${apps_dir}" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | while IFS= read -r namespace; do
        if kubectl get namespace "${namespace}" &>/dev/null; then
            log info "Namespace is up-to-date" "namespace" "${namespace}"
            continue
        fi

        if ! kubectl create namespace "${namespace}" --dry-run=client --output=yaml | kubectl apply --server-side --filename - &>/dev/null; then
            log error "Failed to apply namespace" "namespace" "${namespace}"
        fi

        log info "Namespace applied successfully" "namespace" "${namespace}"
    done
}

# Apply resources before the helmfile charts are installed
function apply_resources() {
    log info "Applying resources"

    local -r resources_file="${ROOT_DIR}/bootstrap/resources.yaml"

    if [[ ! -f "${resources_file}" ]]; then
        log fatal "File does not exist" "file" "${resources_file}"
    fi

    if op inject --in-file "${resources_file}" | kubectl diff --filename - &>/dev/null; then
        log info "Resources are up-to-date"
        return
    fi

    if ! op inject --in-file "${resources_file}" | kubectl apply --server-side --filename - &>/dev/null; then
        log fatal "Failed to apply resources"
    fi

    log info "Resources applied successfully"
}

# Apply Custom Resource Definitions (CRDs)
function apply_crds() {
    log info "Applying CRDs"

    local -r helmfile_file="${ROOT_DIR}/bootstrap/helmfile.d/00-crds.yaml"

    if [[ ! -f "${helmfile_file}" ]]; then
        log fatal "File does not exist" "file" "${helmfile_file}"
    fi

    if ! crds=$(helmfile --file "${helmfile_file}" template --include-crds --no-hooks --quiet | yq ea --exit-status 'select(.kind == "CustomResourceDefinition")' -) || [[ -z "${crds}" ]]; then
        log fatal "Failed to render CRDs from Helmfile" "file" "${helmfile_file}"
    fi

    if echo "${crds}" | kubectl diff --filename - &>/dev/null; then
        log info "CRDs are up-to-date"
        return
    fi

    if ! echo "${crds}" | kubectl apply --server-side --filename - &>/dev/null; then
        log fatal "Failed to apply crds from Helmfile" "file" "${helmfile_file}"
    fi

    log info "CRDs applied successfully"
}

# Apply applications using Helmfile
function apply_apps() {
    log info "Applying apps"

    local -r helmfile_file="${ROOT_DIR}/bootstrap/helmfile.d/01-apps.yaml"

    if [[ ! -f "${helmfile_file}" ]]; then
        log fatal "File does not exist" "file" "${helmfile_file}"
    fi

    if ! helmfile --file "${helmfile_file}" sync --hide-notes; then
        log fatal "Failed to apply apps from Helmfile" "file" "${helmfile_file}"
    fi

    log info "Apps applied successfully"
}

function main() {
    install_talos
    install_kubernetes
    fetch_kubeconfig
    wait_for_nodes
    apply_namespaces
    apply_resources
    apply_crds
    apply_apps
}

main "$@"
