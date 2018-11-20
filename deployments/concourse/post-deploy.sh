#!/usr/bin/env bash

set -eo pipefail

function main() {
    setup

    run_errand_with_retry_for_debugging "smoke_tests" "smoke-tests"
    exit $?
}

function setup() {
    SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
    BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
    SUBSYS_NAME=$(own_spec_var /subsys/name)
    readonly SUBSYS_DIR BASE_DIR SUBSYS_NAME
}

function run_errand_with_retry_for_debugging() {
    local errand_name=$1
    local errand_vm_name=$2

    local concourse_target
    concourse_target=$(spec_var /sanity-tests/concourse-target)

    set +e -x
    "${SUBSYS_DIR}/sanity-tests" "${concourse_target}"
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
    DEBUG=yes time bash -x "${SUBSYS_DIR}/sanity-tests" "${concourse_target}"
    error=$?
    set +x -e

    if [[ ${error} -eq 0 ]]; then
        # Whenever the second try succeeds, we delete the collected logs and
        # any dedicated errand VM.
        : # Nothing to do
    fi
    return ${error}
}

function own_spec_var() {
    local path=$1
    bosh int "${SUBSYS_DIR}/conf/spec.yml" --path "${path}"
}

function spec_var() {
    local path=$1

    local has_upstream spec_file
    has_upstream=$(own_spec_var "/subsys/upstream" 2> /dev/null || true)
    if [[ -n ${has_upstream} ]]; then
        state_var "merged-spec" "${path}"
    else
        own_spec_var "${path}"
    fi
}

function state_var() {
    local state_file=$1
    local path=$2
    bosh int "${BASE_DIR}/state/${SUBSYS_NAME}/${state_file}.yml" --path "${path}"
}

main "$@"
