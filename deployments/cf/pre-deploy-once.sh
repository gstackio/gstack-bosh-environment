#!/usr/bin/env bash

function rt_cfg_var() {
    local path=$1
    bosh int "$BASE_DIR/base-env/runtime-config/conf/spec.yml" \
        --path "/config_vars$path"
}

bosh_dns_version=$(rt_cfg_var /bosh_dns_version)
bosh_dns_sha1=$(rt_cfg_var /bosh_dns_sha1)

set -ex

# When the 'bosh-dns' compiled release has been uploaded (with 'gbe import'),
# we only have the 'bosh-dns' job for Linux. As the runtime config also
# references the 'bosh-dns-windows' job, we actually need the complete release
# to be uploaded here.
bosh upload-release \
    --sha1 "$bosh_dns_sha1" \
    "https://bosh.io/d/github.com/cloudfoundry/bosh-dns-release?v=$bosh_dns_version"
