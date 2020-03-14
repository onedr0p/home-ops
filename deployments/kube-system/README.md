# kube-system

## intel-gpu-plugin

The [GPU plugin](https://github.com/intel/intel-device-plugins-for-kubernetes) facilitates offloading the processing of computation intensive workloads to GPU hardware. 

This is used with Plex to handle hardware acceleration.

## metallb

[MetalLB](https://github.com/metallb/metallb) is a load-balancer implementation for bare metal Kubernetes clusters, using standard routing protocols.

## metrics-server

[Metrics server](https://github.com/kubernetes-sigs/metrics-server) is responsible for collecting resource metrics from kubelets and exposing them in Kubernetes Apiserver through Metrics API.

## nginx-ingress

[NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx) is an Ingress controller that uses ConfigMap to store the NGINX configuration.

## sealed-secrets

[Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) are a "one-way" encrypted Secret that can be created by anyone, but can only be decrypted by the controller running in the target cluster. The Sealed Secret is safe to share publicly, upload to git repositories, give to the NSA, etc. Once the Sealed Secret is safely uploaded to the target Kubernetes cluster, the sealed secrets controller will decrypt it and recover the original Secret.

## stash

[Stash](https://github.com/stashed/stash) by AppsCode is a cloud native data backup and recovery solution for Kubernetes workloads.