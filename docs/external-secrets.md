# external-secrets

> *Note*: this document is a work in progress

## Create secret for External Secrets using AWS Secrets Manager

```bash
kubectl create secret generic aws-credentials \
    --from-literal=id="access-key-id" \
    --from-literal=key="access-secret-key" \
    --namespace kube-system
```

## Create any secret using aws-cli

```bash
aws secretsmanager create-secret \
    --name namespace/secret-name \
    --secret-string "secret-data"
```
