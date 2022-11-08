# Bootstrap Flux

## Install the Flux manifests into the cluster

```sh
kubectl apply --kustomize ./cluster/bootstrap
```

## Apply the Age and GitHub Secrets

_These cannot be applied with `kubectl` in the regular fashion due to be encrypted with sops_

```sh
sops --decrypt cluster/bootstrap/age-key.sops.yaml | kubectl apply -f -
sops --decrypt cluster/bootstrap/github-deploy-key.sops.yaml | kubectl apply -f -
```

## Apply the Flux CRs to bootstrap this Git repository into the cluster

```sh
kubectl apply --kustomize ./cluster/flux/config
```
