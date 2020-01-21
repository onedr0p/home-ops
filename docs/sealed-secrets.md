# sealed-secrets

> *Note*: this document is a work in progress

## Fetch Sealed Secrets Cert

```bash
kubeseal --controller-name sealed-secrets --fetch-cert > ./secrets/pub-cert.pem
```
