
source "$BASE_DIR/lib/common.inc.bash"

function depl_var() {
    local path=$1

    bosh2 int "$DEPL_DIR/conf/depl-vars.yml" \
        --path "$path"
}

function bosh2_ro_invoke() {
    local verb=$1
    shift

    build_operations_arguments

    bosh2 "$verb" "$MAIN_DEPLOYMENT_FILE" \
        "${operations_arguments[@]}" \
        --vars-file "$DEPL_DIR/conf/depl-vars.yml" \
        "$@"
}

function bosh2_rw_invoke() {
    local verb=$1
    shift

    bosh2_ro_invoke "$verb" \
        --vars-store "$DEPL_DIR/state/depl-creds.yml" \
        "$@"
}
