---
apiVersion: v1
kind: Service
metadata:
  name: rocinante
  annotations:
    external-dns.alpha.kubernetes.io/hostname: "rocinante.${DOMAIN}."
spec:
  type: ExternalName
  externalName: 192.168.1.39
---
apiVersion: v1
kind: Service
metadata:
  name: rocinante-portal
  annotations:
    external-dns.alpha.kubernetes.io/target: "portal.rocinante.${DOMAIN}."  
spec:
  type: ExternalName
  externalName: 192.168.1.39
  ports:
  - name: http
    port: 8080
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: internal
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
  labels:
    app.kubernetes.io/instance: rocinante-portal
    app.kubernetes.io/name: rocinante-portal
  name: rocinante-portal
spec:
  rules:
  - host: "portal.rocinante.${DOMAIN}"
    http:
      paths:
      - backend:
          serviceName: rocinante-portal
          servicePort: 8080
  tls:
  - hosts:
    - "portal.rocinante.${DOMAIN}"
---
apiVersion: v1
kind: Service
metadata:
  name: rocinante-nexus
  annotations:
    external-dns.alpha.kubernetes.io/target: "nexus.rocinante.${DOMAIN}."  
spec:
  type: ExternalName
  externalName: 192.168.1.39
  ports:
  - name: http
    port: 8081
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: internal
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
  labels:
    app.kubernetes.io/instance: rocinante-nexus
    app.kubernetes.io/name: rocinante-nexus
  name: rocinante-nexus
spec:
  rules:
  - host: "nexus.rocinante.${DOMAIN}"
    http:
      paths:
      - backend:
          serviceName: rocinante-nexus
          servicePort: 8081
  tls:
  - hosts:
    - "nexus.rocinante.${DOMAIN}"
---
apiVersion: v1
kind: Service
metadata:
  name: rocinante-minio
  annotations:
    external-dns.alpha.kubernetes.io/target: "minio.rocinante.${DOMAIN}."  
spec:
  type: ExternalName
  externalName: 192.168.1.39
  ports:
  - name: http
    port: 9000
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: internal
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
  labels:
    app.kubernetes.io/instance: rocinante-minio
    app.kubernetes.io/name: rocinante-minio
  name: rocinante-minio
spec:
  rules:
  - host: "minio.rocinante.${DOMAIN}"
    http:
      paths:
      - backend:
          serviceName: rocinante-minio
          servicePort: 9000
  tls:
  - hosts:
    - "minio.rocinante.${DOMAIN}"
---
apiVersion: v1
kind: Service
metadata:
  name: rocinante-registry
  annotations:
    external-dns.alpha.kubernetes.io/target: "registry.rocinante.${DOMAIN}."  
spec:
  type: ExternalName
  externalName: 192.168.1.39
  ports:
  - name: http
    port: 5000
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: internal
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
  labels:
    app.kubernetes.io/instance: rocinante-registry
    app.kubernetes.io/name: rocinante-registry
  name: rocinante-registry
spec:
  rules:
  - host: "registry.rocinante.${DOMAIN}"
    http:
      paths:
      - backend:
          serviceName: rocinante-registry
          servicePort: 5000
  tls:
  - hosts:
    - "registry.rocinante.${DOMAIN}"