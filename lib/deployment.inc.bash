
source "$BASE_DIR/lib/common.inc.bash"

function bosh_ro_invoke() {
    local verb=$1
    shift

    build_operations_arguments

    bosh "$verb" "$MAIN_DEPLOYMENT_FILE" \
        "${operations_arguments[@]}" \
        --vars-file "$DEPL_DIR/conf/depl-vars.yml" \
        "$@"
}

function bosh_rw_invoke() {
    local verb=$1
    shift

    bosh_ro_invoke "$verb" \
        --vars-store "$DEPL_DIR/state/depl-creds.yml" \
        "$@"
}
