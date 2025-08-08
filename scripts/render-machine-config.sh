#!/usr/bin/env bash
set -Eeuo pipefail

# This script renders and merges Talos machine configurations.
# It uses templates and patches to generate a final configuration for Talos nodes.
#
# Arguments:
# 1. Path to the Talos machine configuration file.
# 2. The node file to render the configuration for.
#
# Example Usage:
#   ./render-machine-config.sh controlplane.yaml k8s-0
#
# Output:
#   The rendered Talos configuration is printed to standard output.

source "$(dirname "${0}")/lib/common.sh"
export ROOT_DIR="$(git rev-parse --show-toplevel)"

readonly MACHINE_CONFIG="${1:?}" NODE="${2:?}"

function main() {
    # shellcheck disable=SC2034
    local -r LOG_LEVEL="info"

    check_cli minijinja-cli op

    if ! op whoami --format=json &>/dev/null; then
        log error "Failed to authenticate with 1Password CLI"
    fi

    local mc

    # shellcheck disable=SC2016
    if ! mc=$(render_template "${MACHINE_CONFIG}" "${NODE}") || [[ -z "${mc}" ]]; then
        log error "Failed to render machine config" "base=$(basename "${MACHINE_CONFIG}")"
    fi

    echo "${mc}"
}

main "$@"
