---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  labels:
    app.kubernetes.io/instance: sabnzbd
    app.kubernetes.io/name: sabnzbd
  name: sabnzbd-api
spec:
  rules:
  - host: "sabnzbd.${DOMAIN}"
    http:
      paths:
      - backend:
          serviceName: sabnzbd
          servicePort: http
        path: /api
  tls:
  - hosts:
    - "sabnzbd.${DOMAIN}"