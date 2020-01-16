# flux-helm-operator

## Install Tiller

```bash
# Install Tiller
kubectl -n kube-system create sa tiller

kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller

helm init --tiller-image=jessestuart/tiller:v2.15.0 --service-account tiller

# Upgrade Tiller
helm init --upgrade --tiller-image=jessestuart/tiller:v2.15.0 --service-account tiller
```

## Install Flux

```bash
kubectl apply -f deployments/flux/namespace.yaml

helm repo add fluxcd https://charts.fluxcd.io
helm repo update
helm upgrade --install flux --values deployments/flux/flux/flux-values.yaml --namespace flux fluxcd/flux

kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2

hack/add-repo-key.sh "ssh-rsa ..."
```

## Install Helm Operator

```bash
helm upgrade --install helm-operator --values deployments/flux/helm-operator/helm-operator-values.yaml --namespace flux fluxcd/helm-operator
```

## Sealed Secrets

```bash
kubeseal --controller-name sealed-secrets --fetch-cert > ./secrets/pub-cert.pem
```
