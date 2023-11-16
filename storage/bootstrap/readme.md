# Bootstrap

## Flux

### Install Flux

```sh
kubectl --context storage apply --server-side --kustomize ./storage/bootstrap/flux
```

### Apply Cluster Configuration

_These cannot be applied with `kubectl` in the regular fashion due to be encrypted with sops_

```sh
sops --decrypt ./storage/bootstrap/flux/age-key.sops.yaml | kubectl --context storage apply --server-side -f -
sops --decrypt ./storage/bootstrap/flux/github-deploy-key.sops.yaml | kubectl --context storage apply --server-side -f -
kubectl --context storage apply --server-side -k ./storage/flux/vars
```

### Kick off Flux applying this repository

```sh
kubectl --context storage apply --server-side --kustomize ./storage/flux/config
```
