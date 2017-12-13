
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

function bosh_ro_invoke() {
    local verb=$1; shift

    build_operations_arguments

    bosh "$verb" "$MAIN_DEPLOYMENT_FILE" \
        "${operations_arguments[@]}" \
        --vars-file "$DEPL_DIR/conf/depl-vars.yml" \
        "$@"
}

function bosh_rw_invoke() {
    local verb=$1; shift

    bosh_ro_invoke "$verb" \
        --vars-store "$DEPL_DIR/state/depl-creds.yml" \
        "$@"
}

# Find a value in deployment configuration variables.
#
# Exits with status 0 in case a value is found, and the value is outputed to
# STDOUT.
#
# Exits with status 1 in case a value is not found and an empty string is
# outputed to STDOUT.
#
# In case you use a variable assignment like VAR=$(depl_var ...) then the non-
# zero exit status is not reflected in the $? variable.
function depl_var() {
    local path=$1

    bosh int "$DEPL_DIR/conf/depl-vars.yml" \
        --path "$path" \
        2> /dev/null
}

function fetch_ubdms() {
    local local_dir=$(depl_var "/upstream_base_deployment_manifests/local_dir")

    if [ -n "$local_dir" ]; then
        UPSTREAM_DEPLOYMENT_DIR=$DEPL_DIR/$local_dir
    else
        local ubdm_name=$(depl_var /upstream_base_deployment_manifests/name)
        local ubdm_remote=$(depl_var /upstream_base_deployment_manifests/git_repo)
        local ubdm_version=$(depl_var /upstream_base_deployment_manifests/version)

        local ubdms_dir="$BASE_DIR/.cache/ubdms"
        if [ -d "$ubdms_dir/$ubdm_name" ]; then
            pushd "$ubdms_dir/$ubdm_name" > /dev/null || exit 115
                git fetch -q
            popd > /dev/null
        else
            mkdir -p "$ubdms_dir"
            git clone -q "$ubdm_remote" "$ubdms_dir/$ubdm_name" \
                || (echo "Error while cloning repository '$ubdm_remote'" > /dev/stderr \
                    && exit 1)
        fi
        pushd "$ubdms_dir/$ubdm_name" > /dev/null || exit 115
            git checkout -q "$ubdm_version" \
                || (echo "Error while checking out version '$ubdm_version' of '$ubdm_name'" > /dev/stderr \
                    && exit 1)
        popd > /dev/null

        UPSTREAM_DEPLOYMENT_DIR=$ubdms_dir/$ubdm_name
    fi

    MAIN_DEPLOYMENT_FILE=$UPSTREAM_DEPLOYMENT_DIR/$(depl_var /upstream_base_deployment_manifests/main_deployment_file)
}