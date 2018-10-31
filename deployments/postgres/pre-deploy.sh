#!/usr/bin/env bash

set -e

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function spec_var() {
    local path=$1
    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path"
}

function delete_any_existing_unused_release() {
    local release_name=$1
    compute_existing_releases "$release_name"
    for existing_release in "${existing_releases[@]}"; do
        # Don't delete release that are already used
        if [[ $existing_release != *\* ]]; then
            bosh delete-release -n "$existing_release"
        fi
    done
}

function create_upload_release_if_necessary_or_if_stale() {
    local release_name=$1

    local rsc_name create_dev_release latest_dev_release \
        latest_dev_release_commit_hash latest_git_commit_hash
    rsc_name=$(spec_var /input_resources/0/name)
    pushd "$BASE_DIR/.cache/resources/$rsc_name" || exit 115
        latest_dev_release=$(
            ls -t dev_releases/$release_name/$release_name-*.yml 2> /dev/null \
                | head -n 1
        )

        create_dev_release=false
        if [[ -z $latest_dev_release ]]; then
            create_dev_release=true
        else
            latest_dev_release_commit_hash=$(bosh int "$latest_dev_release" --path /commit_hash)
            latest_git_commit_hash=$(git rev-parse --short HEAD)
            if [[ $latest_dev_release_commit_hash != $latest_git_commit_hash ]]; then
                create_dev_release=true
            fi
        fi

        if [[ $create_dev_release == true ]]; then
            git submodule update --init --recursive
            bosh create-release --force
        fi

        delete_any_existing_unused_release "$release_name"

        bosh upload-release
    popd
}

existing_releases=()
function compute_existing_releases() {
    local release_name=$1

    if [[ -n $existing_releases ]]; then
        return
    fi
    existing_releases=(
        $(bosh releases --column name --column version \
            | awk "/${release_name}/"'{print $1 "/" $2}')
    )
}

set -x

developing=false

if [[ $developing == true ]]; then
    create_upload_release_if_necessary_or_if_stale "dingo-postgresql"
fi
