---
apiVersion: v1
kind: Service
metadata:
  name: unifi
  annotations:
    external-dns.alpha.kubernetes.io/hostname: "unifi.${DOMAIN}."
spec:
  type: ExternalName
  externalName: 192.168.1.2
---
apiVersion: v1
kind: Service
metadata:
  name: unifi-controller
  annotations:
    external-dns.alpha.kubernetes.io/target: "controller.unifi.${DOMAIN}."  
spec:
  type: ExternalName
  ports:
  - name: http
    port: 8443
  type: ExternalName
  externalName: 192.168.1.2
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: internal
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
  labels:
    app.kubernetes.io/instance: unifi-controller
    app.kubernetes.io/name: unifi-controller
  name: unifi-controller
spec:
  rules:
  - host: "controller.unifi.${DOMAIN}"
    http:
      paths:
      - backend:
          serviceName: unifi-controller
          servicePort: 8443
  tls:
  - hosts:
    - "controller.unifi.${DOMAIN}"
---
apiVersion: v1
kind: Service
metadata:
  name: unifi-protect
  annotations:
    external-dns.alpha.kubernetes.io/target: "protect.unifi.${DOMAIN}."  
spec:
  type: ExternalName
  ports:
  - name: http
    port: 7443
  type: ExternalName
  externalName: 192.168.1.2
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: internal
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
  labels:
    app.kubernetes.io/instance: unifi-protect
    app.kubernetes.io/name: unifi-protect
  name: unifi-protect
spec:
  rules:
  - host: "protect.unifi.${DOMAIN}"
    http:
      paths:
      - backend:
          serviceName: unifi-protect
          servicePort: 7443
  tls:
  - hosts:
    - "protect.unifi.${DOMAIN}"    