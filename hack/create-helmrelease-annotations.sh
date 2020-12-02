#!/usr/bin/env bash
shopt -s globstar

# shellcheck disable=SC2155
REPO_ROOT=$(git rev-parse --show-toplevel)
CLUSTER_ROOT="${REPO_ROOT}/cluster"
HELM_REPOSITORIES="${CLUSTER_ROOT}/flux-system/helm-chart-repositories"

# Ensure yq exist
command -v yq >/dev/null 2>&1 || {
    echo >&2 "yq is not installed. Aborting."
    exit 1
}

for helm_release in "${CLUSTER_ROOT}"/**/*.yaml; do
    # ignore flux-system namespace
    # ignore wrong apiVersion
    # ignore non HelmReleases
    if [[ "${helm_release}" =~ "flux-system"
        || $(yq r "${helm_release}" apiVersion) != "helm.toolkit.fluxcd.io/v2beta1"
        || $(yq r "${helm_release}" kind) != "HelmRelease" ]]; then
        continue
    fi

    for helm_repository in "${HELM_REPOSITORIES}"/*.yaml; do
        chart_name=$(yq r "${helm_repository}" metadata.name)
        chart_url=$(yq r "${helm_repository}" spec.url)

        # only helmreleases where helm_release is related to chart_url
        if [[ $(yq r "${helm_release}" spec.chart.spec.sourceRef.name) == "${chart_name}" ]]; then
            # delete "renovate: registryUrl=" line
            sed -i "/renovate: registryUrl=/d" "${helm_release}"
            # insert "renovate: registryUrl=" line
            sed -i "/.*chart: .*/i \ \ \ \ \ \ # renovate: registryUrl=${chart_url}" "${helm_release}"
            echo "Annotated $(basename "${helm_release%.*}") with ${chart_name} for renovatebot..."
            break
        fi
    done
done
