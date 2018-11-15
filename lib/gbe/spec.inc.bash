
function bbl_invoke() {
    bbl --state-dir "$(state_dir "$GBE_ENVIRONMENT")" "$@"
}

# Synopsis:
#   spec_var [--required] <path> [<subsys_dir>]
#
# --required
#   When specified, any missing value returns an error. Otherwise, missing
#   values are silently ignored and considered to be like an empty string.
#
# <path>
#   The YAML path of the spec var to fetch
#
# <subsys_dir> (optional)
#   A specific subsys directory where to find the spec.yml to consider.
#   If not specified, the $SPEC_FILE is considered, and if not defined, the
#   $SUBSYS_DIR is taken into consideration.
#
# External variables:
#   SUBSYS_DIR
#       The default subsys directory to use.
#   SPEC_FILE
#       The exact spec.yml file to operate on. This has a higher precedence
#       compared to $SUBSYS_DIR.
#       Defaults to '<subsys_dir>/conf/spec.yml'.
#
function spec_var() {
    local required
    if [[ $1 == --required ]]; then
        shift
        required=yes
    fi

    local path=$1
    local subsys_dir=$2

    local spec_file
    if [[ -n $subsys_dir ]]; then
        spec_file=$subsys_dir/conf/spec.yml
    elif [[ -n $SPEC_FILE ]]; then
        spec_file=$SPEC_FILE
    elif [[ -n $SUBSYS_DIR ]]; then
        spec_file=$SUBSYS_DIR/conf/spec.yml
    else
        echo "${RED}ERROR:$RESET cannot fetch '$path' spec var: missing" \
            "'SUBSYS_DIR' or 'SPEC_FILE' variable. Aborting." >&2
        return 1
    fi

    local initial_errexit=$(tr -Cd e <<< "$-")
    if [[ -n $initial_errexit ]]; then set +e; fi

    local return_status=0
    command=(bosh int --path "$path" "$spec_file")
    if [[ -n $required ]]; then
        "${command[@]}"
        return_status=$?
        if [[ $return_status -ne 0 ]]; then
            echo "${RED}ERROR:$RESET cannot find the required '$path' spec variable" \
                "in '${spec_file/#$BASE_DIR\//}' file. Aborting." >&2
        fi
    else
        "${command[@]}" 2> /dev/null
    fi

    if [[ -n $initial_errexit ]]; then set -e; fi
    return $return_status
}

function assert_subsys() {
    local expected_type=$1

    local subsys_type subsys_name
    subsys_type=$(spec_var /subsys/type)
    if [[ $subsys_type != $expected_type ]]; then
        subsys_name=$(spec_var /subsys/name)
        fatal "${RED}ERROR:$RESET expected subsystem '$subsys_name' to be" \
            "of type '$expected_type', but was '$subsys_type'. Aborting."
    fi
}

function fetch_input_resources() {
    local rsc_count rsc_idx rsc_path rsc_val rsc_type
    rsc_count=$(spec_var /input_resources | awk '/^-/{print $1}' \
                    | wc -l | tr -d ' ')
    rsc_idx=0
    while [[ $rsc_idx -lt $rsc_count ]]; do
        rsc_path=/input_resources/$rsc_idx
        rsc_val=$(spec_var "$rsc_path")
        if [[ $rsc_val == \(\(*\)\) ]]; then
            # Ignore spruce directives like ((merge)) or ((replace))
            rsc_idx=$(($rsc_idx + 1))
            continue
        fi
        rsc_type=$(spec_var --required "$rsc_path/type")
        case $rsc_type in
            git|local-dir|subsys-upstream)
                fetch_${rsc_type}_resource $rsc_path "$@"
                ;;
            *)
                echo "${RED}ERROR:$RESET unsupported resource type: '$rsc_type'. Aborting." >&2
                return 1 ;;
        esac
        rsc_idx=$(($rsc_idx + 1))
    done
}

UPSTREAM_RESOURCES=()

function fetch_subsys-upstream_resource() {
    local rsc_path=$1; shift

    fetch_git_resource "$rsc_path" "$@"

    local rsc_name
    rsc_name=$(spec_var --required "$rsc_path/name")

    UPSTREAM_RESOURCES+=("$rsc_name")
}

