---
apiVersion: v1
kind: Service
metadata:
  name: rocinante-dns
  annotations:
    external-dns.alpha.kubernetes.io/hostname: "rocinante.${DOMAIN}."
spec:
  type: ExternalName
  externalName: 192.168.1.39