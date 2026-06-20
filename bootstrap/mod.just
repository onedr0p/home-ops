set no-exit-message
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

controller := `talosctl config info -o yaml | yq -r -e '.endpoints[0]'`
nodes := `talosctl config info -o yaml | yq -r -e '.nodes | join (" ")'`

[private]
default:
    just -l bootstrap

[confirm('Bootstrap cluster? [y|N]')]
[doc('Bootstrap a Talos & Kubernetes cluster end-to-end')]
cluster: nodes k8s (kubeconfig "node") base apps kubeconfig

[private]
[script]
nodes:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    for n in {{ nodes }}; do
        if ! op=$(just --yes talos apply-node "$n" --insecure 2>&1); then
            if [[ "$op" == *"certificate required"* ]]; then
                just log info "Talos already configured, skipping apply of config" "stage" "{{ recipe_name() }}" "node" "$n"
                continue
            fi
            just log fatal "Failed to apply Talos configuration" "stage" "{{ recipe_name() }}" "node" "$n" "output" "$op"
        fi
    done

[private]
[script]
k8s:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    until op=$(talosctl -n "{{ controller }}" bootstrap 2>&1 || true) && [[ "$op" == *"AlreadyExists"* ]]; do
        just log info "Kubernetes bootstrap in progress. Retrying in 5 seconds..." "stage" "{{ recipe_name() }}"
        sleep 5
    done

[private]
[script]
kubeconfig lb="cilium":
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    if ! talosctl kubeconfig -n "{{ controller }}" -f --force-context-name main {{ justfile_dir() }}; then
        just log fatal "Failed to fetch kubeconfig" "stage" "{{ recipe_name() }}"
    fi
    if [[ "{{ lb }}" != "cilium" ]]; then
        if ! kubectl config set-cluster main --server "https://{{ controller }}:6443"; then
            just log fatal "Failed to set kubectl cluster server address" "stage" "{{ recipe_name() }}"
        fi
    fi

[private]
[script]
base: ready
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    if ! kustomize build {{ source_directory() }}/kustomize/apps | just template - | kubectl apply --server-side --force-conflicts -f -; then
        just log fatal "Failed to apply base manifests" "stage" "{{ recipe_name() }}" "file" "$f"
    fi
    if ! helmfile -f "{{ source_directory() }}/helmfile/crds.yaml" template -q | yq ea -r -e 'select(.kind == "CustomResourceDefinition")' | kubectl apply --server-side --force-conflicts -f -; then
        just log fatal "Failed to apply base crds" "stage" "{{ recipe_name() }}"
    fi

[private]
[script]
apps:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    if ! helmfile -f "{{ source_directory() }}/helmfile/apps.yaml" sync --hide-notes; then
        just log fatal "Failed to sync helmfile" "stage" "{{ recipe_name() }}"
    fi

# Wait until nodes register as Ready=False. They only become Ready=True once the CNI is healthy.
[private]
[script]
ready:
    just log info "Running stage..." "stage" "{{ recipe_name() }}"
    if ! kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then
        until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do
            just log info "Nodes not available, waiting for nodes to be available. Retrying in 5 seconds..." "stage" "{{ recipe_name() }}"
            sleep 5
        done
    fi
