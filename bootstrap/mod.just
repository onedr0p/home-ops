set lazy
set quiet
set script-interpreter := ['bash', '-euo', 'pipefail']
set shell := ['bash', '-euo', 'pipefail', '-c']

controller := `talosctl config info -o yaml | yq -e '.endpoints[0]'`
nodes := `talosctl config info -o yaml | yq -e '.nodes | join (" ")'`

[private]
[script]
default:
    just -l bootstrap

[doc('Bootstrap Cluster')]
[script]
cluster: talos kube (kubeconfig "node") wait-for-nodes resources crds apps kubeconfig

[private]
[script]
talos:
    just log info "Running stage..." "stage" "$(basename "$0")"
    for n in {{ nodes }}; do
        if ! op=$(just talos apply-node "$n" --insecure 2>&1); then
            if [[ "$op" == *"certificate required"* ]]; then
                just log info "Talos already configured, skipping apply of config" "stage" "$(basename "$0")" "node" "$n"
                continue
            fi
            just log fatal "Failed to apply Talos configuration" "stage" "$(basename "$0")" "node" "$n" "output" "$op"
        fi
    done

[private]
[script]
kube:
    just log info "Running stage..." "stage" "$(basename "$0")"
    until op=$(talosctl -n "{{ controller }}" bootstrap 2>&1 || true) && [[ "$op" == *"AlreadyExists"* ]]; do
        just log info "Kubernetes bootstrap in progress. Retrying in 5 seconds..." "stage" "$(basename "$0")"
        sleep 5
    done

[private]
[script]
kubeconfig lb="cilium":
    just log info "Running stage..." "stage" "$(basename "$0")"
    if ! talosctl kubeconfig -n "{{ controller }}" -f --force-context-name main {{ justfile_dir() }}; then
        just log fatal "Failed to fetch kubeconfig" "stage" "$(basename "$0")"
    fi
    if [[ "{{ lb }}" != "cilium" ]]; then
        if ! kubectl config set-cluster main --server "https://{{ controller }}:6443"; then
            just log fatal "Failed to set kubectl cluster server address" "stage" "$(basename "$0")"
        fi
    fi

[private]
[script]
wait-for-nodes:
    just log info "Running stage..." "stage" "$(basename "$0")"
    if ! kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then
        until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do
            just log info "Nodes not available, waiting for nodes to be available. Retrying in 5 seconds..." "stage" "$(basename "$0")"
            sleep 5
        done
    fi

[private]
[script]
resources:
    just log info "Running stage..." "stage" "$(basename "$0")"
    for f in {{ source_directory() }}/resources/*.yaml.j2; do
        if ! just template "$f" | kubectl apply --server-side --force-conflicts -f -; then
            just log fatal "Failed to apply resources" "stage" "$(basename "$0")" "file" "$f"
        fi
    done

[private]
[script]
crds:
    just log info "Running stage..." "stage" "$(basename "$0")"
    if ! helmfile -f "{{ source_directory() }}/helmfile.d/00-crds.yaml" template -q | yq ea -e 'select(.kind == "CustomResourceDefinition")' | kubectl apply --server-side --force-conflicts -f -; then
        just log fatal "Failed to apply crds" "stage" "$(basename "$0")"
    fi

[private]
[script]
apps:
    just log info "Running stage..." "stage" "$(basename "$0")"
    if ! helmfile -f "{{ source_directory() }}/helmfile.d/01-apps.yaml" sync --hide-notes; then
        just log fatal "Failed to sync helmfile" "stage" "$(basename "$0")"
    fi
