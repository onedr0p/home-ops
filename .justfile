#!/usr/bin/env -S just --justfile

set shell := ["bash", "-Eeu", "-o", "pipefail", "-c"]

[doc('Bootstrap Recipes')]
mod bootstrap '.just/bootstrap.just'

[doc('Kube Recipes')]
mod kubernetes '.just/kubernetes.just'

[doc('Talos Recipes')]
mod talos '.just/talos.just'

[private]
default:
	@just --list
