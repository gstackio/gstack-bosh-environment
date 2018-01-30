#!/usr/bin/env bash

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

set -eux

pushd "$BASE_DIR/.cache/resources/shield-boshrelease" || exit 115
    #bosh reset-release
    # bosh create-release
    # bosh upload-release
popd
