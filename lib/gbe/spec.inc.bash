
function spec_var() {
    local path=$1

    if [ -z "$SUBSYS_DIR" ]; then
        echo "ERROR: missing 'SUBSYS_DIR' variable. Aborting." >&2
        return 1
    fi

    bosh int "$SUBSYS_DIR/conf/spec.yml" \
        --path "$path" \
        2> /dev/null
}

function assert_subsys() {
    local expected_type=$1

    local subsys_type=$(spec_var /subsys/type)
    if [[ $subsys_type != $expected_type ]]; then
        local subsys_name=$(spec_var /subsys/name)
        echo "ERROR: expected subsystem '$subsys_name' to be of type '$expected_type'" \
         "but was '$subsys_type'. Aborting." >&2
        exit 1
    fi
}

function fetch_input_resources() {
    local subsys_spec=

    local rsc_count=$(spec_var /input_resources \
                         | awk '/^-/{print $1}' | wc -l)
    local rsc_idx=0
    while [[ $rsc_idx -lt $rsc_count ]]; do
        local rsc_path=/input_resources/$rsc_idx
        local rsc_type=$(spec_var "$rsc_path/type")
        case $rsc_type in
            git|local-dir)
                fetch_${rsc_type}_resource $rsc_path
                ;;
            *)
                echo "ERROR: unsupported resource type: '$rsc_type'" >&2
                return 1 ;;
        esac
        rsc_idx=$(($rsc_idx + 1))
    done
}

function fetch_git_resource() {
    local rsc_path=$1

    local rsc_name git_remote git_version cache_dir rsc_dir
    rsc_name=$(spec_var $rsc_path/name)
    git_remote=$(spec_var $rsc_path/uri)
    git_version=$(spec_var $rsc_path/version)

    cache_dir="$BASE_DIR/.cache/resources"
    rsc_dir=$cache_dir/$rsc_name
    if [ -d "$rsc_dir" ]; then
        pushd "$rsc_dir" > /dev/null || exit 115
            git fetch -q
        popd > /dev/null
    else
        mkdir -p "$cache_dir"
        git clone -q "$git_remote" "$rsc_dir" \
            || (echo "Error while cloning repository '$git_remote'" > /dev/stderr \
                && exit 1)
    fi
    pushd "$rsc_dir" > /dev/null || exit 115
        git checkout -q "$git_version" \
            || (echo "Error while checking out version '$git_version' of '$rsc_name'" > /dev/stderr \
                && exit 1)
    popd > /dev/null

    echo "$(spec_var "$rsc_path/name")@$(spec_var "$rsc_path/version")"
}

# This is just given as an example for implementing another resource type
function fetch_local-dir_resource() {
    echo "$(spec_var "$rsc_path/name")"
}

function read_bosh-environment_spec() {
    read_bosh-deployment_spec "$@"
}

function read_bosh-deployment_spec() {
    local rsc file dir
    rsc=$(spec_var /main_deployment_file | cut -d/ -f1)
    file=$(spec_var /main_deployment_file | cut -d/ -f2-)
    if [ "$rsc" == . ]; then
        dir=$SUBSYS_DIR
    else
        dir=$BASE_DIR/.cache/resources/$rsc
    fi
    MAIN_DEPLOYMENT_FILE=$dir/$file

    OPERATIONS_ARGUMENTS=()
    local op op_dir
    for rsc in $(spec_var /operations_files | awk -F: '/^[^-]/{print $1}'); do
        if [ "$rsc" == local ]; then
            op_dir=$SUBSYS_DIR/features
        else
            op_dir=$BASE_DIR/.cache/resources/$rsc
        fi
        for op in $(spec_var /operations_files/$rsc | cut -c3-); do
            OPERATIONS_ARGUMENTS+=(-o "$op_dir/${op}.yml")
        done
    done
}

function bosh_ro_invoke() {
    local verb=$1; shift

    bosh "$verb" "$MAIN_DEPLOYMENT_FILE" \
        "${OPERATIONS_ARGUMENTS[@]}" \
        --vars-file <(spec_var /deployment_vars) \
        "$@"
}

function bosh_rw_invoke() {
    local verb=$1; shift

    bosh_ro_invoke "$verb" \
        --vars-store "$(state_dir)/depl-creds.yml" \
        "$@"
}

function infra_bosh_ro_invoke() {
    local verb=$1; shift

    bosh_ro_invoke "$verb" \
        --vars-file <(spec_var /infra_vars) \
        "$@" \
        --vars-file <(spec_var /deployment_vars) # re-add it at the end, in order to override bbl defaults
}

function infra_bosh_rw_invoke() {
    local verb=$1; shift

    # Note: BBL's bosh-deployment-vars contain credentials. That's why
    # they are added here as --vars-file instead of in 'infra_bosh_ro_invoke()'
    infra_bosh_ro_invoke "$verb" \
        --vars-file <(bbl_invoke bosh-deployment-vars) \
        --vars-store "$(state_dir base-env)/depl-creds.yml" \
        --state "$(state_dir base-env)/env-infra-state.json" \
        "$@"
}

# Local Variables:
# indent-tabs-mode: nil
# End:
