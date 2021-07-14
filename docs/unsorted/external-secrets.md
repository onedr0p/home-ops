# External Secrets

!!! note "Work in progress"
    This document is a work in progress.

## Create secret for External Secrets using AWS Secrets Manager

```sh
kubectl create secret generic aws-credentials \
    --from-literal=id="access-key-id" \
    --from-literal=key="access-secret-key" \
    --namespace kube-system
```

## Create a secret using aws-cli

```sh
aws secretsmanager create-secret \
    --name namespace/secret-name \
    --secret-string "secret-data"
```
