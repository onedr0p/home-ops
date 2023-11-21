#!/usr/bin/env bash
set -o errexit

# Sync from MinIO to Cloudflare
rclone sync --verbose --create-empty-src-dirs --transfers 10 \
    minio:/volsync \
    cloudflare:/volsync

# Verify sync was successful
for app in $(rclone lsf --dirs-only cloudflare:/volsync); do
    export RESTIC_REPOSITORY="${RESTIC_REPOSITORY_TEMPLATE}/${app}"
    printf "=== Verifying %s ===\n" "${RESTIC_REPOSITORY}"
    restic check
done
