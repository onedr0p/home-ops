set shell := ['bash', '-eu', '-o', 'pipefail', '-c']

bootstrap_dir := justfile_dir() + '/bootstrap'
kubernetes_dir := justfile_dir() + '/kubernetes'

controller := `talosctl config info -o yaml | yq -e '.endpoints[0]'`
nodes := `talosctl config info -o yaml | yq -e '.nodes | join (" ")'`

[doc('Bootstrap Cluster')]
default: talos kubernetes kubeconfig wait namespaces resources crds apps

[doc('Install Talos')]
talos: (with-banner "Installing Talos")
    @for node in {{nodes}}; do \
        if ! output=$(just talos apply-node "${node}" --insecure 2>&1); then \
            if [[ "${output}" == *"certificate required"* ]]; then \
                just log info "Talos node is already configured, skipping apply of config" "node" "${node}"; \
                continue; \
            fi; \
            just log fatal "Failed to apply Talos node configuration" "node" "${node}" "output" "${output}"; \
        fi; \
    done

[doc('Install Kubernetes')]
kubernetes: (with-banner "Installing Kubernetes")
    @until output=$(talosctl -n "{{controller}}" bootstrap 2>&1 || true) && [[ "${output}" == *"AlreadyExists"* ]]; do \
        just log info "Talos bootstrap in progress, waiting 5 seconds..."; \
        sleep 5; \
    done

[doc('Fetch Kubeconfig')]
kubeconfig: (with-banner "Fetching kubeconfig")
    @if ! talosctl -n "{{controller}}" kubeconfig -f --force-context-name main "{{justfile_dir()}}" &>/dev/null; then \
        just log fatal "Failed to fetch kubeconfig"; \
    fi

[doc('Wait for nodes to be not-ready')]
wait: (with-banner "Waiting for nodes to be not-ready")
    @if ! kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then \
        until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do \
            just log info "Nodes are not available, waiting for nodes to be available. Retrying in 5 seconds..."; \
            sleep 5; \
        done \
    fi

[doc('Apply Namespaces')]
namespaces: (with-banner "Applying Namespaces")
    @find "{{kubernetes_dir}}/apps" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | while IFS= read -r namespace; do \
        if kubectl get namespace "${namespace}" &>/dev/null; then \
            continue; \
        fi; \
        if ! kubectl create namespace "${namespace}" --dry-run=client -o yaml | kubectl apply --server-side -f - &>/dev/null; then \
            just log error "Failed to apply namespace" "namespace" "${namespace}"; \
        fi; \
        just log info "Namespace applied successfully" "namespace" "${namespace}"; \
    done

[doc('Apply Resources')]
resources: (with-banner "Applying Resources")
    @if ! resources=$(op inject -i "{{bootstrap_dir}}/resources.yaml") || [[ -z "${resources}" ]]; then \
        just log fatal "Failed to render resources"; \
    fi; \
    if ! echo "${resources}" | kubectl diff -f - &>/dev/null; then \
        if ! echo "${resources}" | kubectl apply --server-side -f - &>/dev/null; then \
            just log fatal "Failed to apply resources"; \
        fi \
    fi

[doc('Apply CRDs')]
crds: (with-banner "Applying CRDs")
    @if ! crds=$(helmfile --file "{{bootstrap_dir}}/helmfile.d/00-crds.yaml" template -q | yq ea -e 'select(.kind == "CustomResourceDefinition")') || [[ -z "${crds}" ]]; then \
        just log fatal "Failed to render CRDs from Helmfile"; \
    fi; \
    if ! echo "${crds}" | kubectl diff --filename - &>/dev/null; then \
        if ! echo "${crds}" | kubectl apply --server-side --filename - &>/dev/null; then \
            just log fatal "Failed to apply crds from Helmfile"; \
        fi; \
    fi

[doc('Apply Apps')]
apps: (with-banner "Applying Apps")
    @if ! helmfile --file "{{bootstrap_dir}}/helmfile.d/01-apps.yaml" sync --hide-notes; then \
        just log fatal "Failed to apply apps from Helmfile"; \
    fi

[private]
with-banner msg:
    @just log info "{{msg}}"
