#!/usr/bin/env bash
set -o errexit

# Script that uses rclone to sync the contents of a volume to a remote and then runs restci check

# rclone sync --verbose --create-empty-src-dirs minio:volsync cloudflare:volsync

# restic --repository-file /config/volsync-repo check
