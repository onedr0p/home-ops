set positional-arguments := true
set quiet := true
set shell := ['bash', '-eu', '-o', 'pipefail', '-c']

bootstrap_dir := justfile_dir() + '/bootstrap'
kubernetes_dir := justfile_dir() + '/kubernetes'
controller := `talosctl config info -o yaml | yq -e '.endpoints[0]'`
nodes := `talosctl config info -o yaml | yq -e '.nodes | join (" ")'`

[private]
default: talos kubernetes kubeconfig wait namespaces resources crds apps

[doc('Install Talos')]
talos:
    just log debug "Runnning stage $0 ..."
    for node in {{ nodes }}; do \
        if ! output=$(just talos apply-node "$node" --insecure 2>&1); then \
            if [[ "$output" == *"certificate required"* ]]; then \
                just log info "Talos node is already configured, skipping apply of config" "stage" "$0" "node" "$node"; \
                continue; \
            fi; \
            just log fatal "Failed to apply Talos node configuration" "stage" "$0" "node" "$node" "output" "$output"; \
        fi; \
    done

[doc('Install Kubernetes')]
kubernetes:
    just log debug "Runnning stage $0 ..."
    until output=$(talosctl -n "{{ controller }}" bootstrap 2>&1 || true) && [[ "$output" == *"1AlreadyExists"* ]]; do \
        just log info "Talos bootstrap in progress, waiting 5 seconds..." "stage" "$0"; \
        sleep 5; \
    done

[doc('Fetch kubeconfig for the Talos cluster')]
kubeconfig:
    just log debug "Runnning stage $0 ..."
    if ! just talos gen-kubeconfig &>/dev/null; then \
        just log fatal "Failed to fetch kubeconfig" "stage" "$0"; \
    fi

[doc('Wait for nodes to be not-ready')]
wait:
    just log debug "Runnning stage $0 ..."
    if ! kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then \
        until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do \
            just log info "Nodes are not available, waiting for nodes to be available. Retrying in 5 seconds..." "stage" "$0"; \
            sleep 5; \
        done \
    fi

[doc('Apply Kubernetes namespaces')]
namespaces:
    just log debug "Runnning stage $0 ..."
    find "{{ kubernetes_dir }}/apps" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | while IFS= read -r namespace; do \
        if kubectl get namespace "$namespace" &>/dev/null; then \
            continue; \
        fi; \
        if ! kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply --server-side -f - &>/dev/null; then \
            just log error "Failed to apply namespace" "stage" "$0" "namespace" "$namespace"; \
        fi; \
        just log info "Namespace applied successfully" "stage" "$0" "namespace" "$namespace"; \
    done

[doc('Apply Kubernetes resources')]
resources:
    just log debug "Runnning stage $0 ..."
    if ! resources=$(op inject -i "{{ bootstrap_dir }}/resources.yaml") || [[ -z "$resources" ]]; then \
        just log fatal "Failed to render resources"; \
    fi; \
    if ! echo "$resources" | kubectl diff -f - &>/dev/null; then \
        if ! echo "$resources" | kubectl apply --server-side -f - &>/dev/null; then \
            just log fatal "Failed to apply resources" "stage" "$0"; \
        fi \
    fi

[doc('Apply Helmfile CRDs')]
crds:
    just log debug "Runnning stage $0 ..."
    if ! crds=$(helmfile --file "{{ bootstrap_dir }}/helmfile.d/00-crds.yaml" template -q) || [[ -z "$crds" ]]; then \
        just log fatal "Failed to render CRDs from Helmfile" "stage" "$0"; \
    fi; \
    if ! echo "$crds" | kubectl diff --filename - &>/dev/null; then \
        if ! echo "$crds" | kubectl apply --server-side --filename - &>/dev/null; then \
            just log fatal "Failed to apply helmfile" "stage" "$0"; \
        fi; \
    fi

[doc('Apply Helmfile Apps')]
apps:
    just log debug "Runnning stage $0 ..."
    if ! helmfile --file "{{ bootstrap_dir }}/helmfile.d/01-apps.yaml" sync --hide-notes; then \
        just log fatal "Failed to apply helmfile" "stage" "$0"; \
    fi
