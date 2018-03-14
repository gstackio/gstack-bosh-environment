#!/usr/bin/env bash

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function runtime_config_var() {
    local path=$1
    bosh int "$GBE_ENVIRONMENT/runtime-config/conf/spec.yml" --path "/config_vars$path"
}

function spec_var() {
    local path=$1
    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path"
}

deployment_name=$(spec_var /deployment_vars/deployment_name)
bosh_dns_version=$(runtime_config_var /bosh_dns_version)
node_exporter_version=$(runtime_config_var /node_exporter_version)
stemcell_version=$(spec_var /deployment_vars/stemcell_version)
subsys_name=$(spec_var /subsys/name)

set -e

bosh -d "$deployment_name" \
    export-release \
    --job=bosh-dns \
    --dir="$BASE_DIR/.cache/compiled-releases" \
    "bosh-dns/$bosh_dns_version" "ubuntu-trusty/$stemcell_version"

bosh -d "$deployment_name" \
    export-release \
    --dir="$BASE_DIR/.cache/compiled-releases" \
    "node-exporter/$node_exporter_version" "ubuntu-trusty/$stemcell_version"

gbe delete "$subsys_name" -n
