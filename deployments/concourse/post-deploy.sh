#!/usr/bin/env bash

set -eo pipefail

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function run_errand_with_retry_for_debugging() {
    local errand_name=$1
    local errand_vm_name=$2

    set +e -x
    "${SUBSYS_DIR}/sanity-tests"
    error=$?
    set +x -e

    if [[ ${error} -eq 0 ]]; then
        return 0
    fi

    # When there's an error, we restart the smoke tests, collecting logs and
    # keeping the VM arround for debugging purpose.

    logs_dir="${BASE_DIR}/logs/$(basename "${SUBSYS_DIR}")/${errand_name}"
    mkdir -p "${logs_dir}"

    set +e -x
    DEBUG=yes time bash -x "$SUBSYS_DIR/sanity-tests"
    error=$?
    set +x -e

    if [[ ${error} -eq 0 ]]; then
        # Whenever the second try succeeds, we delete the collected logs and
        # any dedicated errand VM.
        : # Nothing to do
    fi
    return ${error}
}

run_errand_with_retry_for_debugging "smoke_tests" "smoke-tests"
exit $?
