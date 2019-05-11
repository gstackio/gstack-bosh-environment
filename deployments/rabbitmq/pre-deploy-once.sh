#!/usr/bin/env bash

set -eo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

source "${BASE_DIR}/lib/hooks-api/common.inc.bash"
source "${BASE_DIR}/lib/hooks-api/cloud-foundry.inc.bash"
source "${BASE_DIR}/lib/hooks-api/bosh-releases.inc.bash"

function main() {
    cf_enforce_security_group "rabbitmq"
}

main "$@"
