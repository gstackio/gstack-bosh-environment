#!/usr/bin/env bash

set -eo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}

source "${BASE_DIR}/lib/hooks-api/common.inc.bash"

function main() {
    local bosh_dns_version bosh_dns_sha1
    bosh_dns_version=$(runtime_config_var "/bosh_dns_version")
    bosh_dns_sha1=$(runtime_config_var "/bosh_dns_sha1")

    set -x

    # When the 'bosh-dns' compiled release has been uploaded (with 'gbe import'),
    # we only have the 'bosh-dns' job for Linux. As the runtime config also
    # references the 'bosh-dns-windows' job, we actually need the complete release
    # to be uploaded here.
    bosh upload-release \
        --sha1 "${bosh_dns_sha1}" \
        "https://bosh.io/d/github.com/cloudfoundry/bosh-dns-release?v=${bosh_dns_version}"
}

main "$@"
