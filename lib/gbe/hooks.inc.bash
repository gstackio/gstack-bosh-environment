
function run_hook_once() {
    local name=$1; shift
    local script=$1; shift

    local state_file=$(state_dir)/$name-hook.yml
    if [ -f "$state_file" ] && grep -qF "status: success" "$state_file"; then
        return
    fi
    if [ ! -x "$script" ]; then
        return
    fi

    local initial_errexit=$(echo "$-" | sed -e 's/[^e]//g')
    if [ -n "$initial_errexit" ]; then set +e; fi
    run_hook "$script" "$@"
    local status=$?
    if [ -n "$initial_errexit" ]; then set -e; fi

    if [ "$status" -ne 0 ]; then
        return $status
    fi

    mkdir -p "$(dirname "$state_file")"
    (
        echo "status: success"
        echo "date: $(date -u +%FT%TZ)"
    ) > "$state_file"
}

function run_hook() {
    local script=$1; shift

    if [ ! -x "$script" ]; then
        return
    fi

    echo -e "\n${BLUE}Running hook $BOLD'$(basename "$script")'$RESET.\n"

    export BASE_DIR
    export GBE_ENVIRONMENT
    export SUBSYS_DIR
    "$script" "$@"
    return $? # to make it obvious that we want the exit status to propagate
}
