set working-directory := '../'

[private]
default:
    @just --list bootstrap --unsorted

[doc('Bootstrap Talos')]
talos:
    @bash ./scripts/bootstrap.sh talos

[doc('Bootstrap Kubernetes')]
kubernetes:
    @bash ./scripts/bootstrap.sh kubernetes

[doc('Fetch kubeconfig')]
kubeconfig:
    @bash ./scripts/bootstrap.sh kubeconfig

[doc('Wait for nodes to be not-ready')]
wait:
    @bash ./scripts/bootstrap.sh wait

[doc('Apply Namespaces')]
namespaces:
    @bash ./scripts/bootstrap.sh namespaces

[doc('Apply Resources')]
resources:
    @bash ./scripts/bootstrap.sh resources

[doc('Apply CRDs')]
crds:
    @bash ./scripts/bootstrap.sh crds

[doc('Apply Apps')]
apps:
    @bash ./scripts/bootstrap.sh apps
