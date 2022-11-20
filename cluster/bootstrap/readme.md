# Bootstrap Flux

## 1. Install the Flux manifests into the cluster

```sh
kubectl apply --kustomize ./cluster/bootstrap
```

## 2. Apply the Age, GitHub and cluster variable secrets

_These cannot be applied with `kubectl` in the regular fashion due to be encrypted with sops_

```sh
sops --decrypt cluster/bootstrap/age-key.sops.yaml | kubectl apply -f -
sops --decrypt cluster/bootstrap/github-deploy-key.sops.yaml | kubectl apply -f -
sops --decrypt cluster/flux/vars/cluster-secrets.sops.yaml | kubectl apply -f -
kubectl apply -f cluster/flux/vars/cluster-settings.yaml
```

## 3. Apply the Flux CRs to bootstrap this Git repository into the cluster

```sh
kubectl apply --kustomize ./cluster/flux/config
```
