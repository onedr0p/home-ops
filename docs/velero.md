# velero

[Velero](https://velero.io/) is a cluster backup & restore solution.  I can also leverage restic to backup persistent volumes to S3 storage buckets.

In order to backup and restore a given workload, the following steps should work.

## install cli tool

```sh
brew install velero
```

## backup

> A backup should already be created by either a scheduled, or manual backup

```bash
# create a backup for all apps
velero backup create manually-backup-1 --from-schedule velero-daily-backup
# create a backup for a single app
velero backup create jackett-test-abc --include-namespaces testing --selector "app.kubernetes.io/instance=jackett-test" --wait
```

## delete resources

```bash
# delete the helmrelease
kubectl delete hr jackett-test -n testing

# allow the application to redeployed and create the new resources

# delete the new resources
kubectl delete deployment/jackett-test -n jackett
kubectl delete pvc/jackett-test-config
```

## restore

```bash
velero restore create --from-backup velero-daily-backup-20201120020022 --include-namespaces testing --selector "app.kubernetes.io/instance=jackett-test" --wait
```

* This should not interfere with the HelmRelease or require scaling helm-operator
* You don't need to worry about adding labels to the HelmRelease or backing-up the helm secret object
