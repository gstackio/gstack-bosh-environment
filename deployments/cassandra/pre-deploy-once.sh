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

set -ex

pushd "$BASE_DIR/.cache/resources/cassandra-boshrelease" || exit 115
    git submodule update --init --recursive
    bosh reset-release
    bosh create-release --force
    bosh upload-release
popd

cf_login

if ! cf security-groups 2> /dev/null | grep -qE '\bcassandra\b'; then
    cf create-security-group cassandra "$BASE_DIR/deployments/cassandra/security-groups.json"
fi
if ! cf running-security-groups 2> /dev/null | grep -q '^cassandra$'; then
    cf bind-running-security-group cassandra
fi
