# sealed-secrets

!!! note "Work in progress"
    This document is a work in progress.

## Installation

```
--8<--​ "https://raw.githubusercontent.com/onedr0p/home-cluster/main/cluster/kube-system/sealed-secrets/helm-release.yaml"
```

## Install kubeseal

```sh
brew install kubeseal
```

## Fetch Sealed Secrets Cert

```sh
kubeseal \
    --controller-name sealed-secrets \
    --fetch-cert > ./sealed-secrets-public-cert.pem
```
