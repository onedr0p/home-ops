# Bootstrapping Applications

The Kubernetes @Home community has created a wonderful Github template for bootstrapping a cluster for flux this can be viewed [here](https://github.com/k8s-at-home/template-cluster-k3s).

## Bootstrapping Flux

### Create or locate cluster GPG key

```sh
export SOPS_AGE_KEY_FILE=/Users/devin/.config/sops/age/keys.txt
```

### Verify cluster is ready for Flux

```sh
flux --kubeconfig=./kubeconfig check --pre
```

### Pre-create the `flux-system` namespace

```sh
kubectl --kubeconfig=./kubeconfig create namespace flux-system --dry-run=client -o yaml | kubectl --kubeconfig=./kubeconfig apply -f -
```

### Add the Age key in-order for Flux to decrypt sops secrets

```sh
cat ~/.config/sops/age/keys.txt |
    kubectl -n flux-system create secret generic sops-age \
    --from-file=age.agekey=/dev/stdin
```

### Install Flux

!!! warning "Due to race conditions with the Flux CRDs you will have to run the below command twice. There should be no errors on this second run."

```sh
kubectl --kubeconfig=./kubeconfig apply --kustomize=./cluster/base/flux-system
```

🎉 At this point after reconciliation Flux state should be restored. 🎉
