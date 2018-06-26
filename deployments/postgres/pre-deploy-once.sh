#!/usr/bin/env bash

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function spec_var() {
    local path=$1
    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path"
}

set -ex

create_release=false
dev_release_name=dingo-postgresql

if [[ $create_release == true ]]; then
    rsc_name=$(spec_var /input_resources/0/name)
    pushd "$BASE_DIR/.cache/resources/$rsc_name" || exit 115
        git submodule update --init --recursive

        latest_dev_release=$(ls -t dev_releases/$dev_release_name/$dev_release_name-*.yml 2> /dev/null | head -n 1)
        if [[ -z $latest_dev_release \
                || $(bosh int "$latest_dev_release" --path /commit_hash) != $(git rev-parse --short HEAD) ]]; then
            bosh reset-release
            bosh create-release
        fi
        # base_version=0.10.2
        # if bosh inspect-release "$dev_release_name/${base_version}+dev.1" &> /dev/null; then
        #     bosh delete-release "$dev_release_name/${base_version}+dev.1"
        # fi
        bosh upload-release
    popd
fi
