#!/usr/bin/env bash

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

set -eux

pushd "$BASE_DIR/.cache/resources/traefik-boshrelease" || exit 115
    latest_dev_release=$(ls -t dev_releases/traefik/traefik-*.yml 2> /dev/null | head -n 1)
    if [ -z "$latest_dev_release" -o "$(bosh int "$latest_dev_release" --path /commit_hash)" != "$(git rev-parse --short HEAD)" ]; then
        bosh reset-release
        ./scripts/add-blobs.sh
        bosh create-release --force
    fi
    bosh upload-release
popd

htpasswd_file=$BASE_DIR/state/traefik/htpasswd.txt
if [ ! -f "$htpasswd_file" ]; then
    echo -n "# " > "$htpasswd_file"
    chmod 600 "$htpasswd_file"
    openssl rand -base64 24 \
        | tee -a "$htpasswd_file" \
        | htpasswd -ni gstack >> "$htpasswd_file"
fi
