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
# ---
# apiVersion: networking.k8s.io/v1beta1
# kind: Ingress
# metadata:
#   annotations:
#     kubernetes.io/ingress.class: internal
#   labels:
#     app.kubernetes.io/instance: serenity-web
#     app.kubernetes.io/name: serenity-web
#   name: serenity-web
# spec:
#   rules:
#   - host: "serenity.${DOMAIN}"
#     http:
#       paths:
#       - backend:
#           serviceName: serenity-web
#           servicePort: 8080
#   tls:
#   - hosts:
#     - "serenity.${DOMAIN}"