#!/usr/bin/env bash
set -Eeuo pipefail

INFOHASH="${1:?}"

# Ref: https://github.com/buroa/qbr
# TODO: Bring binary into the container via an OCI volume mount
/config/qbr --hash "${INFOHASH}"

# Ref: https://github.com/cross-seed/cross-seed/issues/945
qbt tag delete "cross-seed" --quiet
