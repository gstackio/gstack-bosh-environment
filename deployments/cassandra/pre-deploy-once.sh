#!/usr/bin/env bash

set -ex

pushd "$BASE_DIR/.cache/resources/cassandra-boshrelease" || exit 115
    git submodule update --init --recursive
    bosh create-release
    bosh upload-release
popd
