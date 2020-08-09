---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/use-regex: "true"
  labels:
    app.kubernetes.io/instance: radarr
    app.kubernetes.io/name: radarr
  name: radarr-api
spec:
  rules:
  - host: "radarr.${DOMAIN}"
    http:
      paths:
      - backend:
          serviceName: radarr
          servicePort: http
        path: /api
  tls:
  - hosts:
    - "radarr.${DOMAIN}"