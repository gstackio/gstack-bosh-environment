#!/usr/bin/env bash

set -euo pipefail

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BASE_DIR=$(cd "$SUBSYS_DIR/../.." && pwd)

function runtime_config_var() {
    local path=$1
    bosh int "$BASE_DIR/$GBE_ENVIRONMENT/runtime-config/conf/spec.yml" --path "/config_vars${path}"
}

function spec_var() {
    local path=$1
    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path"
}

function sibling_subsys_depl_var() {
    local subsys=$1
    local path=$2
    bosh int "$SUBSYS_DIR/../$subsys/conf/spec.yml" --path "/deployment_vars${path}"
}

function export_release() {
    local depl_name=$1; shift
    local release=$1; shift
    local stemcell=$1; shift

    local base_filename
    base_filename=$(tr / - <<< "$release")-$(tr / - <<< "$stemcell")

    local cache_dir=$BASE_DIR/.cache/compiled-releases

    if [[ -n $(find "$cache_dir" -name "${base_filename}-*.tgz") ]]; then
        return
    fi
    bosh -d "$depl_name" \
        export-release "$release" "$stemcell" \
        --dir="$cache_dir" \
        "$@"
}

deployment_name=$(spec_var /deployment_vars/deployment_name)
bosh_dns_version=$(runtime_config_var /bosh_dns_version)
node_exporter_version=$(runtime_config_var /node_exporter_version)
stemcell_version=$(sibling_subsys_depl_var cf /stemcell_version)
subsys_name=$(spec_var /subsys/name)

set -x

mkdir -p "$BASE_DIR/.cache/compiled-releases"

export_release "$deployment_name" \
    "bosh-dns/$bosh_dns_version" "ubuntu-trusty/$stemcell_version" \
    --job=bosh-dns

export_release "$deployment_name" \
    "node-exporter/$node_exporter_version" "ubuntu-trusty/$stemcell_version"

gbe delete -y "$subsys_name"



concourse_deployment_name=$(sibling_subsys_depl_var concourse /deployment_name)
concourse_version=$(sibling_subsys_depl_var concourse /concourse_version)
if ! bosh deployments --column=name | grep -qE "\\b${concourse_deployment_name}\\b"; then
    set +x
    echo "WARNING: missing BOSH Deployment '$concourse_deployment_name' for" \
        "exporting the 'concourse/$concourse_version' BOSH Release. Skipping."
else
    non_windows_jobs=($(bosh inspect-release "concourse/$concourse_version" \
                | sed -e '/^$/,$d; /^ /d' \
                | awk '{print $1}' | cut -d/ -f1 | grep -v -- '-windows$'))
    export_release "$concourse_deployment_name" \
        "concourse/$concourse_version" "ubuntu-trusty/$stemcell_version" \
        "${non_windows_jobs[@]/#/--job=}"
fi
