set shell := ["bash", "-Eeu", "-o", "pipefail", "-c"]

scripts_dir := justfile_dir() + '/scripts'

[doc('Bootstrap')]
default: talos kubernetes kubeconfig wait namespaces resources crds apps

[doc('Install Talos')]
talos:
	@bash {{scripts_dir}}/bootstrap.sh talos

[doc('Install Kubernetes')]
kubernetes:
	@bash {{scripts_dir}}/bootstrap.sh kubernetes

[doc('Fetch kubeconfig')]
kubeconfig:
	@bash {{scripts_dir}}/bootstrap.sh kubeconfig

[doc('Wait for nodes to be not-ready')]
wait:
	@bash {{scripts_dir}}/bootstrap.sh wait

[doc('Apply Namespaces')]
namespaces:
	@bash {{scripts_dir}}/bootstrap.sh namespaces

[doc('Apply Resources')]
resources:
	@bash {{scripts_dir}}/bootstrap.sh resources

[doc('Apply CRDs')]
crds:
	@bash {{scripts_dir}}/bootstrap.sh crds

[doc('Apply Apps')]
apps:
	@bash {{scripts_dir}}/bootstrap.sh apps
