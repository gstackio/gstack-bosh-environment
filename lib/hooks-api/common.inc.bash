
function own_spec_var() {
    local path=$1
    bosh int "${SUBSYS_DIR}/conf/spec.yml" --path "${path}"
}

function spec_var() {
    local path=$1

    local has_upstream
    has_upstream=$(own_spec_var "/subsys/upstream" 2> /dev/null || true)
    if [[ -n "${has_upstream}" ]]; then
        state_var "merged-spec" "${path}"
    else
        own_spec_var "${path}"
    fi
}

function state_var() {
    local state_file=$1
    local path=$2
    bosh int "${BASE_DIR}/state/${SUBSYS_NAME}/${state_file}.yml" --path "${path}"
}

function runtime_config_var() {
    local path=$1
    bosh int "${BASE_DIR}/${GBE_ENVIRONMENT}/runtime-config/conf/spec.yml" \
        --path "/config_vars${path}"
}

SUBSYS_NAME=${SUBSYS_NAME:-$(own_spec_var /subsys/name)}
