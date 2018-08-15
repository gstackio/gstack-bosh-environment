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

function cleanup() {
    if [[ -n $tmp_file ]]; then
        rm -f "$tmp_file"
        unset tmp_file
    fi
}

function yaml_upsert() {
    local dst_yaml_file=$1
    local dst_yaml_path=$2
    local src_value_file=$3

    local tmp_file
    tmp_file=$(mktemp)
    trap cleanup EXIT
    if [[ ! -e $dst_yaml_file || ! -s $dst_yaml_file ]]; then
        # non existing or empty file: we need it to be an empty YAML hash
        echo '--- {}' >> "$dst_yaml_file"
    fi
    bosh int --var-file var_value="$src_value_file" \
        --ops-file /dev/stdin \
        "$dst_yaml_file" \
        <<< "--- [ { path: '${dst_yaml_path}', value: ((var_value)), type: replace } ]" \
        > "$tmp_file"

    cp "$tmp_file" "$dst_yaml_file"
}

set -eo pipefail

remote_host=$(spec_var_optional /deployment_vars/vbox_host | sed -e 's/^null$//')
if [[ -z $remote_host ]]; then
    exit 0
fi

ssh_key_base_filename=$SUBSYS_DIR/conf/id_rsa
remote_user=$(spec_var_required /deployment_vars/vbox_username)

if [ ! -f "$ssh_key_base_filename" ]; then
    ssh-keygen -b 4096 -N '' -C "boshinit@$(spec_var_optional /subsys/name)" \
        -f "$ssh_key_base_filename"
fi
yaml_upsert "$SUBSYS_DIR/conf/private.yml" "/vbox_ssh?/private_key" \
    "$ssh_key_base_filename"
ssh-copy-id -i "${ssh_key_base_filename}.pub" "$remote_user@$remote_host"
