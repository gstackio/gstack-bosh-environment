#!/usr/bin/env bash

set -e

depl_name=data-services
state_file=$BASE_DIR/state/deployments/$depl_name/broker-registrar.yml

if [ -f "$state_file" ] && grep -qF "status: success" "$state_file"; then
    exit
fi

bosh run-errand sanity-test

bosh run-errand broker-registrar
status=$?

if [ "$status" -eq 0 ]; then
    mkdir -p "$(dirname "$state_file")"
    (
        echo "status: success"
        echo "date: $(date -u +%FT%TZ)"
    ) > "$state_file"
fi