function fetch_git_resource() {
    local rsc_path=$1; shift

    local rsc_name git_remote git_version cache_dir rsc_dir
    rsc_name=$(spec_var --required "$rsc_path/name")
    git_remote=$(spec_var --required "$rsc_path/uri")
    git_version=$(spec_var --required "$rsc_path/version")

    cache_dir="$BASE_DIR/.cache/resources"
    rsc_dir=$cache_dir/$rsc_name
    if [[ -d $rsc_dir || -L $rsc_dir ]]; then
        pushd "$rsc_dir" > /dev/null || exit 115
            if [[ -n $(git remote) && $@ != *--offline* ]]; then
                git fetch -q
            fi
        popd > /dev/null
    else
        mkdir -p "$(dirname "$rsc_dir")"
        git clone -q "$git_remote" "$rsc_dir" \
            || (echo "Error while cloning repository '$git_remote'" > /dev/stderr \
                && exit 1)
    fi
    pushd "$rsc_dir" > /dev/null || exit 115
        git checkout -q "$git_version" \
            || (echo "Error while checking out version '$git_version' of '$rsc_name'" > /dev/stderr \
                && exit 1)
    popd > /dev/null

    echo "${rsc_name}@${git_version}"
}

# This is just given as an example for implementing another resource type
function fetch_local-dir_resource() {
    local rsc_name
    rsc_name=$(spec_var --required "$rsc_path/name")
    echo "$rsc_name"
}

function read_bosh-environment_spec() {
    read_bosh-deployment_spec "$@"
}

function expand_resource_dir() {
    local rsc_file=$1
    local subdir=$2

    local rsc file dir
    rsc=$(awk -F/ '{print $1}' <<< "$rsc_file")
    file=$(awk -F/ '{OFS="/"; $1=""; print substr($0,2)}' <<< "$rsc_file")
    if [[ $rsc == . || $rsc == local ]]; then
        dir=$SUBSYS_DIR${subdir:+/$subdir}
    else
        # local is_upstream=no
        # for upstream in "${UPSTREAM_RESOURCES[@]}"; do
        #     if [[ $rsc == $upstream ]]; then
        #         is_upstream=yes
        #         break
        #     fi
        # done
        dir=$BASE_DIR/.cache/resources/$rsc
        # if [[ $is_upstream == yes ]]; then
        #     rsc_file=$file

        #     rsc=$(awk -F/ '{print $1}' <<< "$rsc_file")
        #     file=$(awk -F/ '{OFS="/"; $1=""; print substr($0,2)}' <<< "$rsc_file")
        #     dir=$dir/.cache/resources/$rsc
        # fi
    fi
    echo "$dir${file:+/$file}"
}

function populate_operations_arguments() {
    OPERATIONS_ARGUMENTS=()

    local key rsc op_dir op_file
    for key in $(spec_var /operations_files | awk -F: '/^[^- #].*:/{print $1}'); do
        rsc=$(sed -e 's/^[[:digit:]]\{1,\}[-_]//' <<< "$key")
        op_dir=$(expand_resource_dir "$rsc" features)
        for op_file in $(spec_var --required "/operations_files/$key" | sed -e 's/^- //'); do
            OPERATIONS_ARGUMENTS+=(-o "$op_dir/${op_file}.yml")
        done
    done
}

function populate_vars_files_arguments() {
    VARS_FILES_ARGUMENTS=()
    local secrets_files=()

    local key rsc vars_file_dir files_count file_idx vars_file
    for key in $(spec_var /variables_files | awk -F: '/^[^- #].*:/{print $1}'); do
        rsc=$(sed -e 's/^[[:digit:]]\{1,\}[-_]//' <<< "$key")
        vars_file_dir=$(expand_resource_dir "$rsc" conf)

        files_count=$(spec_var "/variables_files/$key" | awk '/^-/{print $1}' \
                            | wc -l | tr -d ' ')
        file_idx=0
        while [[ $file_idx -lt $files_count ]]; do
            vars_file=$(spec_var "/variables_files/$key/$file_idx/file")
            if [[ $vars_file == *secrets* ]]; then
                secrets_files+=("$vars_file_dir/${vars_file}.yml")
            else
                VARS_FILES_ARGUMENTS+=(-l "$vars_file_dir/${vars_file}.yml")
            fi
            file_idx=$(($file_idx + 1))
        done
    done

    local dst_vars_store secrets_file var_value
    dst_vars_store=$(state_dir)/depl-creds.yml
    for secrets_file in "${secrets_files[@]}"; do
        for key in $(awk -F: '/^[^- #].*:/{print $1}' "$secrets_file"); do
            var_value=$(bosh int "$secrets_file" --path "/$key")
            merge_yaml_value_in_vars_file "$var_value" "$key" "$dst_vars_store"
        done
    done
}

