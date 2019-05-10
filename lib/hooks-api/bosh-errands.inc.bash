
function run_errand_with_retry_for_debugging() {
    local errand_name=$1; shift
    local errand_vm_name=$1; shift
    local errand_extra_args=("$@")

    local logs_dir
    logs_dir="${BASE_DIR}/logs/$(basename "${SUBSYS_DIR}")/${errand_name}"

    function errand_runner() {
        bosh run-errand "${errand_name}" "${errand_extra_args[@]}"
    }

    # When there's an error, we restart the smoke tests, collecting logs and
    # keeping the VM arround for debugging purpose.
    function debug_errand_runner() {
        mkdir -p "${logs_dir}"
        time bosh run-errand "${errand_name}" "${errand_extra_args[@]}" \
            --keep-alive --download-logs --logs-dir="${logs_dir}"
    }

    # Whenever the second try succeeds, we delete the collected logs and any
    # dedicated errand VM.
    function cleanup_debug_errand_run() {
        rm -r "${logs_dir}"
        if [[ -n "${errand_vm_name}" ]]; then
            bosh --non-interactive stop --hard "${errand_vm_name}"
        fi
    }

    run_scripts_with_retry_and_cleanup \
        "errand_runner" "debug_errand_runner" "cleanup_debug_errand_run"
}

function run_scripts_with_retry_and_cleanup() {
    local errand_runner_function=$1; shift
    local debug_errand_runner_function=$1; shift
    local cleanup_debug_errand_run_function=$1; shift

    local initial_xtrace initial_errexit error

    initial_errexit=$(tr -Cd "e" <<< "$-")
    if [[ -n $initial_errexit ]]; then set +e; fi
        initial_xtrace=$(tr -Cd "x" <<< "$-")
        if [[ -z "${initial_xtrace}" ]]; then set -x; fi
            "${errand_runner_function}"
            error=$?
        if [[ -z "${initial_xtrace}" ]]; then set +x; fi
    if [[ -n $initial_errexit ]]; then set -e; fi

    if [[ "${error}" -eq 0 ]]; then
        return 0
    fi

    initial_errexit=$(tr -Cd "e" <<< "$-")
    if [[ -n $initial_errexit ]]; then set +e; fi
        initial_xtrace=$(tr -Cd "x" <<< "$-")
        if [[ -z "${initial_xtrace}" ]]; then set -x; fi
            "${debug_errand_runner_function}"
            error=$?
        if [[ -z "${initial_xtrace}" ]]; then set +x; fi
    if [[ -n $initial_errexit ]]; then set -e; fi

    if [[ "${error}" -eq 0 ]]; then
        "${cleanup_debug_errand_run_function}"
    fi
    return "${error}"
}

