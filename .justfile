#!/usr/bin/env -S just --justfile

[doc('Bootstrap Recipes')]
mod bootstrap '.just/bootstrap.justfile'

[doc('Kube Recipes')]
mod kubernetes '.just/kubernetes.justfile'

[doc('Talos Recipes')]
mod talos '.just/talos.justfile'

[private]
default:
	@just --list
