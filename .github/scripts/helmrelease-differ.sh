#!/usr/bin/env bash

# shellcheck source=/dev/null
source "$(dirname "${0}")/lib/functions.sh"

set -o errexit
set -o nounset
set -o pipefail
shopt -s lastpipe

show_help() {
cat << EOF
Usage: $(basename "$0") <options>
    -h, --help                      Display help
    --source-file                   Original helm release
    --target-file                   New helm release
    --remove-common-labels          Remove common labels from manifests
EOF
}

main() {
    local source_file=
    local target_file=
    local remove_common_labels=
    parse_command_line "$@"
    check "helm"
    check "yq"
    entry
}

parse_command_line() {
    while :; do
        case "${1:-}" in
            -h|--help)
                show_help
                exit
                ;;
            --source-file)
                if [[ -n "${2:-}" ]]; then
                    source_file="$2"
                    shift
                else
                    echo "ERROR: '--source-file' cannot be empty." >&2
                    show_help
                    exit 1
                fi
                ;;
            --target-file)
                if [[ -n "${2:-}" ]]; then
                    target_file="$2"
                    shift
                else
                    echo "ERROR: '--target-file' cannot be empty." >&2
                    show_help
                    exit 1
                fi
                ;;
            --remove-common-labels)
                remove_common_labels=true
                ;;
            *)
                break
                ;;
        esac
        shift
    done

    if [[ -z "${source_file}" ]]; then
        echo "ERROR: '--source-file' is required." >&2
        show_help
        exit 1
    fi

    if  [[ $(yq eval .kind "${source_file}" 2>/dev/null) != "HelmRelease" ]]; then
        echo "ERROR: '--source-file' is not a HelmRelease"
        show_help
        exit 1
    fi

    if [[ -z "${target_file}" ]]; then
        echo "ERROR: '--target-file' is required." >&2
        show_help
        exit 1
    fi

    if  [[ $(yq eval .kind "${target_file}" 2>/dev/null) != "HelmRelease" ]]; then
        echo "ERROR: '--target-file' is not a HelmRelease"
        show_help
        exit 1
    fi

    if [[ -z "$remove_common_labels" ]]; then
        remove_common_labels=false
    fi
}

_resources() {
    local chart_name=${1}
    local chart_version=${2}
    local chart_registry_url=${3}
    local chart_values=${4}
    local resources=

    helm repo add main "${chart_registry_url}" > /dev/null 2>&1
    pushd "$(mktemp -d)" > /dev/null 2>&1
    helm pull "main/${chart_name}" --untar --version "${chart_version}"
    resources=$(echo "${chart_values}" | helm template "${chart_name}" "${chart_name}" --version "${chart_version}" -f -)
    if [[ "${remove_common_labels}" == "true" ]]; then
        labels='.metadata.labels."helm.sh/chart"'
        labels+=',.metadata.labels.chart'
        labels+=',.metadata.labels."app.kubernetes.io/version"'
        labels+=',.spec.template.metadata.labels."helm.sh/chart"'
        labels+=',.spec.template.metadata.labels.chart'
        labels+=',.spec.template.metadata.labels."app.kubernetes.io/version"'
        echo "${resources}" | yq eval "del($labels)" -
    else
        echo "${resources}"
    fi
    popd > /dev/null 2>&1
    helm repo remove main > /dev/null 2>&1
}

entry() {
    local comments=

    source_chart_name=$(chart_name "${source_file}")
    source_chart_version=$(chart_version "${source_file}")
    source_chart_registry_url=$(chart_registry_url "${source_file}")
    source_chart_values=$(chart_values "${source_file}")
    source_resources=$(_resources "${source_chart_name}" "${source_chart_version}" "${source_chart_registry_url}" "${source_chart_values}")
    echo "${source_resources}" > /tmp/source_resources

    target_chart_version=$(chart_version "${target_file}")
    target_chart_name=$(chart_name "${target_file}")
    target_chart_registry_url=$(chart_registry_url "${target_file}")
    target_chart_values=$(chart_values "${target_file}")
    target_resources=$(_resources "${target_chart_name}" "${target_chart_version}" "${target_chart_registry_url}" "${target_chart_values}")
    echo "${target_resources}" > /tmp/target_resources

    # Diff the files and always return true
    diff -u /tmp/source_resources /tmp/target_resources > /tmp/diff || true
    # Remove the filenames
    sed -i -e '1,2d' /tmp/diff

    # Store the comment in an array
    comments=()

    # shellcheck disable=SC2016
    comments+=( "$(printf 'Path: `%s`' "${target_file}")" )
    if [[ "${source_chart_name}" != "${target_chart_name}" ]]; then
        # shellcheck disable=SC2016
        comments+=( "$(printf 'Chart: `%s` -> `%s`' "${source_chart_name}" "${target_chart_name}")" )
    fi
    if [[ "${source_chart_version}" != "${target_chart_version}" ]]; then
        # shellcheck disable=SC2016
        comments+=( "$(printf 'Version: `%s` -> `%s`' "${source_chart_version}" "${target_chart_version}")" )
    fi
    if [[ "${source_chart_registry_url}" != "${target_chart_registry_url}" ]]; then
        # shellcheck disable=SC2016
        comments+=( "$(printf 'Registry URL: `%s` -> `%s`' "${source_chart_registry_url}" "${target_chart_registry_url}")" )
    fi
    comments+=( "$(printf '\n\n')" )
    if [[ -f /tmp/diff && -s /tmp/diff ]]; then
        # shellcheck disable=SC2016
        comments+=( "$(printf '```diff\n%s\n```' "$(cat /tmp/diff)")" )
    else
        # shellcheck disable=SC2016
        comments+=( "$(printf '```\nNo changes in detected in resources\n```')" )
    fi

    # Join the array with a new line and print it
    printf "%s\n" "${comments[@]}"
}

main "$@"
