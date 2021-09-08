# Kasten Data Restore

Recovering from a K10 backup involves the following sequence of actions

## Create k10-dr-secret Kubernetes Secret

!!! info "The `<passphrase>` was set during the first installation of k10"

```sh
kubectl create secret generic k10-dr-secret \
    --namespace kasten-io \
    --from-literal key=<passphrase>
```

## Install a fresh K10 instance

!!! info "Ensure that Flux has correctly deployed K10 to it's namespace `kasten-io`"

```sh
flux get hr -n kasten-io
```

## Verify the nfs storage profile was created

```sh
kubectl get profiles -n kasten-io
```

## Restoring the K10 backup

Install the helm chart that creates the K10 restore job and wait for completion of the `k10-restore` job

!!! info "The `<source-cluster-id>` was set during the first installation of k10"

```sh
helm install k10-restore kasten/k10restore -n kasten-io \
    --set sourceClusterID=<source-cluster-id> \
    --set profile.name=nfs
```

## Application recovery

Upon completion of the DR Restore job, go to the Applications card, select `Removed` under the `Filter by status` drop-down menu.

Click restore under the application and select a restore point to recover from.
