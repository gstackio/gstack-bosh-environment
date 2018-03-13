#!/usr/bin/env bash

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function runtime_config_var() {
    local path=$1
    bosh int "$GBE_ENVIRONMENT/runtime-config/conf/spec.yml" --path "/config_vars$path"
}

function spec_var() {
    local path=$1
    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "/deployment_vars$path"
}

bosh_dns_version=$(runtime_config_var /bosh_dns_version)
stemcell_version=$(spec_var /stemcell_version)

set -e

bosh -d bosh-dns-dummy \
    export-release \
    --job=bosh-dns \
    --dir="$BASE_DIR/.cache/compiled-releases" \
    "bosh-dns/$bosh_dns_version" "ubuntu-trusty/$stemcell_version"

gbe delete zzz-bosh-dns -n
