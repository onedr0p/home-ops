---
apiVersion: v1
kind: Service
metadata:
  name: denon-receiver
spec:
  ports:
  - name: http
    port: 10443
  type: ExternalName
  externalName: 192.168.1.36
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: denon-receiver
  annotations:
    kubernetes.io/ingress.class: internal
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  rules:
  - host: "denon-receiver.${DOMAIN}"
    http:
      paths:
      - backend:
          serviceName: denon-receiver
          servicePort: 10443
  tls:
  - hosts:
    - "denon-receiver.${DOMAIN}"