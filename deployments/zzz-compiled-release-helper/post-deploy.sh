#!/usr/bin/env bash

set -eo pipefail -u

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

source "${BASE_DIR}/lib/hooks-api/common.inc.bash"

function main() {
    local deployment_name bosh_dns_version node_exporter_version subsys_name \
        used_stemcells stemcell_os_version
    deployment_name=$(own_spec_var "/deployment_vars/deployment_name")
    bosh_dns_version=$(runtime_config_var "/bosh_dns_version")
    node_exporter_version=$(runtime_config_var "/node_exporter_version")
    subsys_name=$(own_spec_var "/subsys/name")

    set -x

    mkdir -p "${BASE_DIR}/.cache/compiled-releases"

    used_stemcells=$(bosh stemcells --column version --column os \
                     | awk '/\*/{gsub(/\*$/, "", $1); print $2 "/" $1}')
    for stemcell_os_version in ${used_stemcells}; do
        export_release "${deployment_name}" \
            "bosh-dns/${bosh_dns_version}" "${stemcell_os_version}" \
            --job=bosh-dns

        export_release "${deployment_name}" \
            "node-exporter/${node_exporter_version}" "${stemcell_os_version}"
    done

    gbe delete -y "$subsys_name"


    local concourse_deployment_name concourse_version stemcell_os \
        stemcell_version non_windows_jobs
    concourse_deployment_name=$(sibling_subsys_depl_var "concourse" "/deployment_name")
    concourse_version=$(sibling_subsys_depl_var "concourse" "/concourse_version")
    stemcell_os=$(sibling_subsys_depl_var "cf" "/stemcell_os")
    stemcell_version=$(sibling_subsys_depl_var "cf" "/stemcell_version")
    if ! bosh deployments --column="name" | grep -qE "\\b${concourse_deployment_name}\\b"; then
        set +x
        echo "WARNING: missing BOSH Deployment '${concourse_deployment_name}' for" \
            "exporting the 'concourse/${concourse_version}' BOSH Release. Skipping."
    else
        non_windows_jobs=($(bosh inspect-release "concourse/${concourse_version}" \
                    | sed -e '/^$/,$d; /^ /d' \
                    | awk '{print $1}' | cut -d/ -f1 | grep -v -- '-windows$'))
        export_release "${concourse_deployment_name}" \
            "concourse/${concourse_version}" "${stemcell_os}/${stemcell_version}" \
            "${non_windows_jobs[@]/#/--job=}"
    fi
}

function export_release() {
    local depl_name=$1; shift
    local release=$1; shift
    local stemcell=$1; shift

    local base_filename
    base_filename=$(tr / - <<< "${release}")-$(tr / - <<< "${stemcell}")

    local cache_dir=${BASE_DIR}/.cache/compiled-releases

    if [[ -n $(find "${cache_dir}" -name "${base_filename}-*.tgz") ]]; then
        return
    fi
    bosh -d "${depl_name}" \
        export-release "${release}" "${stemcell}" \
        --dir="${cache_dir}" \
        "$@"
}

function sibling_subsys_depl_var() {
    local subsys=$1
    local path=$2
    bosh int "${SUBSYS_DIR}/../${subsys}/conf/spec.yml" --path "/deployment_vars${path}"
}

main "$@"
