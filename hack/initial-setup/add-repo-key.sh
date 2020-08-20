#!/usr/bin/env sh

# Credit: billimek@github
# https://github.com/billimek/k8s-gitops/blob/master/setup/add-repo-key.sh

# This script will, for the current repo:
# 1. delete any existing repo keys
# 2. add a new repo key from the input passed-in

#
# @CHANGEME - Update to your GitHub Username
#
github_username=onedr0p

if [ ! -f "$HOME/.secret/github_access_token" ]; then
    echo "$HOME/.secret/github_access_token needs to exist with a GitHub personal access token"
    exit 1
fi

if [ -z "$1" ]; then
    echo "This script requires an ssh-key passed in as an argument"
    exit 1
else
    KEY="$1"
fi

need() {
    which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

need "git"
need "curl"
need "jq"

github_access_token=$(cat "${HOME}"/.secret/github_access_token)

rp=$(git rev-parse --is-inside-work-tree 2>/dev/null)

if [ "$?" -eq 0 ] && [ "$rp" = "true" ]; then
    url="$(git config --get remote.origin.url)"
    repo=${url##*/}
    reponame=${repo%%.*}

    repo_id="github-deploy-$reponame.github.com"

    # delete all existing deploy keys
    curl \
        -H"Authorization: token $github_access_token"\
        https://api.github.com/repos/"$github_username"/"$reponame"/keys 2>/dev/null\
        | jq '.[] | .id ' | \
        while read _id; do
            echo "- deploy key: $_id"
            curl \
                -X "DELETE"\
                -H"Authorization: token $github_access_token"\
                https://api.github.com/repos/"$github_username"/"$reponame"/keys/"$_id" 2>/dev/null
        done

    # add the keyfile to github
    echo
    echo "+ deploy key:"
    echo -n ">> "
    {
        curl \
            -i\
            -H"Authorization: token $github_access_token"\
            --data @- https://api.github.com/repos/"$github_username"/"$reponame"/keys << EOF
    {
        "title" : "$repo_id $(date)",
        "key" : "$KEY",
        "read_only" : false
    }
EOF
    } 2>/dev/null | head -1 # status code should be 201

else
    echo 'Not a git repository'
    exit
fi
