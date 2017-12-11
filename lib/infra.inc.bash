# We assume we have those variables set:
#  - BASE_DIR
#  - UPSTREAM_DEPLOYMENT_DIR
#  - MAIN_DEPLOYMENT_FILE
# These are typicaly set by the '.envrc' config file

DEPL_DIR=$BASE_DIR/base-env
source "$DEPL_DIR/conf/env-operations-layout.inc.bash"
source "$BASE_DIR/lib/common.inc.bash"

function infra_var() {
    local path=$1

    bosh int "$DEPL_DIR/conf/env-infra-vars.yml" \
        --path "$path"
}

function bbl_invoke() {
    bbl --state-dir "$BASE_DIR/state/base-env" "$@"
}

function infra_bosh_ro_invoke() {
    local verb=$1; shift

    bosh_ro_invoke "$verb" \
        --vars-file "$DEPL_DIR/conf/env-infra-vars.yml" \
        "$@" \
        --vars-file "$DEPL_DIR/conf/depl-vars.yml" # override bbl defaults
}

function infra_bosh_rw_invoke() {
    local verb=$1; shift

    infra_bosh_ro_invoke "$verb" \
        --vars-file <(bbl_invoke bosh-deployment-vars) \
        --vars-store "$BASE_DIR/state/base-env/depl-creds.yml" \
        --state "$BASE_DIR/state/base-env/env-infra-state.json" \
        "$@"
}

function assert_terraform_version() {
    if ! which terraform > /dev/null 2>&1; then
        echo "Warning: missing terraform. GBE requires version v0.9.11." >&2
        gbe terraform
        return
    fi

    local tf_version=$(terraform --version | head -n 1 | cut -d' ' -f2)

    if [[ ! $tf_version =~ ^v0\.9\..*$ ]]; then
        echo "Warning: unsupported terraform version '$tf_version'." \
            "GBE requires version v0.9.11." >&2
        gbe terraform
        return
    fi
}

function assert_bbl_version() {
    if ! which bbl > /dev/null 2>&1; then
        echo "Warning: missing bbl. GBE requires version 3.2.6." >&2
        gbe bbl
        return
    fi

    local bbl_version=$(bbl --version | head -n 1 | cut -d' ' -f2)

    if [[ ! $bbl_version =~ ^3\..*\..*$ ]]; then
        echo "Warning: unsupported bbl version '$bbl_version'." \
            "GBE requires version 3.2.6." >&2
        gbe bbl
        return
    fi
}
