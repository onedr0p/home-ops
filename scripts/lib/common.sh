#!/usr/bin/env bash

set -euo pipefail

# Log messages with different levels
function log() {
    local level="${1:-info}"
    shift

    local -A colors=(
        [info]="\033[1m\033[38;5;87m"   # Cyan
        [warn]="\033[1m\033[38;5;192m"  # Yellow
        [error]="\033[1m\033[38;5;198m" # Red
        [debug]="\033[1m\033[38;5;63m"  # Blue
        [fatal]="\033[1m\033[38;5;92m"  # Purple
    )

    if [[ ! ${colors[$level]} ]]; then
        level="info"
    fi

    local color="${colors[$level]}"
    local msg="$1"
    shift

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

    printf "%s %b%s%b %s %b\n" "$(date --iso-8601=seconds)" \
        "${color}" "${level^^}" "\033[0m" "${msg}" "${data}"

    if [[ "$level" == "fatal" ]]; then
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
        log fatal "Missing required env variables" "envs=${missing[*]}"
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
        log fatal "Missing required deps" "deps=${missing[*]}"
    fi

    log debug "Deps are installed" "deps=${deps[*]}"
}
