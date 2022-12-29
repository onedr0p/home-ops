#!/usr/bin/env bash
shopt -s globstar

if [[ "$(uname)" == "Darwin" ]]; then
    command -v gsed >/dev/null 2>&1 || {
        echo >&2 "gsed is not installed. Aborting." && exit 1
    }
    export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
fi

toggle() {
    file=$1
    if ! grep -q '^#.*replicationsource' "${file}"; then
        sed -i '/replicationsource/ s/^#*/#/g' "${file}"
    else
        sed -i '/replicationsource/ s/^#//g' "${file}"
    fi
}

for file in ./kubernetes/**/backups/kustomization.yaml; do
    toggle "${file}"
done
