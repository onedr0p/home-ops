# sealed-secrets

!!! note "Work in progress"
    This document is a work in progress.

## Installation

```yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: sealed-secrets
  namespace: kube-system
spec:
  interval: 5m
  chart:
    spec:
      chart: sealed-secrets
      version: 1.13.2
      sourceRef:
        kind: HelmRepository
        name: sealed-secrets-charts
        namespace: flux-system
      interval: 5m
  values:
    ingress:
      enabled: false
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