function read_bosh-deployment_spec() {
    local depl_rsc_file
    depl_rsc_file=$(spec_var /main_deployment_file)
    if [[ -z $depl_rsc_file ]]; then
        echo "${RED}ERROR:$RESET missing 'main_deployment_file' in subsys spec." >&2
        return 1
    fi

    MAIN_DEPLOYMENT_FILE=$(expand_resource_dir "$depl_rsc_file")

    populate_operations_arguments
    populate_vars_files_arguments
}

function read_bosh-config_spec() {
    local config_rsc_file
    config_rsc_file=$(spec_var /main_config_file)
    if [[ -z $config_rsc_file ]]; then
        echo "${RED}ERROR:$RESET missing 'main_config_file' in subsys spec." >&2
        return 1
    fi
    MAIN_CONFIG_FILE=$(expand_resource_dir "$config_rsc_file")

    populate_operations_arguments
    populate_vars_files_arguments
}

function bosh_int_with_value() {
    local var_value=$1; shift
    if echo "$var_value" | grep -q ^-----BEGIN; then
        # Note: we use the --var-file form here, because it
        # supports structured data for certificates.
        bosh int --var-file var_value=<(echo -n "$var_value") "$@"
    else
        # Note: we use the --var form here, because we feed it
        # with a plain value, and not with structured YAML data.
        if [[ $var_value =~ ^[0-9.]+$ ]]; then
            # For values that can be interpreted as numeric, we are safe when
            # quoting it so that 'bosh int' makes a string of it
            bosh int --var "var_value='${var_value}'" "$@"
        else
            bosh int --var "var_value=${var_value}" "$@"
        fi
    fi
}

function import_file_value() {
    local base_path=$1
    local vars_file=$2

    local var_name var_value import_path
    var_name=$(spec_var "$base_path/name")
    var_value=$(spec_var "$base_path/value")
    import_path=$(spec_var "$base_path/path")
    if [[ -z $var_name ]]; then
        echo "${RED}ERROR:$RESET missing '$base_path/name' YAML node in subsys spec." >&2
        return 1
    fi
    if [[ -z $var_value && -z $import_path ]]; then
        echo "${RED}ERROR:$RESET either '$base_path/path' or '$base_path/value' YAML nodes" \
            "must be specified in subsys spec." >&2
        return 1
    fi

    if [[ -n $var_value ]]; then
        # FIXME: poor YAML escaping here below
        bosh int <(echo "$var_name: $var_value") \
            --vars-file "$vars_file"
    else
        var_value=$(bosh int "$vars_file" --path "$import_path")
        bosh_int_with_value "$var_value" <(echo "$var_name: ((var_value))")
    fi
}

function merge_yaml_value_in_vars_file() {
    local src_var_value=$1
    local dst_var_name=$2
    local dst_yaml_file=$3

    local tmp_file
    tmp_file=$(mktemp)
    if [[ ! -e $dst_yaml_file || ! -s $dst_yaml_file ]]; then
        # non existing or empty file: we need it to be an empty YAML hash
        echo '--- {}' >> "$dst_yaml_file"
    fi
    # Merge $var_value YAML node at the root level of the destination YAML
    # file (as designated by $dst_yaml_file) at key $dst_var_name
    bosh_int_with_value "$src_var_value" \
        --ops-file /dev/stdin \
        "$dst_yaml_file" \
        <<< "--- [ { path: '/${dst_var_name}?', value: ((var_value)), type: replace } ]" \
        > "$tmp_file"

    cp "$tmp_file" "$dst_yaml_file"
    rm -f "$tmp_file"
}

