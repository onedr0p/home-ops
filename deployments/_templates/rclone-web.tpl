---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: rclone-web
  annotations:
    kubernetes.io/ingress.class: internal
  labels:
    app.kubernetes.io/instance: rclone-web
    app.kubernetes.io/name: rclone-web
spec:
  rules:
  - host: "rclone.${DOMAIN}"
    http:
      paths:
      - backend:
          serviceName: rclone-web
          servicePort: http
  tls:
  - hosts:
    - "rclone.${DOMAIN}"