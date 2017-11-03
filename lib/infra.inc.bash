# We assume we have those variables set:
#  - BASE_DIR
#  - UPSTREAM_DEPLOYMENT_DIR
#  - MAIN_DEPLOYMENT_FILE
# These are typicaly set by the '.envrc' config file

source "$BASE_DIR/conf/env-operations-layout.inc.bash"
DEPL_DIR=$BASE_DIR
source "$BASE_DIR/lib/common.inc.bash"

function infra_var() {
    local path=$1

    bosh int "$BASE_DIR/conf/env-infra-vars.yml" \
        --path "$path"
}

function bbl_invoke() {
    bbl --state-dir "$BASE_DIR/state" "$@"
}

function bosh_ro_invoke() {
    local verb=$1
    shift

    build_operations_arguments

    bosh "$verb" "$MAIN_DEPLOYMENT_FILE" \
        "${operations_arguments[@]}" \
        --vars-file "$BASE_DIR/conf/env-infra-vars.yml" \
        "$@" \
        --vars-file "$BASE_DIR/conf/env-depl-vars.yml" # override bbl defaults
}

function bosh_rw_invoke() {
    local verb=$1
    shift

    bosh_ro_invoke "$verb" \
        --vars-file <(bbl_invoke bosh-deployment-vars) \
        --vars-store "$BASE_DIR/state/env-creds.yml" \
        --state "$BASE_DIR/state/env-infra-state.json" \
        "$@"
}

function assert_terraform_version() {
    if ! which terraform > /dev/null 2>&1; then
        echo "Error: missing terraform. Please install version v0.9.11 first." >&2
        exit 1
    fi

    local tf_version=$(terraform --version | head -n 1 | cut -d' ' -f2)

    if [[ ! $tf_version =~ ^v0\.9\..*$ ]]; then
        echo "Error: unsupported terraform version '$tf_version'." \
            "Please use terraform v0.9.11 instead." >&2
        exit 1
    fi
}

function assert_bbl_version() {
    if ! which bbl > /dev/null 2>&1; then
        echo "Error: missing bbl. Please install version 3.2.6 first." >&2
        exit 1
    fi

    local bbl_version=$(bbl --version | head -n 1 | cut -d' ' -f2)

    if [[ ! $bbl_version =~ ^3\..*\..*$ ]]; then
        echo "Error: unsupported bbl version '$bbl_version'." \
            "Please use bbl 3.2.6 instead." >&2
        exit 1
    fi
}
