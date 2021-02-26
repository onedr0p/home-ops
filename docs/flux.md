# Flux

!!! note "Work in progress" This document is a work in progress.

> Flux is a tool for keeping Kubernetes clusters in sync with sources of configuration (like Git repositories), and automating updates to configuration when there is new code to deploy.

## Installation

Set the `GITHUB_TOKEN` environment variable to a personal access token you created in Github.

```console
$ export GITHUB_TOKEN=47241b5a1f9cc45cc7388cf787fc6abacf99eb70

$ flux check --pre

$ flux bootstrap github \
  --version=v0.9.0 \
  --owner=onedr0p \
  --repository=home-cluster \
  --path=cluster \
  --personal \
  --network-policy=false
```

**Note**: When using k3s I found that the network-policy flag has to be set to false, or Flux will not work

For full installation guide visit the [Flux installation guide](https://toolkit.fluxcd.io/guides/installation/)

## Useful commands

```command
# force flux to sync your repository
$ flux reconcile source git flux-system

# force flux to sync a helm release
$ flux reconcile helmrelease sonarr -n default

# force flux to sync a helm repository
$ flux reconcile source helm ingress-nginx-charts -n flux-system
```
