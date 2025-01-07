#!/usr/bin/env bash

# List of CRDs to annotate
CRDS=(
    "alerts.notification.toolkit.fluxcd.io"
    "buckets.source.toolkit.fluxcd.io"
    "gitrepositories.source.toolkit.fluxcd.io"
    "helmcharts.source.toolkit.fluxcd.io"
    "helmreleases.helm.toolkit.fluxcd.io"
    "helmrepositories.source.toolkit.fluxcd.io"
    "imagepolicies.image.toolkit.fluxcd.io"
    "imagerepositories.image.toolkit.fluxcd.io"
    "imageupdateautomations.image.toolkit.fluxcd.io"
    "kustomizations.kustomize.toolkit.fluxcd.io"
    "ocirepositories.source.toolkit.fluxcd.io"
    "providers.notification.toolkit.fluxcd.io"
    "receivers.notification.toolkit.fluxcd.io"
)

# Annotation to add
ANNOTATION_KEY="helm.sh/resource-policy"
ANNOTATION_VALUE="keep"

# Loop through each CRD and add the annotation
for CRD in "${CRDS[@]}"; do
    echo "Annotating CRD: $CRD"
    kubectl patch crd "$CRD" --type merge -p "{\"metadata\":{\"annotations\":{\"$ANNOTATION_KEY\":\"$ANNOTATION_VALUE\"}}}"
    if [ $? -ne 0 ]; then
        echo "Failed to annotate $CRD" >&2
    fi
done

echo "Annotation process complete."
