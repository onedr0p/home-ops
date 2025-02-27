#!/usr/bin/env bash
set -Eeuo pipefail

# Log messages with different levels
function log() {
    local level="${1:-info}"
    shift

    # Define log levels with their priorities
    local -A level_priority=(
        [debug]=1
        [info]=2
        [warn]=3
        [error]=4
    )

    # Get the current log level's priority
    local current_priority=${level_priority[$level]:-2} # Default to "info" priority

    # Get the configured log level from the environment, default to "info"
    local configured_level=${LOG_LEVEL:-info}
    local configured_priority=${level_priority[$configured_level]:-2}

    # Skip log messages below the configured log level
    if (( current_priority < configured_priority )); then
        return
    fi

    # Define log colors
    local -A colors=(
        [debug]="\033[1m\033[38;5;63m"  # Blue
        [info]="\033[1m\033[38;5;87m"   # Cyan
        [warn]="\033[1m\033[38;5;192m"  # Yellow
        [error]="\033[1m\033[38;5;198m" # Red
    )

    # Fallback to "info" if the color for the given level is not defined
    local color="${colors[$level]:-${colors[info]}}"
    local msg="$1"
    shift

    # Prepare additional data
    local data=
    if [[ $# -gt 0 ]]; then
        for item in "$@"; do
            if [[ "${item}" == *=* ]]; then
                data+="\033[1m\033[38;5;236m${item%%=*}=\033[0m\"${item#*=}\" "
            else
                data+="${item} "
            fi
        done
    fi

    # Determine output stream based on log level
    local output_stream="/dev/stdout"
    if [[ "$level" == "error" ]]; then
        output_stream="/dev/stderr"
    fi

    # Print the log message
    printf "%s %b%s%b %s %b\n" "$(date --iso-8601=seconds)" \
        "${color}" "${level^^}" "\033[0m" "${msg}" "${data}" > "${output_stream}"

    # Exit if the log level is error
    if [[ "$level" == "error" ]]; then
        exit 1
    fi
}

# Check if required environment variables are set
function check_env() {
    local envs=("${@}")
    local missing=()

    for env in "${envs[@]}"; do
        if [[ -z "${!env-}" ]]; then
            missing+=("${env}")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        log error "Missing required env variables" "envs=${missing[*]}"
    fi

    log debug "Env variables are set" "envs=${envs[*]}"
}

# Check if required CLI tools are installed
function check_cli() {
    local deps=("${@}")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "${dep}" &>/dev/null; then
            missing+=("${dep}")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        log error "Missing required deps" "deps=${missing[*]}"
    fi

    log debug "Deps are installed" "deps=${deps[*]}"
}

# Wait for CRDs to be available
function wait_for_crds() {
    local crds=("${@}")

    for crd in "${crds[@]}"; do
        until kubectl get crd "${crd}" &>/dev/null; do
            log info "CRD is not available. Retrying in 10 seconds..." "crd=${crd}"
            sleep 10
        done
    done
}

# Apply a config file using kubectl
function apply_config_file() {
    local -r namespace="${1}"
    local -r file="${2}"

    if [[ ! -d "${file}" ]]; then
        log error "No config file found" "file=${file}"
    fi

    if kubectl --namespace "${namespace}" diff --file "${file}" &>/dev/null; then
        log info "Config file is up-to-date"
    else
        if kubectl apply --namespace "${namespace}" --server-side --field-manager kustomize-controller --file "${file}" &>/dev/null; then
            log info "Config file applied successfully"
        else
            log error "Failed to apply config file"
        fi
    fi
}

# Render a template using minijinja and inject secrets using op
function render_template() {
    local -r file="${1}"
    local output

    if [[ ! -f "${file}" ]]; then
        log error "File does not exist" "file=${file}"
    fi

    if ! output=$(minijinja-cli "${file}" | op inject 2>/dev/null) || [[ -z "${output}" ]]; then
        log error "Failed to render config" "file=${file}"
    fi

    echo "${output}"
}
