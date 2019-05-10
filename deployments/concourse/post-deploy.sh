#!/usr/bin/env bash

set -eo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

source "${BASE_DIR}/lib/hooks-api/common.inc.bash"
source "${BASE_DIR}/lib/hooks-api/bosh-errands.inc.bash"

function main() {
    run_concourse_sanity_tests_with_retry_for_debugging
}

function run_concourse_sanity_tests_with_retry_for_debugging() {
    local concourse_target logs_dir
    concourse_target=$(spec_var /sanity-tests/concourse-target 2> /dev/null || true)

    function errand_runner() {
        "${SUBSYS_DIR}/sanity-tests" "${concourse_target}"
    }

    # When there's an error, we restart the smoke tests, collecting logs and
    # keeping the VM arround for debugging purpose.
    function debug_errand_runner() {
        DEBUG=yes time bash -x "${SUBSYS_DIR}/sanity-tests" "${concourse_target}"
    }

    # Whenever the second try succeeds, we delete the collected logs and any
    # dedicated errand VM.
    function cleanup_debug_errand_run() {
        : # Nothing to do
    }

    run_scripts_with_retry_and_cleanup \
        "errand_runner" "debug_errand_runner" "cleanup_debug_errand_run"
}

main "$@"
