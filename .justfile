#!/usr/bin/env -S just --justfile

[doc('Bootstrap Recipes')]
mod bootstrap

[doc('Kube Recipes')]
mod kubernetes

[doc('Talos Recipes')]
mod talos

[private]
default:
    @just --list --unsorted
