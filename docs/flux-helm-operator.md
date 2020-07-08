# flux-helm-operator

> *Note*: this document is a work in progress

## Install Flux

```bash
kubectl apply -f deployments/flux/namespace.yaml

helm repo add fluxcd https://charts.fluxcd.io
helm repo update
helm upgrade --install flux --values deployments/flux/flux-values.yaml --namespace flux fluxcd/flux

kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2

hack/add-repo-key.sh "ssh-rsa ..."
```

## Upgrade Flux

Apply version change to flux-values file, then commit & push

## Install Helm Operator

```bash
helm upgrade --install helm-operator --values deployments/flux/helm-operator-values.yaml --namespace flux fluxcd/helm-operator
```

## Upgrade Helm Operator

Apply changes to helm-operator-values files, then commit & push and then run the following

```bash
helm upgrade --install helm-operator --values deployments/flux/helm-operator-values.yaml --namespace flux fluxcd/helm-operator
```
