#!/bin/bash

export REPO_ROOT
REPO_ROOT=$(git rev-parse --show-toplevel)

sed 's/=.*/=""/' $REPO_ROOT/setup/.secrets.env > $REPO_ROOT/setup/.secrets.env.sample