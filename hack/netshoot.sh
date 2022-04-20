#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

show_help() {
cat << EOF
Usage: $(basename "$0") <options>
    -h, --help                              Display help
    -H, --host-networking                   Run netshoot in host networking
EOF
}

main() {
    local host_networking=
    parse_command_line "$@"
    entry
}

parse_command_line() {
    while :; do
        case "${1:-}" in
            -h|--help)
                show_help
                exit
                ;;
            -H|--host-networking)
                host_networking=true
                ;;
            *)
                break
                ;;
        esac
        shift
    done

    if [[ -z "$host_networking" ]]; then
        host_networking=false
    fi
}

entry() {
    if [[ "${host_networking}" == "true" ]]; then
        exec kubectl run tmp-shell --rm -i --tty --overrides='{"spec": {"hostNetwork": true}}' --image docker.io/nicolaka/netshoot:latest
    else
        exec kubectl run tmp-shell --rm -i --tty --image docker.io/nicolaka/netshoot:latest
    fi
}

main "$@"
