#!/usr/bin/env bash

set -eo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

source "${BASE_DIR}/lib/hooks-api/common.inc.bash"

function main() {
    local deployment_name
    deployment_name=$(own_spec_var "/deployment_vars/deployment_name")

    set -x \
        +o pipefail # because of the `bosh ... | grep -q ...` construct below

    if bosh deployments | grep -qE "\\b${deployment_name}\\b"; then
        bosh run-errand "broker-deregistrar" || true
    fi
}

main "$@"
