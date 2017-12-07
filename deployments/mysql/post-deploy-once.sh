#!/usr/bin/env bash

set -e

depl_name=mysql
state_file=$BASE_DIR/state/deployments/$depl_name/broker-registrar.yml

if [ -f "$state_file" ] && grep -qF "status: success" "$state_file"; then
    exit
fi

bosh run-errand broker-registrar

# bosh run-errand smoke-tests # does not work yet
status=$?

if [ "$status" -eq 0 ]; then
    mkdir -p "$(dirname "$state_file")"
    (
        echo "status: success"
        echo "date: $(date -u +%FT%TZ)"
    ) > "$state_file"
fi
