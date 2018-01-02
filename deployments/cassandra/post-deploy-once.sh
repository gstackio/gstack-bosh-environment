#!/usr/bin/env bash

set -ex

bosh run-errand broker-registrar


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

cf create-org service-sandbox
cf create-space cassandra-smoke-tests -o service-sandbox

function cleanup() {
    cf target -o service-sandbox -s cassandra-smoke-tests
    cf delete cassandra-example-app -r -f
    cf delete-space cassandra-smoke-tests -o service-sandbox -f
    cf delete-org service-sandbox -f
    cf logout
}

trap cleanup EXIT

bosh run-errand cassandra-smoke-tests
