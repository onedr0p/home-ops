#!/usr/bin/env bash

find ./kubernetes -name '*.sops.yaml' | while read -r file;
do
    sops -d "${file}" >/dev/null 2>&1 && rc=$? || rc=$?
    # In case of MAC mismatch, then MAC is regenerated
    # See https://github.com/mozilla/sops/blob/v3.6.1/cmd/sops/codes/codes.go#L19
    if [ $rc -eq 51  ] ; then
        echo "Regenerating sops MAC for: ${file}"
        EDITOR="vim -es +'norm Go' +':wq'" sops --ignore-mac "${file}"
    fi
done
