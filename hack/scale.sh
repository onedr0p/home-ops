#!/usr/bin/env sh

#
# Gracefully shutdown or start deployments, useful for system upgrades / reboots
#

kubectl scale deployment.apps/radarr --replicas 0 -n default
kubectl scale deployment.apps/sonarr --replicas 0 -n default
kubectl scale deployment.apps/lidarr --replicas 0 -n default
kubectl scale deployment.apps/bazarr --replicas 0 -n default
kubectl scale deployment.apps/plex-kube-plex --replicas 0 -n default
kubectl scale deployment.apps/ombi --replicas 0 -n default
kubectl scale deployment.apps/tautulli --replicas 0 -n default
kubectl scale deployment.apps/jackett --replicas 0 -n default
kubectl scale deployment.apps/nzbhydra2 --replicas 0 -n default
kubectl scale deployment.apps/sonarr-episode-prune --replicas 0 -n default
kubectl scale deployment.apps/nzbget --replicas 0 -n default
kubectl scale deployment.apps/qbittorrent --replicas 0 -n default
kubectl scale deployment.apps/qbittorrent-prune --replicas 0 -n default
kubectl scale deployment.apps/rclone-sync --replicas 0 -n default
kubectl scale deployment.apps/minecraft-survival-minecraft --replicas 0 -n default
kubectl scale deployment.apps/velero --replicas 0 -n velero
