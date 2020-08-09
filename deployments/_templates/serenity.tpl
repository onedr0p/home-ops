---
apiVersion: v1
kind: Service
metadata:
  name: serenity-dns
  annotations:
    external-dns.alpha.kubernetes.io/hostname: "serenity.${DOMAIN}."
spec:
  type: ExternalName
  externalName: 192.168.1.40