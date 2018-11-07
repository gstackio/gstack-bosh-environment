#!/usr/bin/env bash

set -o pipefail

function run_errand_with_retry_for_debugging() {
    local errand_name=$1
    local errand_vm_name=$2

    set -x
    bosh run-errand "${errand_name}" --when-changed
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
    time bosh run-errand "${errand_name}" --keep-alive --download-logs --logs-dir="${logs_dir}"
    error=$?
    set +x -e

    if [[ ${error} -eq 0 ]]; then
        # Whenever the second try succeeds, we delete the collected logs and
        # any dedicated errand VM.
        rm -r "${logs_dir}"
        if [[ -n ${errand_vm_name} ]]; then
            bosh --non-interactive stop --hard "${errand_vm_name}"
        fi
    fi
    return ${error}
}

# Smoke tests don't support Go Buildpack v1.8.28+ yet, so we disable them
# temporarily.
#
# See: https://github.com/cloudfoundry-community/logsearch-boshrelease/issues/129
#
# run_errand_with_retry_for_debugging "smoke-tests"
exit $?
