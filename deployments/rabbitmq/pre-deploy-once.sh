#!/usr/bin/env bash

set -eo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

source "${BASE_DIR}/lib/hooks-api/common.inc.bash"
source "${BASE_DIR}/lib/hooks-api/cloud-foundry.inc.bash"
source "${BASE_DIR}/lib/hooks-api/bosh-releases.inc.bash"

function main() {
    cf_enforce_security_group "rabbitmq"

    # Workaround issues with broker-registrar-boshrelease v3.4.0
    input_resource_index="3"
    release_name="broker-registrar"
    create_upload_dev_release_only_if_missing \
        "${input_resource_index}" "${release_name}"
}

main "$@"
