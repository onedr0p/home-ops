set shell := ["bash", "-Eeu", "-o", "pipefail", "-c"]

[private]
default:
	@just --list kube

[private]
with-deps:
	@for tool in kubectl; do \
		command -v $tool >/dev/null || (echo "$tool is required" && exit 1) \
	done

[doc('Spawn a shell on a node')]
[group: 'debug']
node-shell node: with-deps
	@kubectl node-shell -n kube-system -x {{node}}

[doc('Prune all unused Pods')]
[group: 'housekeeping']
prune-pods: with-deps
	@for phase in Failed Pending Succeeded; do \
		kubectl delete pods -A --field-selector status.phase="${phase}" --ignore-not-found=true; \
	done
