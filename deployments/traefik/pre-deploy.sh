#!/usr/bin/env bash

base_version=0

set -ex

pushd "$BASE_DIR/.cache/resources/traefik-boshrelease" || exit 115
    # bosh reset-release
    # ./scripts/add-blobs.sh
    bosh create-release --force
    # if bosh inspect-release traefik/${base_version}+dev.1 &> /dev/null; then
    #     bosh delete-release traefik/${base_version}+dev.1
    # fi
    bosh upload-release
popd
