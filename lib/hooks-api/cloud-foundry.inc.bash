
# Requires: 'common.inc.bash'

function cf_file_var() {
    local file=$1 path=$2
    bosh int "${SUBSYS_DIR}/../cf/conf/${file}.yml" --path "${path}"
}

function cf_manif_var() {
    cf_state_var "depl-manifest" "$1"
}

function cf_creds_var() {
    cf_state_var "depl-creds" "$1"
}

function cf_login() {
    export LANG=en_US.UTF-8

    cf_api_url=$(cf_manif_var "/instance_groups/name=api/jobs/name=cf-admin-user/properties/api_url")
    cf_skip_ssl_validation=$(cf_manif_var "/instance_groups/name=smoke-tests/jobs/name=smoke_tests/properties/smoke_tests/skip_ssl_validation")
    cf api "$cf_api_url" ${cf_skip_ssl_validation:+"--skip-ssl-validation"}

    cf_admin_username=$(cf_manif_var "/instance_groups/name=api/jobs/name=cf-admin-user/properties/admin_username")

    local initial_xtrace=$(tr -Cd "x" <<< "$-")
    if [[ -n "${initial_xtrace}" ]]; then set +x; fi
        # In this section, we avoind printing passwords to the console
        cf_admin_password=$(cf_creds_var "/cf_admin_password")
        echo "cf auth '${cf_admin_username}' '<redacted>'"
        cf auth "${cf_admin_username}" "${cf_admin_password}"
    if [[ -n "${initial_xtrace}" ]]; then set -x; fi
}

function cf_enforce_security_group() {
    local security_group_name=$1

    cf_login

    # NOTICE: the "cf ... | grep -q ..." constructs below prevents us from
    #         adopting the "-o pipefail" Bash option.
    set +o pipefail

    if ! cf security-groups 2> /dev/null | grep -qE "\\b${security_group_name}\\b"; then
        cf create-security-group "${security_group_name}" "${SUBSYS_DIR}/security-groups.json"
    fi
    if ! cf running-security-groups 2> /dev/null | grep -q "^${security_group_name}\$"; then
        cf bind-running-security-group "${security_group_name}"
    fi
}
