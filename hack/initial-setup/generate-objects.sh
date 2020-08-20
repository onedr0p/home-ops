#!/usr/bin/env bash

# Wire up the env and validations
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${__dir}/../environment.sh"

message() {
	echo -e "\n######################################################################"
	echo "# $1"
	echo "######################################################################"
}

kapply() {
	if output=$(envsubst <"$@"); then
		printf '%s' "$output" | kubectl apply -f -
	fi
}

CERT_MANAGER_READY=1
while [ $CERT_MANAGER_READY != 0 ]; do
	message "waiting for cert-manager to be fully ready..."
	kubectl -n cert-manager wait --for condition=Available deployment/cert-manager >/dev/null 2>&1
	CERT_MANAGER_READY="$?"
	sleep 5
done
kapply "$REPO_ROOT"/deployments/cert-manager/cloudflare/cert-manager-letsencrypt.txt
