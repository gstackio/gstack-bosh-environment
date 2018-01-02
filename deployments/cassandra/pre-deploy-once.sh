#!/usr/bin/env bash

set -ex

pushd "$BASE_DIR/.cache/resources/cassandra-boshrelease" || exit 115
    git submodule update --init --recursive
    bosh create-release
    bosh upload-release
popd

cf_api_url=$(bosh int "$BASE_DIR/state/cf/depl-manifest.yml" \
        --path /instance_groups/name=api/jobs/name=cf-admin-user/properties/api_url)
cf_skip_ssl_validation=$(bosh int "$BASE_DIR/state/cf/depl-manifest.yml" \
        --path /instance_groups/name=smoke-tests/jobs/name=smoke_tests/properties/smoke_tests/skip_ssl_validation)
cf api "$cf_api_url" ${cf_skip_ssl_validation:+--skip-ssl-validation}

cf_admin_username=$(bosh int "$BASE_DIR/state/cf/depl-manifest.yml" \
        --path /instance_groups/name=api/jobs/name=cf-admin-user/properties/admin_username)
set +x
cf_admin_password=$(bosh int "$BASE_DIR/state/cf/depl-creds.yml" \
        --path /cf_admin_password)
echo "cf auth '$cf_admin_username' '<redacted>'"
cf auth "$cf_admin_username" "$cf_admin_password"
set -x

if ! cf security-groups 2> /dev/null | grep -qE '\bcassandra\b'; then
    cf create-security-group cassandra "$BASE_DIR/deployments/cassandra/security-groups.json"
fi
if ! cf running-security-groups 2> /dev/null | grep -q '^cassandra$'; then
    cf bind-running-security-group cassandra
fi
