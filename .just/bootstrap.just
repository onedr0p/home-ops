set working-directory := '../'

[private]
default: talos kubernetes kubeconfig wait namespaces resources crds apps

[doc('Bootstrap Talos')]
talos:
    #!/usr/bin/env bash -Eeuo pipefail

    # Check if Talos configuration files exist
    machineconfig_file="./talos/machineconfig.yaml.j2"
    if [[ ! -f ${machineconfig_file} ]]; then
        just log fatal "No Talos machine files found for machineconfig" "file" "${machineconfig_file}"
    fi

    # Check if Talos nodes are present
    if ! nodes=$(talosctl config info --output yaml | yq --exit-status '.nodes | join (" ")') || [[ -z "${nodes}" ]]; then
        just log fatal "No Talos nodes found"
    fi

    # Check that all nodes have a Talos configuration file
    for node in ${nodes}; do
        node_file="./talos/nodes/${node}.yaml.j2"
        if [[ ! -f "${node_file}" ]]; then
            just log fatal "No Talos machine files found for node" "node" "${node}" "file" "${node_file}"
        fi
    done

    # Apply the Talos configuration to the nodes
    for node in ${nodes}; do
        node_file="./talos/nodes/${node}.yaml.j2"
        just log info "Applying Talos node configuration" "node" "${node}"
        if ! machine_config=$(bash "./scripts/render-machine-config.sh" "${machineconfig_file}" "${node_file}" 2>/dev/null) || [[ -z "${machine_config}" ]]; then
            just log fatal "Failed to render Talos node configuration" "node" "${node}" "file" "${node_file}"
        fi
        just log debug "Talos node configuration rendered successfully" "node" "${node}"
        if ! output=$(echo "${machine_config}" | talosctl --nodes "${node}" apply-config --insecure --file /dev/stdin 2>&1); then
            if [[ "${output}" == *"certificate required"* ]]; then
                just log warn "Talos node is already configured, skipping apply of config" "node" "${node}"
                continue
            fi
            just log fatal "Failed to apply Talos node configuration" "node" "${node}" "output" "${output}"
        fi
    done

[doc('Bootstrap Kubernetes')]
kubernetes:
    #!/usr/bin/env bash -Eeuo pipefail

    # Get the Talos controller node
    if ! controller=$(talosctl config info --output yaml | yq --exit-status '.endpoints[0]') || [[ -z "${controller}" ]]; then
        just log fatal "No Talos controller found"
    fi

    # Bootstrap the Talos controller node
    until output=$(talosctl --nodes "${controller}" bootstrap 2>&1 || true) && [[ "${output}" == *"AlreadyExists"* ]]; do
        just log info "Talos bootstrap in progress, waiting 5 seconds..." "controller" "${controller}"
        sleep 5
    done

[doc('Fetch kubeconfig')]
kubeconfig:
    #!/usr/bin/env bash -Eeuo pipefail

    # Get the Talos controller node
    if ! controller=$(talosctl config info --output yaml | yq --exit-status '.endpoints[0]') || [[ -z "${controller}" ]]; then
        just log fatal "No Talos controller found"
    fi

    # Fetch the kubeconfig from the Talos controller node
    if ! talosctl kubeconfig --nodes "${controller}" --force --force-context-name main "./$(basename "${KUBECONFIG}")" &>/dev/null; then
        just log fatal "Failed to fetch kubeconfig"
    fi

[doc('Wait for Talos nodes to be not-ready')]
wait:
    #!/usr/bin/env bash -Eeuo pipefail

    # Skip waiting if all nodes are 'Ready=True'
    if kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then
        just log info "Nodes are available and ready, skipping wait for nodes"
        exit 0
    fi

    # Wait for all nodes to be 'Ready=False'
    until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do
        just log info "Nodes are not available, waiting for nodes to be available. Retrying in 5 seconds..."
        sleep 5
    done

[doc('Apply Namespaces')]
namespaces:
    #!/usr/bin/env bash -Eeuo pipefail

    # Check if the apps directory exists
    apps_dir="./kubernetes/apps"
    if [[ ! -d "${apps_dir}" ]]; then
        just log fatal "Directory does not exist" "directory" "${apps_dir}"
    fi

    # Create namespaces for each app
    find "${apps_dir}" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | while IFS= read -r namespace; do
        if kubectl get namespace "${namespace}" &>/dev/null; then
            just log info "Namespace is up-to-date" "namespace" "${namespace}"
            continue
        fi
        if ! kubectl create namespace "${namespace}" --dry-run=client --output=yaml | kubectl apply --server-side --filename - &>/dev/null; then
            just log fatal "Failed to apply namespace" "namespace" "${namespace}"
        fi
    done

[doc('Apply Resources')]
resources:
    #!/usr/bin/env bash -Eeuo pipefail

    # Check if the resources file exists
    resources_file="./bootstrap/resources.yaml"
    if [[ ! -f "${resources_file}" ]]; then
        just log fatal "File does not exist" "file" "${resources_file}"
    fi

    if op inject --in-file "${resources_file}" | kubectl diff --filename - &>/dev/null; then
        just log info "Resources are up-to-date"
        exit 0
    fi

    if ! op inject --in-file "${resources_file}" | kubectl apply --server-side --filename - &>/dev/null; then
        just log fatal "Failed to apply resources"
    fi

[doc('Apply CRDs')]
crds:
    #!/usr/bin/env bash -Eeuo pipefail

    # Check if the helmfile for CRDs exists
    helmfile_file="./bootstrap/helmfile.d/00-crds.yaml"
    if [[ ! -f "${helmfile_file}" ]]; then
        just log fatal "File does not exist" "file" "${helmfile_file}"
    fi

    # Render the CRDs from the Helmfile
    if ! crds=$(helmfile --file "${helmfile_file}" template --include-crds --no-hooks --quiet | yq ea --exit-status 'select(.kind == "CustomResourceDefinition")' -) || [[ -z "${crds}" ]]; then
        just log fatal "Failed to render CRDs from Helmfile" "file" "${helmfile_file}"
    fi

    # Check if the CRDs are already applied
    if echo "${crds}" | kubectl diff --filename - &>/dev/null; then
        just log info "CRDs are up-to-date"
        exit 0
    fi

    # Apply the CRDs to the cluster
    if ! echo "${crds}" | kubectl apply --server-side --filename - &>/dev/null; then
        just log fatal "Failed to apply crds from Helmfile" "file" "${helmfile_file}"
    fi

[doc('Apply Apps')]
apps:
    #!/usr/bin/env bash -Eeuo pipefail

    # Check if the helmfile for apps exists
    helmfile_file="./bootstrap/helmfile.d/01-apps.yaml"
    if [[ ! -f "${helmfile_file}" ]]; then
        just log fatal "File does not exist" "file" "${helmfile_file}"
    fi

    # Apply the apps to the cluster
    if ! helmfile --file "${helmfile_file}" sync --hide-notes; then
        just log fatal "Failed to apply apps from Helmfile" "file" "${helmfile_file}"
    fi
