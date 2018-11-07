#!/usr/bin/env bash

function cf_state_var() {
    local state_file=$1
    local path=$2
    bosh int "$BASE_DIR/state/cf/$state_file.yml" --path "$path"
}

function cf_depl_var() {
    cf_state_var depl-manifest "$1"
}

function cf_creds_var() {
    cf_state_var depl-creds "$1"
}

function cf_login() {
    export LANG=en_US.UTF-8

    cf_api_url=$(cf_depl_var /instance_groups/name=api/jobs/name=cf-admin-user/properties/api_url)
    cf_skip_ssl_validation=$(cf_depl_var /instance_groups/name=smoke-tests/jobs/name=smoke_tests/properties/smoke_tests/skip_ssl_validation)
    cf api "$cf_api_url" ${cf_skip_ssl_validation:+--skip-ssl-validation}

    cf_admin_username=$(cf_depl_var /instance_groups/name=api/jobs/name=cf-admin-user/properties/admin_username)
    set +x
    cf_admin_password=$(cf_creds_var /cf_admin_password)
    echo "cf auth '$cf_admin_username' '<redacted>'"
    cf auth "$cf_admin_username" "$cf_admin_password"
    set -x
}

function cleanup() {
    cf target -o service-sandbox -s cassandra-smoke-tests
    cf delete cassandra-example-app -r -f
    cf delete-service cassandra-instance -f
    cf delete-space cassandra-smoke-tests -o service-sandbox -f
    cf delete-org service-sandbox -f
    cf logout
}

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

set -ex

if bosh instances | grep -qF smoke-tests; then
    cf_login

    cf create-org service-sandbox
    cf create-space cassandra-smoke-tests -o service-sandbox

    trap cleanup EXIT

    run_errand_with_retry_for_debugging "broker-smoke-tests" "smoke-tests-vm"
fi
