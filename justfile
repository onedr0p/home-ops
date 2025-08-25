#!/usr/bin/env -S just --justfile

[doc('Bootstrap')]
mod bootstrap '.just/bootstrap.just'

[private]
default:
    @just --list

[positional-arguments, private]
log lvl msg *args:
    @gum log --time=rfc3339 --structured --level "{{lvl}}" "{{msg}}" {{args}}
