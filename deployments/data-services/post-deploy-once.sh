#!/usr/bin/env bash

set -e

depl_name=data-services

if [ -f "$BASE_DIR/state/deployments/$depl_name/broker-registrar" ] && grep -qF "status: success" "$BASE_DIR/state/deployments/$depl_name/broker-registrar"; then
    exit
fi

bosh run-errand sanity-test

bosh run-errand broker-registrar
status=$?

if [ "$status" -eq 0 ]; then
    mkdir -p "$BASE_DIR/state/deployments/$depl_name"
    (
        echo "status: success"
        echo "date: $(date -u +%FT%TZ)"
    ) > "$BASE_DIR/state/deployments/$depl_name/broker-registrar"
fi
