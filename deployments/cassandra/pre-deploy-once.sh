#!/usr/bin/env bash

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function spec_var() {
    local path=$1
    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path"
}

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

set -ex

create_release=false
dev_release_name=cassandra

if [[ $create_release == true ]]; then
    rsc_name=$(spec_var /input_resources/0/name)
    pushd "$BASE_DIR/.cache/resources/$rsc_name" || exit 115
        git submodule update --init --recursive

        latest_dev_release=$(ls -t dev_releases/$dev_release_name/$dev_release_name-*.yml 2> /dev/null | head -n 1)
        if [[ -z $latest_dev_release \
                || $(bosh int "$latest_dev_release" --path /commit_hash) != $(git rev-parse --short HEAD) ]]; then
            bosh reset-release
            bosh create-release --force
        fi
        # base_version=8
        # if bosh inspect-release "$dev_release_name/${base_version}+dev.1" &> /dev/null; then
        #     bosh delete-release "$dev_release_name/${base_version}+dev.1"
        # fi
        bosh upload-release
    popd
fi

cf_login

security_group_name=cassandra
if ! cf security-groups 2> /dev/null | grep -qE "\\b${security_group_name}\\b"; then
    cf create-security-group "$security_group_name" "$SUBSYS_DIR/security-groups.json"
fi
if ! cf running-security-groups 2> /dev/null | grep -q "^${security_group_name}\$"; then
    cf bind-running-security-group "$security_group_name"
fi
