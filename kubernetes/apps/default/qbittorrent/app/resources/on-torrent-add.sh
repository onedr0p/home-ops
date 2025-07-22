#!/usr/bin/env bash
set -Eeuo pipefail

INFOHASH="${1:?}"

# Ref: https://github.com/buroa/qbr
/config/qbr --hash "${INFOHASH}"

# Ref: https://github.com/cross-seed/cross-seed/issues/945
qbt tag delete "cross-seed"
