#!/usr/bin/env bash
export REPO_ROOT=$(git rev-parse --show-toplevel)

sed 's/=.*/=""/' $REPO_ROOT/.cluster-secrets.env > $REPO_ROOT/.cluster-secrets.sample.env
cat "${REPO_ROOT}/.cluster-secrets.sample.env"