function import_state_value() {
    local subsys_name=$1
    local import_from=$2 # Base name of input YAML file, to be found in state
                         # dir of the subsystem designated by $subsys_name
    local base_path=$3
    local to_yaml_file=$4 # Absolute path the output YAML file

    local var_name var_value_tmpl import_path vars_file var_value
    var_name=$(spec_var "$base_path/name")
    var_value_tmpl=$(spec_var "$base_path/value")
    import_path=$(spec_var "$base_path/path")
    if [[ -z $var_name ]]; then
        echo "${RED}ERROR:$RESET missing '$base_path/name' YAML node in subsys spec." >&2
        return 1
    fi
    if [[ -z $var_value_tmpl && -z $import_path ]]; then
        echo "${RED}ERROR:$RESET either '$base_path/path' or '$base_path/value' YAML nodes" \
            "must be specified in subsys spec." >&2
        return 1
    fi

    vars_file=$(state_dir "$subsys_name")/${import_from}.yml

    if [[ -n $var_value_tmpl ]]; then
        if [[ -z $to_yaml_file ]]; then
            # FIXME: poor YAML escaping here below
            bosh int <(echo "$var_name: $var_value_tmpl") \
                --vars-file "$vars_file"
        else
            local tmp_file=$(mktemp)
            # Merge $var_value_tmpl YAML node (as the result of any variable
            # interpolation using the variables in $vars_file) at the root
            # level of the YAML file (as designated by $to_yaml_file) at key
            # $var_name
            #
            # FIXME: poor YAML escaping here below
            echo "--- [ { path: '/${var_name}?', value: $var_value_tmpl, type: replace } ]" \
                | bosh int \
                       --ops-file /dev/stdin \
                       --vars-file "$vars_file" \
                       "$to_yaml_file" \
                   > "$tmp_file"

            cp "$tmp_file" "$to_yaml_file"
            rm -f "$tmp_file"
        fi
        return
    fi

    var_value=$(bosh int "$vars_file" --path "$import_path")

    if [[ -z $to_yaml_file ]]; then
        bosh_int_with_value "$var_value" <(echo "$var_name: ((var_value))")
    else
        merge_yaml_value_in_vars_file "$var_value" "$var_name" "$to_yaml_file"
    fi
}

function get_subsys_dir_from_subsys_name() {
    local subsys_name=$1

    local subsys_dir
    if [[ $subsys_name == base-env ]]; then
        subsys_dir=$BASE_DIR/$GBE_ENVIRONMENT
    elif [[ $subsys_name == *-env || $subsys_name == dns ]]; then
        subsys_dir=$BASE_DIR/$subsys_name
    elif [[ $subsys_name == cloud-config || $subsys_name == runtime-config ]]; then
        subsys_dir=$BASE_DIR/$GBE_ENVIRONMENT/$subsys_name
    else
        subsys_dir=$BASE_DIR/deployments/$subsys_name
    fi
    echo "$subsys_dir"
}

function imports_from() {
    local subsys_name=$1
    local base_path=$2

    local subsys_dir vars_count var_idx var_path import_from
    subsys_dir=$(get_subsys_dir_from_subsys_name "$subsys_name")
    if [[ "$subsys_name" == base-env ]]; then
        subsys_name=$GBE_ENVIRONMENT
    fi

    vars_count=$(spec_var "$base_path" | awk '/^-/{print $1}' \
                        | wc -l | tr -d ' ')
    var_idx=0
    while [[ $var_idx -lt $vars_count ]]; do
        var_path=$base_path/$var_idx
        import_from=$(spec_var --required "$var_path/from")
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
                echo "${RED}ERROR:$RESET unsupported var import type: '$import_from'." \
                    "Expected 'bbl-vars', 'depl-vars', 'conf-vars', 'depl-manifest'," \
                    "or 'depl-creds'. Aborting." >&2
                return 1 ;;
        esac

        var_idx=$(($var_idx + 1))
    done
}

# CONCURRENCY WARNING: imported_vars() not only output variables, because
# credentials are actually written to the "$(state_dir)/depl-creds.yml" file.
function imported_vars() {
    local subsys_count idx subsys_path subsys_name
    subsys_count=$(spec_var /imported_vars | awk '/^-/{print $1}' \
                    | wc -l | tr -d ' ')
    idx=0
    while [[ $idx -lt $subsys_count ]]; do
        subsys_path=/imported_vars/$idx
        subsys_name=$(spec_var --required "$subsys_path/subsys")
        imports_from "$subsys_name" "$subsys_path/imports"
        idx=$(($idx + 1))
    done
}

function state_dir() {
    local gbe_subsys
    gbe_subsys=${1:-$(spec_var /subsys/name)}
    if [[ -z $gbe_subsys ]]; then
        echo "${RED}ERROR:$RESET missing subsys name. Aborting." >&2
        return 1
    fi
    echo "$BASE_DIR/state/$gbe_subsys"
}

function bosh_ro_invoke() {
    local verb=$1; shift

    bosh "$verb" "$MAIN_DEPLOYMENT_FILE" \
        "${OPERATIONS_ARGUMENTS[@]}" \
        "${VARS_FILES_ARGUMENTS[@]}" \
        --var "BASE_DIR=${BASE_DIR}" \
        --vars-file <(imported_vars) \
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
