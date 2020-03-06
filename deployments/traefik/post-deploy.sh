#!/usr/bin/env bash

set -eo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

source "${BASE_DIR}/lib/hooks-api/bosh-errands.inc.bash"

function _config() {
    errand_name="smoke-tests"
    errand_vm_name="" # none, as the errand is co-localized on a persistent VM
}

function main() {
    _config

    run_errand_with_retry_for_debugging \
        "${errand_name}" "${errand_vm_name}" --instance="traefik/first" # --when-changed
}

main "$@"
