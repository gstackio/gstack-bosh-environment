
function bbl_invoke() {
    bbl --state-dir "$(state_dir "$GBE_ENVIRONMENT")" "$@"
}

function spec_var() {
    local path=$1
    local subsys_dir=${2:-$SUBSYS_DIR}

    if [ -z "$subsys_dir" ]; then
        echo "ERROR: cannot fetch '$path' spec var: missing 'SUBSYS_DIR' variable. Aborting." >&2
        return 1
    fi

    bosh int "$subsys_dir/conf/spec.yml" \
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
                echo "ERROR: unsupported resource type: '$rsc_type'. Aborting." >&2
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
    if [ -d "$rsc_dir" -o -L "$rsc_dir" ]; then
        pushd "$rsc_dir" > /dev/null || exit 115
            if [ -n "$(git remote)" ]; then
                git fetch -q
            fi
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

function expand_resource_dir() {
    local rsc_file=$1
    local subdir=$2

    local rsc file dir
    rsc=$(echo "$rsc_file" | awk -F/ '{print $1}')
    file=$(echo "$rsc_file" | awk -F/ '{OFS="/"; $1=""; print substr($0,2)}')
    if [[ $rsc == . || $rsc == local ]]; then
        dir=$SUBSYS_DIR${subdir:+/$subdir}
    else
        dir=$BASE_DIR/.cache/resources/$rsc
    fi
    echo "$dir${file:+/$file}"
}

function populate_operations_arguments() {
    OPERATIONS_ARGUMENTS=()

    local key rsc op_dir op_file
    for key in $(spec_var /operations_files | awk -F: '/^[^-]/{print $1}'); do
        rsc=$(echo "$key" | sed -e 's/^[[:digit:]]\{1,\}\.//')
        op_dir=$(expand_resource_dir "$rsc" features)
        for op_file in $(spec_var /operations_files/$key | sed -e 's/^- //'); do
            OPERATIONS_ARGUMENTS+=(-o "$op_dir/${op_file}.yml")
        done
    done
}

function read_bosh-deployment_spec() {
    local depl_rsc_file=$(spec_var /main_deployment_file)
    MAIN_DEPLOYMENT_FILE=$(expand_resource_dir "$depl_rsc_file")

    populate_operations_arguments
}

function read_bosh-config_spec() {
    local config_rsc_file=$(spec_var /main_config_file)
    MAIN_CONFIG_FILE=$(expand_resource_dir "$config_rsc_file")

    populate_operations_arguments
}

function import_file_value() {
    local base_path=$1
    local vars_file=$2

    local var_name=$(spec_var "$base_path/name")
    local var_value=$(spec_var "$base_path/value")
    local import_path=$(spec_var "$base_path/path")

    if [ -n "$var_value" ]; then
        # FIXME: poor YAML escaping here below
        bosh int <(echo "$var_name: $var_value") \
            --vars-file "$vars_file"
    else
        var_value=$(bosh int "$vars_file" --path "$import_path")
        if echo "$var_value" | grep -q ^-----BEGIN; then
            bosh int <(echo "$var_name: ((value))") --var-file value=<(echo "$var_value")
        else
            bosh int <(echo "$var_name: ((value))") --var value="$var_value"
        fi
    fi
}

function import_state_value() {
    local subsys_name=$1
    local import_from=$2
    local base_path=$3
    local to_yaml_file=$4

    local var_name=$(spec_var "$base_path/name")
    local import_path=$(spec_var "$base_path/path")

    local var_value=$(bosh int "$(state_dir "$subsys_name")/${import_from}.yml" \
        --path "$import_path")

    function bosh_int_with_value() {
        if echo "$var_value" | grep -q ^-----BEGIN; then
            # Note: we use the --var-file form here, because it
            # supports structured data for certificates.
            bosh int --var-file var_value=<(echo -n "$var_value") "$@"
        else
            # Note: we use the --var form here, because we feed it
            # with a plain value, and not with structured YAML data.
            bosh int --var var_value="$var_value" "$@"
        fi
    }

    if [ -z "$to_yaml_file" ]; then
        bosh_int_with_value <(echo "$var_name: ((var_value))")
    else
        local tmp_file=$(mktemp)

        echo "--- [ { path: '/${var_name}?', value: ((var_value)), type: replace } ]" \
            | bosh_int_with_value \
                   --ops-file /dev/stdin \
                   "$to_yaml_file" \
               > "$tmp_file"

        cp "$tmp_file" "$to_yaml_file"
        rm -f "$tmp_file"
    fi
}

function imports_from() {
    local subsys_name=$1
    local base_path=$2

    local subsys_dir
    if [[ "$subsys_name" == base-env || "$subsys_name" == dns ]]; then
        subsys_dir=$BASE_DIR/$subsys_name
    elif [[ "$subsys_name" == cloud-config || "$subsys_name" == runtime-config ]]; then
        subsys_dir=$BASE_DIR/$GBE_ENVIRONMENT/$subsys_name
    else
        subsys_dir=$BASE_DIR/deployments/$subsys_name
    fi
    if [[ "$subsys_name" == base-env ]]; then
        subsys_name=$GBE_ENVIRONMENT
    fi

    local vars_count=$(spec_var "$base_path" \
                         | awk '/^-/{print $1}' | wc -l)
    local var_idx=0
    while [[ $var_idx -lt $vars_count ]]; do
        local var_path=$base_path/$var_idx
        local import_from=$(spec_var "$var_path/from")
        case $import_from in
            bbl-vars)
                import_file_value "$var_path" \
                    <(extern_infra_vars_hook) ;;
            depl-vars)
                import_file_value "$var_path" \
                    <(spec_var /deployment_vars "$subsys_dir") ;;
            conf-vars)
                import_file_value "$var_path" \
                    <(spec_var /config_vars "$subsys_dir") ;;
            depl-manifest)
                import_state_value "$subsys_name" "$import_from" "$var_path" ;;
            depl-creds)
                import_state_value "$subsys_name" "$import_from" "$var_path" \
                    "$(state_dir)/depl-creds.yml"
                ;;
            *)
                echo "ERROR: unsupported var import type: '$import_from'." \
                    "Expected 'depl-vars', 'depl-manifest', or 'depl-creds'. Aborting." >&2
                return 1 ;;
        esac

        var_idx=$(($var_idx + 1))
    done
}

