#!/usr/bin/env -S just --justfile

[doc('Bootstrap Recipes')]
mod bootstrap '.just/bootstrap.just'

[doc('Kube Recipes')]
mod kube '.just/kube.just'

[private]
default:
    @just --list

[positional-arguments, private]
log lvl msg *args:
    @gum log --time=rfc3339 --structured --level "{{lvl}}" "{{msg}}" {{args}}
