#!/usr/bin/env bash

set -eo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

source "${BASE_DIR}/lib/hooks-api/common.inc.bash"
source "${BASE_DIR}/lib/hooks-api/bosh-releases.inc.bash"

function _config() {
    input_resource_index="0"
    release_name="cockroachdb"
    release_version=$(spec_var /deployment_vars/cockroachdb_version)
}

function main() {
    _config

    local developing
    developing=$(spec_var "/developing"  2> /dev/null || true)
    # We create a final release only if we are not developing any new version
    # of the release (in which case we'll need to build a new release at each
    # deploy or so)
    if [[ "${developing}" != "true" ]]; then
        create_upload_final_release_if_missing \
            "$input_resource_index" "$release_name" "$release_version"
    fi
}

main "$@"
