#!/usr/bin/env bash

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function spec_var() {
    local path=$1
    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path"
}

set -ex

developing=false
dev_release_name=shield
base_version=7.0.7

if [[ $developing == true ]]; then
    rsc_name=$(spec_var /input_resources/0/name)
    pushd "$BASE_DIR/.cache/resources/$rsc_name" || exit 115
        latest_dev_release=$(ls -t dev_releases/$dev_release_name/$dev_release_name-*.yml 2> /dev/null | head -n 1)
        if [[ -z $latest_dev_release \
                || $(bosh int "$latest_dev_release" --path /commit_hash) != $(git rev-parse --short HEAD) ]]; then
            bosh reset-release
            bosh create-release --force
        fi
        # if bosh inspect-release "$dev_release_name/${base_version}+dev.1" &> /dev/null; then
        #     bosh delete-release "$dev_release_name/${base_version}+dev.1"
        # fi
        bosh upload-release
    popd
fi
