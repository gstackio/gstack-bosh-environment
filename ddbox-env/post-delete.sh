#!/usr/bin/env bash

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function spec_var_optional() {
    local path=$1

    local initial_errexit=$(tr -Cd e <<< "$-")
    if [[ -n $initial_errexit ]]; then set +e; fi

    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path" 2> /dev/null

    if [[ -n $initial_errexit ]]; then set -e; fi
}

function spec_var_required() {
    local path=$1

    local initial_errexit=$(tr -Cd e <<< "$-")
    if [[ -n $initial_errexit ]]; then set +e; fi

    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path"
    return_status=$?
    if [[ $return_status -ne 0 ]]; then
        echo "${RED}ERROR:$RESET cannot find the required '$path' spec variable" \
            "in '$(basename "$SUBSYS_DIR")/conf/spec.yml' file. Aborting." >&2
    fi

    if [[ -n $initial_errexit ]]; then set -e; fi
    return $return_status
}

function sed_escape() {
    sed -e 's/[]\/$*.^[]/\\&/g' "$@"
}

set -eo pipefail

remote_host=$(spec_var_optional /deployment_vars/vbox_host | sed -e 's/^null$//')
if [[ -z $remote_host ]]; then
    exit 0
fi

ssh_key_base_filename=$SUBSYS_DIR/conf/id_rsa
remote_user=$(spec_var_required /deployment_vars/vbox_username)

ssh_public_key_pattern=$(awk '{print $2}' "${ssh_key_base_filename}.pub" \
    | sed_escape)

ssh "$remote_user@$remote_host" \
    "sed -i.bak '/$ssh_public_key_pattern/d' ~/.ssh/authorized_keys"
