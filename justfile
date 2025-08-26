#!/usr/bin/env -S just --justfile

[doc('Kube Recipes')]
mod kube '.just/kube.just'

[doc('Talos Recipes')]
mod talos '.just/talos.just'

[private]
default:
    @just --list

[doc('Bootstrap')]
bootstrap:
    @bash ./scripts/bootstrap.sh
