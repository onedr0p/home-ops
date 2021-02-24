#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# WIP
# Pre-requisite: run `op signin <op-domain>` once, then
#

show_help() {
cat << EOF
Usage: $(basename "$0") <options>
    -h, --help               Display help
    -d, --domain             1Password domain to use (required)
    -e, --email              1Password email address to use (required)
    -v, --vault              1Password vault to use (default: kubernetes)"
    -p, --path               Path to look for Helm values templates
EOF
}

main() {
    local domain=
    local email=
    local vault=
    local path=

    parse_command_line "$@"

    check "op"
    check "jq"
    check "kubectl"
    check "kubeseal"

    # local repo_root
    # repo_root=$(git rev-parse --show-toplevel)
    # pushd "$repo_root" > /dev/null

    local session=
    login
    declare "OP_SESSION_${domain}=${session}"

    local templates=()
    readarray -t templates <<< "$(find "${path}" -type f -name "helm-values-secret.txt")"

    if [[ -n "${templates[*]}" ]]; then
        for template in "${templates[@]}"; do
            update_sealed_secrets "${template}"
        done
    fi

    # popd > /dev/null
}

parse_command_line() {
    while :; do
        case "${1:-}" in
            -h|--help)
                show_help
                exit
                ;;
            -d|--domain)
                if [[ -n "${2:-}" ]]; then
                    domain="$2"
                    shift
                else
                    echo "ERROR: '-d|--domain' cannot be empty." >&2
                    show_help
                    exit 1
                fi
                ;;
            -e|--email)
                if [[ -n "${2:-}" ]]; then
                    email="$2"
                    shift
                else
                    echo "ERROR: '-e|--email' cannot be empty." >&2
                    show_help
                    exit 1
                fi
                ;;
            -v|--vault)
                if [[ -n "${2:-}" ]]; then
                    vault="$2"
                    shift
                else
                    echo "ERROR: '-v|--vault' cannot be empty." >&2
                    show_help
                    exit 1
                fi
                ;;
            -p|--path)
                if [[ -n "${2:-}" ]]; then
                    path="$2"
                    shift
                else
                    echo "ERROR: '-p|--path' cannot be empty." >&2
                    show_help
                    exit 1
                fi
                ;;
            *)
                break
                ;;
        esac

        shift
    done

    if [[ -z "$domain" ]]; then
        echo "ERROR: '-d|--domain' is required." >&2
        show_help
        exit 1
    fi

    if [[ -z "$email" ]]; then
        echo "ERROR: '-e|--email' is required." >&2
        show_help
        exit 1
    fi

    if [[ -z "$vault" ]]; then
        vault="kubernetes"
    fi

    if [[ -z "$path" ]]; then
        echo "ERROR: '-p|--path' is required." >&2
        show_help
        exit 1
    fi
}

check() {
    command -v "${1}" >/dev/null 2>&1 || {
        echo >&2 "ERROR: ${1} is not installed or not found in \$PATH" >&2
        exit 1
    }
}

login() {
    if [ -v "${session}" ]; then
        echo "OP_SESSION_${domain} variable exists"
        if ! op get user "${email}" --session "${!session}" >/dev/null 2>&1; then
            echo "OP_SESSION_${domain} token invalid"
            session=$(op signin "${domain}" --raw)
        else
            echo "OP_SESSION_${domain} token valid"
            session="${!session}"
        fi
    else
        echo "OP_SESSION_${domain} variable does not exist"
        session=$(op signin "${domain}" --raw)
    fi
}

update_sealed_secrets() {
    local template="${1}"

    echo "template: ${template}"

    secret_path="$(dirname "${template}")"
    secret_name=$(basename "${secret_path}")
    namespace=$(basename "$(dirname "${secret_path}")")
    op_item_title="${namespace}/${secret_name}"

    echo "secret_path: ${secret_path}"
    echo "secret_name: ${secret_name}"
    echo "namespace: ${namespace}"
    echo "op_item_title: ${op_item_title}"

    # # secrets=$(op list items --vault "${vault}" --categories "Password" | op get item - --fields title,password | jq -s .)
    # # op get item --vault kubernetes "monitoring/uptimerobot-heartbeat-url"
    # # op get item --vault kubernetes --fields title,password "monitoring/uptimerobot-heartbeat-url" | jq -r
    # secrets=$(op list items --vault "${vault}" --categories "Password" | op get item - | jq -s .)
    # echo "${secrets}"
}

main "$@"
