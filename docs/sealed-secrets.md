# sealed-secrets

!!! note "Work in progress"
    This document is a work in progress.

## Installation

```
--8<--​ "./_files/sealed-secrets.yaml"
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
