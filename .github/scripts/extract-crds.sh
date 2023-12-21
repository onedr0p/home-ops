#!/usr/bin/env bash
set -o errexit

KUBECTL_BIN=$(command -v kubectl)

# Create temp folder for CRDs
TMP_CRD_DIR=$HOME/.datree/crds
mkdir -p $TMP_CRD_DIR

# Create final schemas directory
SCHEMAS_DIR=$HOME/.datree/crdSchemas
mkdir -p $SCHEMAS_DIR
cd $SCHEMAS_DIR

# Create array to store CRD kinds and groups
ORGANIZE_BY_GROUP=true
declare -A CRD_GROUPS 2>/dev/null
if [ $? -ne 0 ]; then
    # Array creation failed, signal to skip organization by group
    ORGANIZE_BY_GROUP=false
fi

# Extract CRDs from cluster
NUM_OF_CRDS=0
while read -r crd
do
    filename=${crd%% *}
    $KUBECTL_BIN get crds "$filename" -o yaml > "$TMP_CRD_DIR/$filename.yaml" 2>&1

    resourceKind=$(grep "kind:" "$TMP_CRD_DIR/$filename.yaml" | awk 'NR==2{print $2}' | tr '[:upper:]' '[:lower:]')
    resourceGroup=$(grep "group:" "$TMP_CRD_DIR/$filename.yaml" | awk 'NR==1{print $2}')

    # Save name and group for later directory organization
    CRD_GROUPS["$resourceKind"]="$resourceGroup"

    ((++NUM_OF_CRDS)) || true
done < <($KUBECTL_BIN get crds --no-headers)

# If no CRDs exist in the cluster, exit
if [ $NUM_OF_CRDS == 0 ]; then
    printf "No CRDs found in the cluster, exiting...\n"
    exit 0
fi

# Download converter script
curl https://raw.githubusercontent.com/yannh/kubeconform/master/scripts/openapi2jsonschema.py --output $TMP_CRD_DIR/openapi2jsonschema.py 2>/dev/null

# Convert crds to jsonSchema
python3 $TMP_CRD_DIR/openapi2jsonschema.py $TMP_CRD_DIR/*.yaml
conversionResult=$?

# Copy and rename files to support kubeval
rm -rf $SCHEMAS_DIR/master-standalone
mkdir -p $SCHEMAS_DIR/master-standalone
cp $SCHEMAS_DIR/*.json $SCHEMAS_DIR/master-standalone
find $SCHEMAS_DIR/master-standalone -name '*json' -exec bash -c ' mv -f $0 ${0/\_/-stable-}' {} \;

# Organize schemas by group
if [ $ORGANIZE_BY_GROUP == true ]; then
    for schema in $SCHEMAS_DIR/*.json
    do
    crdFileName=$(basename $schema .json)
    crdKind=${crdFileName%%_*}
    crdGroup=${CRD_GROUPS[$crdKind]}
    mkdir -p $crdGroup
    mv $schema ./$crdGroup
    done
fi

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

if [ $conversionResult == 0 ]; then
    printf "${GREEN}Successfully converted $NUM_OF_CRDS CRDs to JSON schema${NC}\n"

    printf "\nTo validate a CR using various tools, run the relevant command:\n"
    printf "\n- ${CYAN}datree:${NC}\n\$ datree test /path/to/file\n"
    printf "\n- ${CYAN}kubeconform:${NC}\n\$ kubeconform -summary -output json -schema-location default -schema-location '$HOME/.datree/crdSchemas/{{ .ResourceKind }}_{{ .ResourceAPIVersion }}.json' /path/to/file\n"
    printf "\n- ${CYAN}kubeval:${NC}\n\$ kubeval --additional-schema-locations file:\"$HOME/.datree/crdSchemas\" /path/to/file\n\n"
fi

rm -rf $TMP_CRD_DIR
