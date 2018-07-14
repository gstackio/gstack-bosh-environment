#!/usr/bin/env bash

function env_depl_var() {
    local required
    if [[ $1 == --required ]]; then
        shift
        required=yes
    fi

    local depl_var_name=$1
    spec_var ${required:+--required} "/deployment_vars/$depl_var_name" "$BASE_DIR/$GBE_ENVIRONMENT"
}

function internal_ip_hook() {
    env_depl_var --required internal_ip
}

function external_ip_hook() {
    env_depl_var --required external_ip
}

function reachable_ip_hook() {
    internal_ip
}

function pre_create_env_hook() {
    echo -e "\n${BLUE}Provisionning ${BOLD}dedibox$RESET with pre-requisites for the Virtualbox infrastructure\n"

    pushd $BASE_DIR/ddbox-env/provision
        # ansible-playbook -i inventory.cfg --ask-become provision.yml
        echo skipped
    popd
}

function extern_infra_vars_hook() {
    local internal_ip
    internal_ip=$(env_depl_var --required internal_ip)
    echo "--- { internal_ip: \"$internal_ip\" }"
}

function post_create_env_hook() {
    :
}

function ensure_reachability_hook() {
    local vbox_host
    vbox_host=$(env_depl_var vbox_host | sed -e 's/^null$//')
    if [[ -z $vbox_host ]]; then
        # We need to add this route only when using a local virtualbox
        add_routes
    else
        : # ensure_sshuttle
    fi
}

function cease_reachability_hook() {
    local vbox_host
    vbox_host=$(env_depl_var vbox_host | sed -e 's/^null$//')
    if [[ -n $vbox_host ]]; then
        : # stop_sshuttle
    fi
}

function env_exports_hook() {
    echo "unset BOSH_ALL_PROXY"
}

function setup_firewall_hook() {
    assert_utilities jq vboxmanage "to update forwarded ports"

    local vboxmanage=vboxmanage
    local vbox_host
    vbox_host=$(env_depl_var vbox_host | sed -e 's/^null$//')
    if [[ -n $vbox_host ]]; then
        local vbox_username
        vbox_username=$(env_depl_var --required vbox_username)
        vboxmanage="ssh $vbox_username@$vbox_host vboxmanage"
    fi

    local vm_cid nic_num
    vm_cid=$(jq -r .current_vm_cid "$(state_dir "$GBE_ENVIRONMENT")/env-infra-state.json")
    nic_num=$($vboxmanage showvminfo "$vm_cid" | sed -ne 's/^NIC \([0-9]\{1,\}\):.* Attachment: NAT,.*/\1/p')

    function locate_nat_rule() {
        local chain=$1
        local uuid=$2

        ssh_jumpbox sudo iptables --line-numbers -t nat -nvL "$chain" \
            | grep -F "$uuid" | awk '{print $1}'
    }
    function set_nat_rule() {
        local chain=$1; shift
        local default_rule_index=$1; shift
        local uuid_comment=$1; shift

        local rule_index action
        if rule_index=$(locate_nat_rule "$chain" "$uuid_comment"); then
            action="-R"
        else
            rule_index=$default_rule_index
            action="-I"
        fi
        ssh_jumpbox sudo iptables -t nat "$action" "$chain" "$rule_index" \
            "$@" \
            -m comment --comment "$uuid_comment"
    }

    if [[ -z $nic_num ]]; then
        # Nothing to do when no NIC is attached to any NAT connection

        # FIXME: we now have some kludge shim here
        local external_ip web_router_ip internal_net_cidr rule_index
        external_ip=$(external_ip)
        web_router_ip=$(env_depl_var --required web_router_ip)
        internal_net_cidr=$(env_depl_var --required routable_network_cidr)

        set_nat_rule PREROUTING 2 "gbe[f55fc128-6cec-4f38-9303-2e45b0010c76]" \
            -i w+ -p tcp -d "$external_ip" --dport 80 \
            -j DNAT --to-dest "$web_router_ip"
        set_nat_rule PREROUTING 3 "gbe[f55fc128-6cec-4f38-9303-2e45b0010c77]" \
            -i w+ -p tcp -d "$external_ip" --dport 443 \
            -j DNAT --to-dest "$web_router_ip"

        set_nat_rule POSTROUTING 1 "gbe[f55fc128-6cec-4f38-9303-2e45b0010c78]" \
            -o w+ -p tcp -s "$internal_net_cidr" -d "$web_router_ip" --dport 80 \
            -j MASQUERADE
        set_nat_rule POSTROUTING 2 "gbe[f55fc128-6cec-4f38-9303-2e45b0010c79]" \
            -o w+ -p tcp -s "$internal_net_cidr" -d "$web_router_ip" --dport 443 \
            -j MASQUERADE

        return
    fi

    echo -e "\n${BLUE}Updating ${BOLD}forwarded ports$RESET in Virtualbox.\n"

    $vboxmanage showvminfo "$vm_cid" \
        | grep -E "^NIC ${nic_num} Rule\\([[:digit:]]+\\):.* name = tcp-pf-rule-[[:digit:]]+," \
        | awk '{print $6}' | tr -d , \
        | xargs -n 1 $vboxmanage controlvm "$vm_cid" "natpf$nic_num" delete

    local add_end_nl=false

    local bosh_ports=""
    local cf_ports="80 443 2222"
    local concourse_ports="8080"
    local mysql_ports="3306"
    local shield_ports="10443"
    local prometheus_ports="3000 9090 9093"
    for tcp_port in $bosh_ports $cf_ports $concourse_ports $mysql_ports \
                    $shield_ports $prometheus_ports; do
        if ! $vboxmanage showvminfo "$vm_cid" \
                | grep -qE "^NIC ${nic_num} Rule\\([[:digit:]]+\\):.*, guest port = $tcp_port\$"; then
            echo "  - $tcp_port"
            add_end_nl=true
            $vboxmanage controlvm "$vm_cid" "natpf$nic_num" tcp-pf-rule-$tcp_port,tcp,,$tcp_port,10.0.2.15,$tcp_port
        fi
    done
    if [[ $add_end_nl == true ]]; then
        echo
    fi
}

function pre_delete_env_hook() {
    :
}

function post_delete_env_hook() {
    :
}

# Local Variables:
# indent-tabs-mode: nil
# End:
