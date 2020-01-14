#!/usr/bin/env bash

export REPO_ROOT
REPO_ROOT=$(git rev-parse --show-toplevel)

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "kubectl"
need "envsubst"

if [ "$(uname)" == "Darwin" ]; then
  set -a
  . "${REPO_ROOT}/secrets/.secrets.env"
  set +a
else
  . "${REPO_ROOT}/secrets/.secrets.env"
fi

message() {
  echo -e "\n######################################################################"
  echo "# $1"
  echo "######################################################################"
}

kapply() {
  if output=$(envsubst < "$@"); then
    printf '%s' "$output" | kubectl apply -f -
  fi
}

kapply "$REPO_ROOT"/deployments/rook-ceph/dashboard/ingress.txt