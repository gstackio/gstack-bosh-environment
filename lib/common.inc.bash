
function assert() {
    local dir_type=$1 # 'deployment', 'cloud-config' or 'runtime-config'
    local asserted_value=$2 # value not to be empty

    if [ -z "$asserted_value" ]; then
        echo "$(basename $0): ERROR: not in a $dir_type directory. Aborting." >&2
        exit 1
    fi
}

function restrict_permissions() {
    local filename=$1

    >> "$filename"
    chmod 600 "$filename"
}

function build_operations_arguments() {
    operations_arguments=()

    for op in "${upstream_operations[@]}"; do
        operations_arguments+=(-o "$UPSTREAM_DEPLOYMENT_DIR/$op.yml")
    done

    for op in "${local_operations[@]}"; do
        operations_arguments+=(-o "$DEPL_DIR/operations/$op.yml")
    done
}
