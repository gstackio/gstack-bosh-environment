#!/usr/bin/env bash

set -e # We can't use "-o pipefail" here, see NOTICE below.

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function main() {
    # configuration is here below
    local input_resource_index="2"
    local release_name="cf-rabbitmq-smoke-tests"


    set -x
    local developing
    developing=$(spec_var /developing || true)
    if [[ $developing == true ]]; then
        create_upload_release_if_necessary_or_if_stale \
            "$input_resource_index" "$release_name"
    fi
}

function spec_var() {
    local path=$1
    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path"
}

function delete_any_existing_unused_dev_release() {
    local release_name=$1

    compute_existing_dev_releases "$release_name"
    for existing_release in "${existing_dev_releases[@]}"; do
        # Don't delete release that are already used
        if [[ $existing_release != *\* ]]; then
            bosh delete-release -n "$existing_release"
        fi
    done
}

function create_upload_release_if_necessary_or_if_stale() {
    local input_resource_index=$1
    local release_name=$2

    local rsc_name latest_dev_release \
        latest_dev_release_commit_hash latest_git_commit_hash
    rsc_name=$(spec_var "/input_resources/${input_resource_index}/name")
    pushd "$BASE_DIR/.cache/resources/$rsc_name" || exit 115
        # NOTICE: such construct here below prevent us from adopting the
        #         "-o pipefail" Bash option
        latest_dev_release=$(
            ls -t "dev_releases/${release_name}/${release_name}"-*.yml 2> /dev/null \
                | head -n 1
        )

        latest_dev_release_commit_hash=$(bosh int "$latest_dev_release" --path /commit_hash) || true
        latest_git_commit_hash=$(git rev-parse --short HEAD)
        if [[ -z $latest_dev_release \
                || $latest_dev_release_commit_hash != $latest_git_commit_hash ]]; then
            git submodule update --init --recursive
            bosh create-release --force
        fi

        delete_any_existing_unused_dev_release "$release_name"

        bosh upload-release
    popd
}

existing_dev_releases=()
function compute_existing_dev_releases() {
    local release_name=$1

    if [[ -n $existing_dev_releases ]]; then
        return
    fi
    existing_dev_releases=(
        $(bosh releases --column name --column version \
            | awk "/^${release_name}[[:blank:]].*\\+dev\\./"'{print $1 "/" $2}')
    )
}

main "$@"