function imported_vars() {
    local subsys_count=$(spec_var /imported_vars \
                         | awk '/^-/{print $1}' | wc -l)
    local idx=0
    while [[ $idx -lt $subsys_count ]]; do
        local subsys_path=/imported_vars/$idx
        local subsys_name=$(spec_var "$subsys_path/subsys")
        imports_from "$subsys_name" "$subsys_path/imports"
        idx=$(($idx + 1))
    done
}

function state_dir() {
    local gbe_subsys=${1:-$(spec_var /subsys/name)}
    if [ -z "$gbe_subsys" ]; then
        echo "ERROR: missing subsys name. Aborting." >&2
        return 1
    fi
    echo "$BASE_DIR/state/$gbe_subsys"
}

function bosh_ro_invoke() {
    local verb=$1; shift

    bosh "$verb" "$MAIN_DEPLOYMENT_FILE" \
        "${OPERATIONS_ARGUMENTS[@]}" \
        --vars-file <(spec_var /deployment_vars) \
        --vars-file <(imported_vars) \
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
        --vars-file <(spec_var /deployment_vars) # re-add it at the end, in order to override any defaults from extern_infra_vars_hook()
}

function infra_bosh_rw_invoke() {
    local verb=$1; shift

    # Note: variables from infra_bosh_ro_invoke() may contain
    # credentials. That's why they are added here as --vars-file
    # instead of in 'infra_bosh_ro_invoke()'
    infra_bosh_ro_invoke "$verb" \
        --vars-file <(extern_infra_vars_hook) \
        --vars-store "$(state_dir "$GBE_ENVIRONMENT")/depl-creds.yml" \
        --state "$(state_dir "$GBE_ENVIRONMENT")/env-infra-state.json" \
        "$@"
}

# Local Variables:
# indent-tabs-mode: nil
# End:
