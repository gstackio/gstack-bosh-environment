
# Requires: 'common.inc.bash'

# ------------ #
# Dev releases #
# ------------ #

function delete_any_existing_unused_release() {
    local release_name=$1

    compute_existing_releases "${release_name}"
    for existing_release in "${existing_releases[@]}"; do
        # Don't delete release that are already used
        if [[ "${existing_release}" != *\* ]]; then
            bosh delete-release -n "${existing_release}"
        fi
    done
}

# This is typically used in a 'pre-deploy-once.sh' hook when any version of
# the release in the Director is fine, but whenever none exists, a dev release
# needs to be built from the git repo.
#
# This function can also be used in a 'pre-deploy.sh' hook due to the check of
# any release version in the Director.
#
function create_upload_dev_release_only_if_missing() {
    local input_resource_index=${1:-"0"}
    local release_name=$2
    local release_subdir_in_git=$3

    compute_existing_releases "$release_name"
    if [[ -n "${existing_releases_cache}" ]]; then
        return
    fi

    create_upload_dev_release_if_necessary \
        "${input_resource_index}" "${release_name}" "${release_subdir_in_git}"
}

existing_releases_cache=()
function compute_existing_releases() {
    local release_name=$1

    if [[ -n "${existing_releases_cache}" ]]; then
        return
    fi
    existing_releases_cache=(
        $(bosh releases --column "name" --column "version" \
            | awk "/^${release_name}[[:blank:]]/"'{print $1 "/" $2}')
    )
}

# This is typically used in two different situations:
#
# - In a 'pre-deploy-once.sh' hook when a dev release needs to be built from
#   the current Git branch (typically the 'master' branch) in order to ship
#   recent fixes.
#
# - In a 'pre-deploy.sh' hook when developing new features in a release, when
#   any new deploy needs to ship the most recent commits of the current Git
#   branch.
#
function create_upload_dev_release_if_necessary() {
    local input_resource_index=${1:-"0"}
    local release_name=$2
    local release_subdir_in_git=$3

    local rsc_name
    rsc_name=$(spec_var "/input_resources/${input_resource_index}/name")
    pushd "${BASE_DIR}/.cache/resources/${rsc_name}${release_subdir_in_git:+"/${release_subdir_in_git}"}" || return 115

        local latest_git_commit_hash
        latest_git_commit_hash=$(git rev-parse --short "HEAD")
        # Whenever there is already a release with the expected name and the
        # expected git commit hash, then we don't mind building or uploading
        # any dev release.
        set +o pipefail # because of the `bosh ... | grep -q ...` construct below
        if ! bosh releases --column "name" --column "commit_hash" \
                | grep -qE "${release_name}\\s+${latest_git_commit_hash}"; then

            create_dev_release_if_necessary_or_if_stale "${release_name}"

            local initial_xtrace
            initial_xtrace=$(tr -Cd "x" <<< "$-")
            if [[ -z "${initial_xtrace}" ]]; then set -x; fi
                bosh upload-release
            if [[ -z "${initial_xtrace}" ]]; then set +x; fi
        fi
    popd
}

function create_dev_release_if_necessary_or_if_stale() {
    local release_name=$1

    local create_dev_release latest_dev_release \
        latest_dev_release_commit_hash latest_git_commit_hash

    latest_dev_release=$(
        ls -t "dev_releases/${release_name}/${release_name}-"*.yml 2> /dev/null \
            | head -n 1
    )

    create_dev_release="false"
    if [[ -z "${latest_dev_release}" ]]; then
        create_dev_release="true"
    else
        latest_dev_release_commit_hash=$(bosh int "${latest_dev_release}" --path "/commit_hash")
        latest_git_commit_hash=$(git rev-parse --short "HEAD")
        if [[ "${latest_dev_release_commit_hash}" != "${latest_git_commit_hash}" ]]; then
            create_dev_release="true"
        fi
    fi

    if [[ "${create_dev_release}" == "true" ]]; then
        local initial_xtrace
        initial_xtrace=$(tr -Cd "x" <<< "$-")
        if [[ -z "${initial_xtrace}" ]]; then set -x; fi
            git submodule update --init --recursive

            # Note: we don't reset the release here because the storage cost of
            # building a dev release with the same blobs is very low, as only
            # what's different is sent and stored.

            if [[ -x "./scripts/add-blobs.sh" ]]; then
                ./scripts/add-blobs.sh
            fi

            bosh create-release --force
        if [[ -z "${initial_xtrace}" ]]; then set +x; fi
    fi
}

# -------------- #
# Final releases #
# -------------- #

function create_upload_final_release_if_missing() {
    local input_resource_index=${1:-"0"}
    local release_name=$2
    local release_version=$3

    if has_release_version "$release_name" "$release_version"; then
        return
    fi

    create_upload_final_release \
        "$input_resource_index" "$release_name" "$release_version"
}

function has_release_version() {
    local release_name=$1
    local release_version=$2

    bosh inspect-release "${release_name}/${release_version}" &> /dev/null
}

function create_upload_final_release() {
    local input_resource_index=$1
    local release_name=$2
    local release_version=$3

    local rsc_name
    rsc_name=$(spec_var "/input_resources/${input_resource_index}/name")
    pushd "$BASE_DIR/.cache/resources/${rsc_name}" || return 115
        local initial_xtrace
        initial_xtrace=$(tr -Cd "x" <<< "$-")
        if [[ -z "${initial_xtrace}" ]]; then set -x; fi
            # Note: when building a final release, we don't need any submodule
            bosh create-release "releases/${release_name}/${release_name}-${release_version}.yml"
            bosh upload-release
        if [[ -z "${initial_xtrace}" ]]; then set +x; fi
    popd
}
