# sealed-secrets

!!! note "Work in progress" This document is a work in progress.

## Installation

```
--8<--​ "./cluster/kube-system/sealed-secrets/helm-release.yaml"
```

## Fetch Sealed Secrets Cert

```bash
kubeseal --controller-name sealed-secrets --fetch-cert > ./secrets/pub-cert.pem
```
