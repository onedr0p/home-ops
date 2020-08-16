apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-test
spec:
  acme:
    email: "${CF_API_EMAIL}"
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-test
    solvers:
    - selector: {}
      dns01:
        cloudflare:
          email: "${CF_API_EMAIL}"
          apiKeySecretRef:
            name: cloudflare-api-key
            key: api-key
---
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: "${CF_API_EMAIL}"
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - selector: {}
      dns01:
        cloudflare:
          email: "${CF_API_EMAIL}"
          apiKeySecretRef:
            name: cloudflare-api-key
            key: api-key
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: acme-crt
  namespace: cert-manager
spec:
  secretName: acme-crt-secret
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - "devbu.io"
  - "*.devbu.io"
  - "*.nd.devbu.io"
  - "*.serenity.devbu.io"
  - "*.rocinante.devbu.io"
  - "*.unifi.devbu.io"