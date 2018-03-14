#!/usr/bin/env bash

base_version=0

set -e

pushd "$BASE_DIR/.cache/resources/traefik-boshrelease" || exit 115
    latest_dev_release=$(ls -t dev_releases/traefik/traefik-*.yml 2> /dev/null | head -n 1)
    if [ -z "$latest_dev_release" -o "$(bosh int "$latest_dev_release" --path /commit_hash)" != "$(git rev-parse --short HEAD)" ]; then
        set -x
        bosh reset-release
        ./scripts/add-blobs.sh
        bosh create-release --force
        if bosh inspect-release traefik/${base_version}+dev.1 &> /dev/null; then
            bosh delete-release traefik/${base_version}+dev.1
        fi
        bosh upload-release
        set +x
    fi
popd
