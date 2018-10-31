#!/usr/bin/env bash

set -o pipefail

set -x
bosh run-errand smoke_tests --when-changed
error=$?
set +x -e

if [[ $error -eq 0 ]]; then
    exit 0
fi

# When there's an error, we restart the smoke tests, collecting logs and
# keeping the VM arround for debugging purpose.

logs_dir="${BASE_DIR}/logs/$(basename "${SUBSYS_DIR}")/smoke-tests"
mkdir -p "${logs_dir}"

set +e -x
time bosh run-errand smoke_tests --keep-alive --download-logs --logs-dir="${logs_dir}"
error=$?
set +x -e

if [[ $error -eq 0 ]]; then
    # Whenever the second try succeeds, we delete the collected logs and the
    # smoke-tests VM.
    rm -r "${logs_dir}"
    bosh --non-interactive stop --hard smoke-tests
fi
