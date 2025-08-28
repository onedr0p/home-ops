#!/usr/bin/env -S just --justfile

set shell := ['bash', '-eu', '-o', 'pipefail', '-c']

[doc('Bootstrap Recipes')]
mod bootstrap '.just/bootstrap.just'

[doc('Kubernetes Recipes')]
mod kube '.just/kube.just'

[doc('Sync Recipes')]
mod sync '.just/sync.just'

[doc('Talos Recipes')]
mod talos '.just/talos.just'

[private]
default:
    @just --list

[positional-arguments, private]
log lvl msg *args:
    @gum log -t rfc3339 -s -l "{{lvl}}" "{{msg}}" {{args}}
