#!/usr/bin/env bash

set -ueo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

function main() {
	local rabbitmq_config
    rabbitmq_config=$(sed -e '/^$/d ; /^ *%/d' "${SUBSYS_DIR}/conf/rabbitmq-server-config.erl" | base64)

    cat > "${SUBSYS_DIR}/features/set-rabbitmq-server-config.yml" <<EOF
---

- path: /instance_groups/name=rmq/jobs/name=rabbitmq-server/properties/rabbitmq-server/config?
  type: replace
  # NOTE: this is the base64-encoded content of the conf/rabbitmq-server-config.erl file
  value: "${rabbitmq_config}"
EOF
}

main "$@"
