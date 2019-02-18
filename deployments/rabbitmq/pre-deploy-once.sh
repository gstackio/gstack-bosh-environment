#!/usr/bin/env bash

set -e # We can't use "-o pipefail" here, see NOTICE below.

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

function _config() {
    input_resource_index="2"
    release_name="cf-rabbitmq-smoke-tests"
    release_version=$(spec_var /deployment_vars/rabbitmq_smoke_tests_version)
}

function main() {
    _config

    local developing
    developing=$(spec_var /developing)
    # We create a final release only if we are not developing any new version
    # of the release (in which case we'll need to build a new release at each
    # deploy or so)
    if [[ $developing != true ]]; then
        set -x
        create_upload_final_release_if_missing \
            "$input_resource_index" "$release_name" "$release_version"
    fi

    enforce_security_group "rabbitmq"
}

# NOTiCE: the "cf ... | grep -q ..." construct here below prevents us from
#         adopting the "-o pipefail" Bash option.
function enforce_security_group() {
    local security_group_name=$1

    cf_login

    if ! cf security-groups 2> /dev/null | grep -qE "\\b${security_group_name}\\b"; then
        cf create-security-group "$security_group_name" "$SUBSYS_DIR/security-groups.json"
    fi
    if ! cf running-security-groups 2> /dev/null | grep -q "^${security_group_name}\$"; then
        cf bind-running-security-group "$security_group_name"
    fi
}

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

function create_upload_final_release() {
    local input_resource_index=$1
    local release_name=$2
    local release_version=$3

    local rsc_name
    rsc_name=$(spec_var "/input_resources/${input_resource_index}/name")
    pushd "$BASE_DIR/.cache/resources/${rsc_name}" || return 115
        # Note: when building a final release, we don't need any submodule
        bosh create-release "releases/${release_name}/${release_name}-${release_version}.yml"
        bosh upload-release
    popd
}

function has_release_version() {
    local release_name=$1
    local release_version=$2

    bosh inspect-release "${release_name}/${release_version}" &> /dev/null
}

function create_upload_final_release_if_missing() {
    local input_resource_index=$1
    local release_name=$2
    local release_version=$3

    if has_release_version "$release_name" "$release_version"; then
        return
    fi

    create_upload_final_release \
        "$input_resource_index" "$release_name" "$release_version"
}

main "$@"
