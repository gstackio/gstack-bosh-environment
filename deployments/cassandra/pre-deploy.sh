#!/usr/bin/env bash

pushd "$BASE_DIR/.cache/ubdms/cassandra-boshrelease" || exit 115
    bosh create-release
    bosh upload-release
popd
