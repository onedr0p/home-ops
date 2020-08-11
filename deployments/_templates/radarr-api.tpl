---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
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
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
  labels:
    app.kubernetes.io/instance: radarr-uhd
    app.kubernetes.io/name: radarr-uhd
  name: radarr-uhd-api
spec:
  rules:
  - host: "radarr-uhd.${DOMAIN}"
    http:
      paths:
      - backend:
          serviceName: radarr-uhd
          servicePort: http
        path: /api
  tls:
  - hosts:
    - "radarr-uhd.${DOMAIN}"    