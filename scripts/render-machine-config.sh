#!/usr/bin/env bash
set -Eeuo pipefail

# Description:
#   This script renders and merges Talos machine configurations using minijinja-cli, op and talosctl.
#   It uses templates and patches to generate a final configuration for Talos nodes.
#
# Arguments:
#   1. Path to the Talos machineconfig file.
#   2. Path to the patch file for the machineconfig.
#
# Example Usage:
#   ./render-maching-config.sh machineconfig.yaml.j2 nodes/k8s-0.yaml.j2
#
# Output:
#   The merged Talos configuration is printed to standard output.

readonly MACHINEBASE="${1:?}" MACHINEPATCH="${2:?}"

# Log messages with structured output
function log() {
    local lvl="${1:?}" msg="${2:?}"
    shift 2
    gum log --time=rfc3339 --structured --level "${lvl}" "[${FUNCNAME[1]}] ${msg}" "$@"
}

function main() {

    local base patch type result

    # Determine the machine type from the patch file
    if ! type=$(yq --exit-status 'select(documentIndex == 0) | .machine.type' "${MACHINEPATCH}") || [[ -z "${type}" ]]; then
        log fatal "Failed to determine machine type from patch file" "file" "${MACHINEPATCH}"
    fi

    # Render the base machine configurations
    if ! base=$(minijinja-cli --define "machinetype=${type}" "${MACHINEBASE}" | op inject) || [[ -z "${base}" ]]; then
        log fatal "Failed to render base machine configuration" "file" "${MACHINEBASE}"
    fi

    BASE_TMPFILE=$(mktemp)
    echo "${base}" >"${BASE_TMPFILE}"

    # Render the patch machine configurations
    if ! patch=$(minijinja-cli --define "machinetype=${type}" "${MACHINEPATCH}" | op inject) || [[ -z "${patch}" ]]; then
        log fatal "Failed to render patch machine configuration" "file" "${MACHINEPATCH}"
    fi

    PATCH_TMPFILE=$(mktemp)
    echo "${patch}" >"${PATCH_TMPFILE}"

    # Apply the patch to the base machine configuration
    if ! result=$(talosctl machineconfig patch "${BASE_TMPFILE}" --patch "@${PATCH_TMPFILE}") || [[ -z "${result}" ]]; then
        log fatal "Failed to apply patch to machine configuration" "base_file" "${BASE_TMPFILE}" "patch_file" "${PATCH_TMPFILE}"
    fi

    echo "${result}"
}

main "$@"
