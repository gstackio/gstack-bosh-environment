#!/usr/bin/env bash

set -e # We can't use "-o pipefail" here, see NOTICE below.

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

function main() {
    enforce_security_group "rabbitmq"
    create_upload_release_if_missing "broker-registrar" "3"
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

function create_upload_release_if_necessary_or_if_stale() {
    local release_name=$1
    local input_resource_index=$2

    local rsc_name create_dev_release latest_dev_release \
        latest_dev_release_commit_hash latest_git_commit_hash
    rsc_name=$(spec_var "/input_resources/$input_resource_index/name")
    pushd "$BASE_DIR/.cache/resources/$rsc_name" || exit 115
        latest_dev_release=$(
            ls -t dev_releases/$release_name/$release_name-*.yml 2> /dev/null \
                | head -n 1
        )

        create_dev_release=false
        if [[ -z $latest_dev_release ]]; then
            create_dev_release=true
        else
            latest_dev_release_commit_hash=$(bosh int "$latest_dev_release" --path /commit_hash)
            latest_git_commit_hash=$(git rev-parse --short HEAD)
            if [[ $latest_dev_release_commit_hash != $latest_git_commit_hash ]]; then
                create_dev_release=true
            fi
        fi

        if [[ $create_dev_release == true ]]; then
            git submodule update --init --recursive
            bosh create-release --force
        fi

        bosh upload-release
    popd
}

existing_releases=()
function compute_existing_releases() {
    local release_name=$1

    if [[ -n $existing_releases ]]; then
        return
    fi
    existing_releases=(
        $(bosh releases --column name --column version \
            | awk "/^${release_name}[[:blank:]]/"'{print $1 "/" $2}')
    )
}

function create_upload_release_if_missing() {
    local release_name=$1
    local input_resource_index=${2:-"0"}

    compute_existing_releases "$release_name"
    if [[ -n $existing_releases ]]; then
        return
    fi

    create_upload_release_if_necessary_or_if_stale "$release_name" "$input_resource_index"
}

main "$@"
