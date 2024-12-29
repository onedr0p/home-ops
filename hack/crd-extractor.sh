#!/usr/bin/env bash

set -euo pipefail

# Function to fetch a CRD
fetch_crd() {
    local crd="$1"
    local crd_file="$TMP_CRD_DIR/$crd.yaml"
    if ! kubectl get crds "$crd" -o yaml >"$crd_file" 2>/dev/null; then
        printf "Failed to fetch CRD: %s\n" "$crd"
        return 1
    fi
}

# Directories
TMP_CRD_DIR="$HOME/.datree/crds"
SCHEMAS_DIR="$HOME/.datree/crdSchemas"

# Initialize directories
mkdir -p "$TMP_CRD_DIR" "$SCHEMAS_DIR"
cd "$SCHEMAS_DIR" || { echo "Failed to change to schemas directory"; exit 1; }

# Fetch list of CRDs
printf "Fetching list of CRDs...\n"
kubectl get crds | awk 'NR>1 {print $1}' >"$TMP_CRD_DIR/crd_list.txt"

# Read CRDs into an array
CRD_LIST=()
while IFS= read -r line; do
    CRD_LIST+=("$line")
done <"$TMP_CRD_DIR/crd_list.txt"

# Check if there are any CRDs
if [ "${#CRD_LIST[@]}" -eq 0 ]; then
    printf "No CRDs found in the cluster, exiting...\n"
    exit 0
fi

# Fetch CRDs in parallel
FETCHED_CRDS=0
PARALLELISM=10
for crd in "${CRD_LIST[@]}"; do
    printf "Fetching CRD %d/%d: %s\n" $((FETCHED_CRDS + 1)) "${#CRD_LIST[@]}" "$crd"

    fetch_crd "$crd" &

    # Ensure a maximum of $PARALLELISM jobs run in parallel
    while [ "$(jobs -r | wc -l)" -ge "$PARALLELISM" ]; do
        wait -n
    done

    FETCHED_CRDS=$((FETCHED_CRDS + 1))
done

# Wait for all background jobs to finish
wait

# Download converter script
CONVERTER_SCRIPT="$TMP_CRD_DIR/openapi2jsonschema.py"
printf "Downloading OpenAPI to JSON schema converter script...\n"
if ! curl -sSL "https://raw.githubusercontent.com/yannh/kubeconform/master/scripts/openapi2jsonschema.py" -o "$CONVERTER_SCRIPT"; then
    printf "Failed to download converter script\n"
    exit 1
fi

# Convert CRDs to JSON schema
printf "Converting CRDs to JSON schema...\n"
if ! FILENAME_FORMAT="{fullgroup}_{kind}_{version}" python3 "$CONVERTER_SCRIPT" "$TMP_CRD_DIR"/*.yaml; then
    printf "Failed to convert CRDs to JSON schema\n"
    exit 1
fi

# Prepare master-standalone directory
rm -rf "$SCHEMAS_DIR/master-standalone"
mkdir -p "$SCHEMAS_DIR/master-standalone"

# Rename and copy JSON files
for json_file in "$SCHEMAS_DIR"/*.json; do
    base_name=$(basename "$json_file")
    new_name=${base_name//_/-stable-}
    cp "$json_file" "$SCHEMAS_DIR/master-standalone/$new_name"
done

# Organize schemas by group
for schema in "$SCHEMAS_DIR"/*.json; do
    crd_file_name=$(basename "$schema")
    crd_group="${crd_file_name%%_*}"
    out_name="${crd_file_name#*_}"
    group_dir="$SCHEMAS_DIR/$crd_group"
    mkdir -p "$group_dir"
    mv "$schema" "$group_dir/$out_name"
done

# Print success message
printf "Successfully converted %d CRDs to JSON schema\n" "$FETCHED_CRDS"

# Cleanup
rm -rf "$TMP_CRD_DIR"
