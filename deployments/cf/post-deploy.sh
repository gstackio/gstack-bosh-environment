#!/usr/bin/env bash

set -eo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

source "${BASE_DIR}/lib/hooks-api/bosh-errands.inc.bash"

function main() {
    run_errand_with_retry_for_debugging "smoke_tests" "smoke-tests" # --when-changed
}

main "$@"
