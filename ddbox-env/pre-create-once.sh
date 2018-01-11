#!/usr/bin/env bash

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function spec_var() {
    local path=$1
    bosh int "$SUBSYS_DIR/conf/spec.yml" --path "$path"
}

ssh_key_base_filename=$SUBSYS_DIR/conf/id_rsa
remote_user=$(spec_var /deployment_vars/vbox_username)
remote_host=$(spec_var /deployment_vars/vbox_host)

if [ ! -f "$ssh_key_base_filename" ]; then
    ssh-keygen -b 4096 -N '' -C "boshinit@$(spec_var /subsys/name)" \
        -f "$ssh_key_base_filename"
fi
ssh-copy-id -i "${ssh_key_base_filename}.pub" "$remote_user@$remote_host"
