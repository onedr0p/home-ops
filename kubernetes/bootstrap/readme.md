# Bootstrap

## Install Prometheus CRDs

_These do not need to be fully up-to-date because the kube-prometheus-stack chart will upgrade them_

```sh
kubectl apply --server-side --kustomize ./kubernetes/bootstrap/prometheus
```

## 2. Flux

### Install Flux

```sh
kubectl apply --kustomize ./kubernetes/bootstrap/flux
```

### Apply Cluster Configuration

_These cannot be applied with `kubectl` in the regular fashion due to be encrypted with sops_

```sh
sops --decrypt cluster/bootstrap/age-key.sops.yaml | kubectl apply -f -
sops --decrypt cluster/bootstrap/github-deploy-key.sops.yaml | kubectl apply -f -
sops --decrypt cluster/flux/vars/cluster-secrets.sops.yaml | kubectl apply -f -
kubectl apply -f cluster/flux/vars/cluster-settings.yaml
```

### Kick off Flux applying this repository

```sh
kubectl apply --kustomize ./kubernetes/flux/config
```
