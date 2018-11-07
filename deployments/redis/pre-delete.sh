#!/usr/bin/env bash

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function spec_var() {
    local path=$1
    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path"
}

set -ex

if bosh deployments | grep -qE "\\b$(spec_var /deployment_vars/deployment_name)\\b"; then
    bosh run-errand broker-deregistrar || true
fi
