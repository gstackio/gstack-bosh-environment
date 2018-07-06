
function jumpbox_key() {
    local env_state_dir
    env_state_dir=$(state_dir "$GBE_ENVIRONMENT")

    restrict_permissions "$env_state_dir/jumpbox.key"
    bosh int "$env_state_dir/depl-creds.yml" --path /jumpbox_ssh/private_key \
         > "$env_state_dir/jumpbox.key"
}

function jumpbox_ip() {
    reachable_ip_hook
}

function ssh_jumpbox() {
    local env_state_dir
    env_state_dir=$(state_dir "$GBE_ENVIRONMENT")

    if [[ ! -f $env_state_dir/depl-creds.yml ]]; then
        fatal "${RED}ERROR:$RESET the base BOSH environment is not created yet." \
             "Please create it first. Aborting." >&2
    fi

    # local timeout_arg
    # case $(platform) in
    #     darwin) timeout_arg=-t ;;
    #     linux)  timeout_arg=-W ;;
    # esac
    # local jumpbox_ip=$(jumpbox_ip)

    # # Wait for target to respond to ping
    # while ! ping -q -c 1 $timeout_arg 3 "$jumpbox_ip" > /dev/null; do
    #     echo "$(date +'%F %T') waiting $jumpbox_ip to respond to ping"
    #     sleep 2
    #     status=$?
    #     if [ "$status" -gt 128 ]; then
    #         # When interrupted by a signal, abort with same status
    #         exit $status
    #     fi
    # done

    jumpbox_key

    TERM=xterm-color ssh \
        -i "$env_state_dir/jumpbox.key" \
        "jumpbox@$(jumpbox_ip)" \
        "$@"
}


TUNNEL_PORT=5000

function has_tunnel() {
    local env_state_dir pid_file
    env_state_dir=$(state_dir "$GBE_ENVIRONMENT")
    pid_file=$env_state_dir/ssh-tunnel.pid
    [[ -s $pid_file ]] && ps -p "$( < "$pid_file" )" > /dev/null
}

function ensure_tunnel() {
    open_tunnel "$TUNNEL_PORT"
}

function open_tunnel() {
    local local_port=$1

    local env_state_dir pid_file
    env_state_dir=$(state_dir "$GBE_ENVIRONMENT")
    pid_file=$env_state_dir/ssh-tunnel.pid
    if has_tunnel; then
        return 0
    fi

    echo -e "\n${BLUE}Opening the ${BOLD}SSH tunnel$RESET that enables access to the BOSH server\n"

    jumpbox_key

    nohup ssh -4 -D "localhost:$local_port" -fNC \
            -i "$env_state_dir/jumpbox.key" "jumpbox@$(jumpbox_ip)" \
        > "$env_state_dir/ssh-tunnel.log"
    lsof -i ":$local_port" \
        | grep -E '^ssh\b' | awk '{print $2}' \
        > "$pid_file"

    # For any subsequent calls to 'bosh' CLI that rely on the tunnel, we now
    # set the BOSH_ALL_PROXY environment variable.
    export BOSH_ALL_PROXY=socks5://127.0.0.1:$TUNNEL_PORT
}

function start_tunnel() {
    local pid_file=$(state_dir "$GBE_ENVIRONMENT")/ssh-tunnel.pid
    if has_tunnel; then
        echo -e "\n${BLUE}SSH tunnel is ${BOLD}already running$RESET on PID '$(cat "$pid_file")'" \
             "(more info with ${UNDERLINE}lsof -i :$local_port$RESET)\n"
        return 1
    fi
    ensure_tunnel
    if [ "$BOSH_ALL_PROXY" != "socks5://127.0.0.1:$TUNNEL_PORT" ]; then
        echo
        echo "${BLUE}You must ${BOLD}refresh your environment variables${RESET} like this:"
        env_usage
    fi
}

function tunnel_status() {
    local env_state_dir pid_file
    env_state_dir=$(state_dir "$GBE_ENVIRONMENT")
    pid_file=$env_state_dir/ssh-tunnel.pid
    if ! has_tunnel; then
        echo -e "\nSSH tunnel is $RED${BOLD}not running$RESET\n"
    else
        echo -e "\nSSH tunnel is $GREEN${BOLD}is running$RESET on PID '$( < "$pid_file" )'\n"
        echo -e "${BOLD}Details:$RESET"
        lsof -i ":$TUNNEL_PORT"
        echo
    fi
}

function tunnel_logs() {
    local env_state_dir pid_file
    env_state_dir=$(state_dir "$GBE_ENVIRONMENT")

    echo -e "${BOLD}Last logs:$RESET"
    tail "$env_state_dir/ssh-tunnel.log"
}

function stop_tunnel() {
    local env_state_dir pid_file
    env_state_dir=$(state_dir "$GBE_ENVIRONMENT")
    pid_file=$env_state_dir/ssh-tunnel.pid

    if has_tunnel; then
        echo -e "\n${BLUE}Closing the ${BOLD}SSH tunnel$RESET that enables access to the Bosh server\n"
        kill "$( < "$pid_file" )"
    fi
    rm -f "$pid_file"
}

# Local Variables:
# indent-tabs-mode: nil
# End:
