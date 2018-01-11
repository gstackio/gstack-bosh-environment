#!/usr/bin/env bash

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function spec_var() {
    local path=$1
    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path"
}

function sed_escape() {
    sed -e 's/[]\/$*.^[]/\\&/g' "$@"
}

ssh_key_base_filename=$SUBSYS_DIR/conf/id_rsa
remote_user=$(spec_var /deployment_vars/vbox_username)
remote_host=$(spec_var /deployment_vars/vbox_host)

ssh_public_key_pattern=$(awk '{print $2}' "${ssh_key_base_filename}.pub" \
    | sed_escape)

ssh "$remote_user@$remote_host" \
    "sed -i.bak '/$ssh_public_key_pattern/d' ~/.ssh/authorized_keys"
