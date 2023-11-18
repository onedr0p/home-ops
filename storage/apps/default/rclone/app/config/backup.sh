#!/usr/bin/env bash
set -o errexit

export RESTIC_PASSWORD="electrometallurgical-thaumaturgist-lucriferousness"
export RESTIC_REPOSITORY_TEMPLATE="s3:https://0a10060d9ff3ad5770343527ec45f104.r2.cloudflarestorage.com/volsync"
export AWS_ACCESS_KEY_ID="0174ad8908c6a60ab24663d200a8b208"
export AWS_SECRET_ACCESS_KEY="99d38c81b657eb5642cb2adf60042befac214fb36a61fbd0eff82c3f93d72b11"

# Sync from MinIO to Cloudflare
# rclone sync --verbose --create-empty-src-dirs --transfers 10 \
#     minio:/volsync \
#     cloudflare:/volsync

# Verify sync was successful
for app in $(rclone lsf --dirs-only cloudflare:/volsync); do
    export RESTIC_REPOSITORY="${RESTIC_REPOSITORY_TEMPLATE}/${app}"
    printf "=== Verifying %s ===\n" "${RESTIC_REPOSITORY}"
    restic check
done
