with-deps:
	@for tool in curl flux gum helm helmfile jq kubectl op talosctl; do \
		command -v $tool >/dev/null || (echo "$tool is required" && exit 1) \
	done
	@awk --version | grep -q GNU || (echo "GNU awk is required" && exit 1)
	@find --version | grep -q GNU || (echo "GNU find is required" && exit 1)
	@sed --version | grep -q GNU || (echo "GNU sed is required" && exit 1)
	@yq --version | grep -q "mikefarah" || (echo "mikefarah/yq is required" && exit 1)
