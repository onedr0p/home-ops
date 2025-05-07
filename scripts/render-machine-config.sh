#!/usr/bin/env bash
set -Eeuo pipefail

# This script renders and merges Talos machine configurations.
# It uses templates and patches to generate a final configuration for Talos nodes.
#
# Arguments:
# 1. Path to the base Talos machine configuration file.
# 2. Path to the patch file for the machine configuration.
#
# Example Usage:
#   ./render-machine-config.sh controlplane.yaml.j2 nodes/192.168.42.10.yaml.j2
#
# Output:
# The merged Talos configuration is printed to standard output.

source "$(dirname "${0}")/lib/common.sh"
export ROOT_DIR="$(git rev-parse --show-toplevel)"

readonly NODE_BASE="${1:?}" NODE_PATCH="${2:?}"

function main() {
    # shellcheck disable=SC2034
    local -r LOG_LEVEL="info"

    check_env KUBERNETES_VERSION TALOS_VERSION
    check_cli minijinja-cli op talosctl

    if ! op whoami --format=json &>/dev/null; then
        log error "Failed to authenticate with 1Password CLI"
    fi

    local base patch machine_config

    if ! base=$(render_template "${NODE_BASE}") || [[ -z "${base}" ]]; then
        exit 1
    fi

    if ! patch=$(render_template "${NODE_PATCH}") || [[ -z "${patch}" ]]; then
        exit 1
    fi

    BASE_TMPFILE=$(mktemp)
    echo "${base}" >"${BASE_TMPFILE}"

    PATCH_TMPFILE=$(mktemp)
    echo "${patch}" >"${PATCH_TMPFILE}"

    # shellcheck disable=SC2016
    if ! machine_config=$(echo "${base}" | talosctl machineconfig patch "${BASE_TMPFILE}" --patch "@${PATCH_TMPFILE}") || [[ -z "${machine_config}" ]]; then
        log error "Failed to merge configs" "base=$(basename "${NODE_BASE}")" "patch=$(basename "${NODE_PATCH}")"
    fi

    echo "${machine_config}"
}

main "$@"
