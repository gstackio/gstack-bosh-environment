#!/usr/bin/env bash

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function spec_var() {
    local path=$1
    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path"
}

set -ex

create_release=false
dev_release_name=traefik

if [[ $create_release == true ]]; then
    rsc_name=$(spec_var /input_resources/0/name)
    pushd "$BASE_DIR/.cache/resources/$rsc_name" || exit 115
        git submodule update --init --recursive

        latest_dev_release=$(ls -t dev_releases/$dev_release_name/$dev_release_name-*.yml 2> /dev/null | head -n 1)
        if [[ -z $latest_dev_release \
                || $(bosh int "$latest_dev_release" --path /commit_hash) != $(git rev-parse --short HEAD) ]]; then
            bosh reset-release
            ./scripts/add-blobs.sh
            bosh create-release --force
        fi
        # base_version=1.1.0
        # if bosh inspect-release "$dev_release_name/${base_version}+dev.1" &> /dev/null; then
        #     bosh delete-release "$dev_release_name/${base_version}+dev.1"
        # fi
        bosh upload-release
    popd
fi

# # This is no more required in v1.1.0 (historically required for v1.0.0)
# htpasswd_file=$BASE_DIR/state/traefik/htpasswd.txt
# if [ ! -f "$htpasswd_file" ]; then
#     echo -n "# " > "$htpasswd_file"
#     chmod 600 "$htpasswd_file"
#     openssl rand -base64 24 \
#         | tee -a "$htpasswd_file" \
#         | htpasswd -ni gstack >> "$htpasswd_file"
# fi
