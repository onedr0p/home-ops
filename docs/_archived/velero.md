# Velero

!!! note "Work in progress"
This document is a work in progress.

## Install the CLI tool

```sh
brew install velero
```

## Create a backup

Create a backup for all apps:

```sh
velero backup create manually-backup-1 --from-schedule velero-daily-backup
```

Create a backup for a single app:

```sh
velero backup create jackett-test-abc \
    --include-namespaces testing \
    --selector "app.kubernetes.io/instance=jackett-test" \
    --wait
```

## Delete resources

Delete the `HelmRelease`:

```sh
kubectl delete hr jackett-test -n testing
```

!!! hint "Wait"
Allow the application to be redeployed and create the new resources

Delete the new resources:

```sh
kubectl delete deployment/jackett-test -n jackett
kubectl delete pvc/jackett-test-config
```

## Restore

```sh
velero restore create \
    --from-backup velero-daily-backup-20201120020022 \
    --include-namespaces testing \
    --selector "app.kubernetes.io/instance=jackett-test" \
    --wait
```
