#!/usr/bin/env bash

# Wire up the env and cli validations
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${__dir}/environment.sh"

export repository_files="${CLUSTER_ROOT}/flux-system/helm-chart-repositories"

# ---
# apiVersion: helm.toolkit.fluxcd.io/v2beta1
# kind: HelmRelease
# metadata:
#   name: plex-media-server-test
#   namespace: testing
# spec:
#   interval: 5m
#   chart:
#     spec:
#       # renovatebot.helm.repository: https://k8s-at-home.com/charts/
#       chart: plex-media-server
#       version: 0.0.1
#       sourceRef:
#         kind: HelmRepository
#         name: k8s-at-home-charts
#         namespace: flux-system
#       interval: 5m

# loop thru and get all repository name and URLs
for file in "${repository_files}"/*.yaml; do
    chart_name=$(yq r "$file" metadata.name)
    chart_url=$(yq r "$file" spec.url)

    echo "$chart_name : $chart_url"

    # loop thru all namespaces and update HelmReleases
    for helm_release in "${CLUSTER_ROOT}"/**/*.yaml; do
        # ignore flux-system namespace
        # ignore wrong apiVersion
        # ignore non HelmReleases
        # ignore files that are not in $chart_name
        if [[ "${helm_release}" =~ "flux-system"
            || $(yq r "${helm_release}" apiVersion) != "helm.toolkit.fluxcd.io/v2beta1"
            || $(yq r "${helm_release}" kind) != "HelmRelease"
            || $(yq r "${helm_release}" spec.chart.spec.sourceRef.name) != "${chart_name}" ]]; then
            continue
        fi

        # remove "renovatebot.helm.repository" line
        sed -i "/renovatebot.helm.repository/d" "${helm_release}"

        # add "renovatebot.helm.repository" line
        sed -i "/.*chart: .*/i \ \ \ \ \ \ # renovatebot.helm.repository: ${chart_url}" "${helm_release}"

        # awk '!found && /.*chart:\s[A-Za-z0-9]+$/ { print "      # renovatebot.helm.repository: $chart_url"; found=1 } 1' "${helm_release}"
        echo "$helm_release"
    done
done