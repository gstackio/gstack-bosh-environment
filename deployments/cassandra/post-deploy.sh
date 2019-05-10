#!/usr/bin/env bash

set -eo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

source "${BASE_DIR}/lib/hooks-api/common.inc.bash"
source "${BASE_DIR}/lib/hooks-api/cloud-foundry.inc.bash"
source "${BASE_DIR}/lib/hooks-api/bosh-errands.inc.bash"

function main() {
    setup

    set +o pipefail # because of the `bosh ... | grep -q ...` construct below

    if bosh instances | grep -qF "smoke-tests"; then
        cf_login

        local initial_xtrace=$(tr -Cd "x" <<< "$-")
        if [[ -z "${initial_xtrace}" ]]; then set -x; fi
            cf create-org "${SMOKE_TESTS_ORG}"
            cf create-space "${SMOKE_TESTS_SPACE}" -o "${SMOKE_TESTS_ORG}"
        if [[ -z "${initial_xtrace}" ]]; then set +x; fi

        trap cleanup EXIT

        run_errand_with_retry_for_debugging "broker-smoke-tests" "smoke-tests-vm" # --when-changed
    fi
}

function setup() {
    SMOKE_TESTS_ORG="service-sandbox"
    SMOKE_TESTS_SPACE="cassandra-smoke-tests"
    SMOKE_TESTS_APP="cassandra-example-app"
    SMOKE_TESTS_SERVICE_INSTANCE="cassandra-instance"
}

function cleanup() {
    cf target -o "${SMOKE_TESTS_ORG}" -s "${SMOKE_TESTS_SPACE}"

    local initial_xtrace=$(tr -Cd "x" <<< "$-")
    if [[ -z "${initial_xtrace}" ]]; then set -x; fi
        cf delete "${SMOKE_TESTS_APP}" -r -f
        cf delete-service "${SMOKE_TESTS_SERVICE_INSTANCE}" -f
        cf delete-space "${SMOKE_TESTS_SPACE}" -o "${SMOKE_TESTS_ORG}" -f
        cf delete-org "${SMOKE_TESTS_ORG}" -f
    if [[ -z "${initial_xtrace}" ]]; then set +x; fi

    cf logout
}

main "$@"
