#!/usr/bin/env bash

set -eo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

source "${BASE_DIR}/lib/hooks-api/common.inc.bash"
source "${BASE_DIR}/lib/hooks-api/cloud-foundry.inc.bash"
source "${BASE_DIR}/lib/hooks-api/bosh-releases.inc.bash"

function _config() {
    provide_dev_release=false
    input_resource_index="0"
    release_name="cassandra"
}

function main() {
    _config

    cf_enforce_security_group "cassandra"

    if [[ "${provide_dev_release}" == "true" ]]; then
        create_upload_dev_release_only_if_missing \
            "${input_resource_index}" "${release_name}"
    fi
}

main "$@"
