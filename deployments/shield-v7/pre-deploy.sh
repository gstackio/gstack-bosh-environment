#!/usr/bin/env bash

base_version=7.0.3

set -ex

pushd "$BASE_DIR/.cache/resources/gk-shield-boshrelease-v7" || exit 115
    # bosh reset-release
#    bosh create-release --force
    # if bosh inspect-release shield/${base_version}+dev.1 &> /dev/null; then
    #     bosh delete-release shield/${base_version}+dev.1
    # fi
#    bosh upload-release
popd
