
function each_used_release() {
    local subsys=$1; shift
    local cmd=$1; shift

    local stemcell deployments_json deployments
    stemcell=$(bosh stemcells \
                | awk '{sub("\\*$", "", $2); print $3 "/" $2}' \
                | head -n1)
    deployments_json=$(bosh deployments --json)
    if [[ -z $subsys || $subsys == '*' ]]; then
        subsys=
        deployments=$(jq -nr "$deployments_json | .Tables[0].Rows[] | .name")
    else
        deployments=$(spec_var --required /deployment_vars/deployment_name "$BASE_DIR/deployments/$subsys")
    fi

    mkdir -p "$BASE_DIR/.cache/compiled-releases${subsys:+/$subsys}"
    pushd "$BASE_DIR/.cache/compiled-releases${subsys:+/$subsys}"

    for depl_name in $deployments; do

        depl_info_json=$(jq -n "$deployments_json | .Tables[0].Rows[] | select(.name == \"$depl_name\")")

        for release in $(jq -nr "$depl_info_json | .release_s"); do

            base_filename=$(echo "$release" | tr / -)-$(echo "$stemcell" | tr / -)

            "$cmd" "$depl_name" "$release" "$stemcell" "$base_filename" "$@"
        done
    done

    popd > /dev/null
}

function export_release_to_cache() {
    local depl_name=$1; shift
    local release=$1; shift
    local stemcell=$1; shift
    local base_filename=$1; shift

    if [[ -n $(find . -name "${base_filename}-*.tgz") ]]; then
        echo -e "\n${RED}Existing release$RESET $BOLD$BLUE$release$RESET" \
            "for stemcell $BOLD$GREEN$stemcell$RESET. Skipping.\n"
        return
    fi

    echo -e "\n${BLUE}Exporting release $BOLD$release$RESET" \
        "compiled on stemcell $GREEN$BOLD$stemcell$RESET\n"

    pushd "$BASE_DIR/.cache/compiled-releases"
        bosh -d "$depl_name" export-release "$release" "$stemcell"
    popd
}

function export_releases() {
    local subsys=$1
    assert_utilities jq "to export compiled releases"
    mkdir -p "$BASE_DIR/.cache/compiled-releases${subsys:+/$subsys}"
    each_used_release "$subsys" export_release_to_cache
}

function upload_compiled_releases() {
    local subsys=$1
    if [[ ! -d $BASE_DIR/.cache/compiled-releases ]]; then
        return
    fi
    echo -e "\n${BLUE}Uploading all ${BOLD}compiled releases$RESET found in cache to the BOSH server.\n"
    pushd "$BASE_DIR/.cache/compiled-releases"
        for compiled_release in $(find ${subsys:-.} -name '*.tgz' | sed -e 's`^./``'); do
            local release=$(echo "$compiled_release" | sed -e 's/^\([a-z-]*\)-\([0-9.]\{1,\}\)-.*$/\1\/\2/')
            local release_name=$(echo "$release" | cut -d/ -f1)
            local release_version=$(echo "$release" | cut -d/ -f2)
            echo -e "\n${BLUE}Uploading compiled release $BOLD$compiled_release$RESET\n"
            bosh -n upload-release --name="$release_name" --version="$release_version" "$compiled_release"
        done
    popd
}

function echo_stale_release_files() {
    local depl_name=$1; shift
    local release=$1; shift
    local stemcell=$1; shift
    local base_filename=$1; shift

    local release_name=$(echo "$release" | cut -d/ -f1)

    find . -type f -name "${release_name}*.tgz" \
        | sed -e 's`^\./``' \
        | grep -v "^$base_filename"
}

function cleanup_compiled_releases() {
    local dry_run_arg=$1 # '-n' or something

    assert_utilities jq "to cleanup compiled releases"
    pushd "$BASE_DIR/.cache/compiled-releases"
        declare -a stale_files
        stale_files=($(each_used_release '*' echo_stale_release_files))

        local bosh_version
        bosh_version=$(bosh env | tail -n +3 | head -n 1 | cut -d' ' -f1)
        stale_files+=($(find . -type f -name "bosh-*.tgz" \
                            | sed -e 's`^\./``' \
                            | grep -v "^bosh-${bosh_version}-"))

        if [[ ${#stale_files[@]} -le 0 ]]; then
            echo 0
        else
            du -sk "${stale_files[@]}"
        fi \
            | awk '{T+=$1} END{print "==> This operation is to free approximately " T/1024 " MiB of disk space."}'
        for f in "${stale_files[@]}"; do
            if [[ -n $dry_run_arg ]]; then
                echo "would remove: '$f'"
            else
                rm -v "$f"
            fi
        done
    popd
}

# Local Variables:
# indent-tabs-mode: nil
# End:
