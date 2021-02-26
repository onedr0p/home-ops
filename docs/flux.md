# Flux

!!! note "Work in progress" This document is a work in progress.


## Installation

_For full installation guide visit the [Flux installation guide](https://toolkit.fluxcd.io/guides/installation/)_

Install the Flux CLI tool

```sh
brew install fluxcd/tap/flux
```

Set the `GITHUB_TOKEN` environment variable to a personal access token you created in Github.

```sh
export GITHUB_TOKEN=47241b5a1f9cc45cc7388cf787fc6abacf99eb70
```

Check if you cluster is ready for Flux

```sh
flux check --pre
```

Install Flux into your cluster

```sh
flux bootstrap github \
  --version=v0.9.0 \
  --owner=onedr0p \
  --repository=home-cluster \
  --path=cluster \
  --personal \
  --network-policy=false
```

**Note**: When using k3s I found that the network-policy flag has to be set to false, or Flux will not work

## Useful commands

```sh
# force flux to sync your repository
flux reconcile source git flux-system

# force flux to sync a helm release
flux reconcile helmrelease sonarr -n default

# force flux to sync a helm repository
flux reconcile source helm ingress-nginx-charts -n flux-system
```
