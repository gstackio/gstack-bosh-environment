#!/usr/bin/env bash

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function spec_var() {
    local path=$1
    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path"
}

set -e

developing=true
dev_release_name=neo4j
base_version=

if [[ $developing == true ]]; then
    rsc_name=$(spec_var /input_resources/0/name)
    pushd "$BASE_DIR/.cache/resources/$rsc_name/neo4j-release" || exit 115
        latest_dev_release=$(ls -t dev_releases/$dev_release_name/$dev_release_name-*.yml 2> /dev/null | head -n 1)
        set -x
        if [[ -z $latest_dev_release \
                || $(bosh int "$latest_dev_release" --path /commit_hash) != $(git rev-parse --short HEAD) ]]; then
            # bosh reset-release
            # ./scripts/add-blobs.sh
            bosh create-release --force
        fi
        # if bosh inspect-release "$dev_release_name/${base_version}+dev.1" &> /dev/null; then
        #     bosh delete-release "$dev_release_name/${base_version}+dev.1"
        # fi
        bosh upload-release
        set +x
    popd
fi
