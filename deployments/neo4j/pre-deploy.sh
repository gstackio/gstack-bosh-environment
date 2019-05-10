#!/usr/bin/env bash

set -eo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

source "${BASE_DIR}/lib/hooks-api/common.inc.bash"
source "${BASE_DIR}/lib/hooks-api/bosh-releases.inc.bash"

function _config() {
    provide_dev_release="true"
    input_resource_index="0"
    release_name="neo4j"
    release_subdir_in_git="neo4j-release"
}

function main() {
    _config

    local developing
    developing=$(own_spec_var "/developing" 2> /dev/null || true)

    if [[ "${developing}" == "true" ]]; then
        create_upload_dev_release_if_necessary "${input_resource_index}" \
            "${release_name}" "${release_subdir_in_git}"
    elif [[ "${provide_dev_release}" == "true" ]]; then
        create_upload_dev_release_only_if_missing "${input_resource_index}" \
            "${release_name}" "${release_subdir_in_git}"
    fi
}

main "$@"
