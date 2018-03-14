#!/usr/bin/env bash

function internal_ip_hook() {
    spec_var /deployment_vars/internal_ip "$BASE_DIR/$GBE_ENVIRONMENT"
}

function external_ip_hook() {
    spec_var /deployment_vars/external_ip "$BASE_DIR/$GBE_ENVIRONMENT"
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
    local internal_ip=$(spec_var /deployment_vars/internal_ip "$BASE_DIR/$GBE_ENVIRONMENT")
    echo "--- { internal_ip: \"$internal_ip\" }"
}

function post_create_env_hook() {
    :
}

function ensure_reachability_hook() {
	add_routes
}

function env_exports_hook() {
	echo "unset BOSH_ALL_PROXY"
}

function setup_firewall_hook() {
    assert_utilities jq vboxmanage "to update forwarded ports"

    local vm_cid nic_num
    vm_cid=$(jq -r .current_vm_cid "$(state_dir "$GBE_ENVIRONMENT")/env-infra-state.json")
    nic_num=$(vboxmanage showvminfo "$vm_cid" | sed -ne 's/^NIC \([0-9]\{1,\}\):.* Attachment: NAT,.*/\1/p')

    if [ -z "$nic_num" ]; then
        # Nothing to do when no NIC is attached to any NAT connection

        # FIXME: we now have some kludge shim here
        local external_ip=$(external_ip)
        local traefik_ip=10.244.0.34
        local default_network=10.244.0.0/20
        if ! gbe ssh sudo iptables -t nat -nvL | grep -qF gbe[f55fc128-6cec-4f38-9303-2e45b0010c76]; then
            gbe ssh sudo iptables -t nat -I PREROUTING 2 -i w+ -p tcp -d "$external_ip" --dport 80 -j DNAT --to-dest "$traefik_ip" -m comment --comment "gbe[f55fc128-6cec-4f38-9303-2e45b0010c76]"
        fi
        if ! gbe ssh sudo iptables -t nat -nvL | grep -qF gbe[f55fc128-6cec-4f38-9303-2e45b0010c77]; then
            gbe ssh sudo iptables -t nat -I PREROUTING 3 -i w+ -p tcp -d "$external_ip" --dport 443 -j DNAT --to-dest "$traefik_ip" -m comment --comment "gbe[f55fc128-6cec-4f38-9303-2e45b0010c77]"

        fi
        if ! gbe ssh sudo iptables -t nat -nvL | grep -qF gbe[f55fc128-6cec-4f38-9303-2e45b0010c78]; then
            gbe ssh sudo iptables -t nat -I POSTROUTING 1 -o w+ -p tcp -s "$default_network" -d "$traefik_ip" --dport 80 -j MASQUERADE -m comment --comment "gbe[f55fc128-6cec-4f38-9303-2e45b0010c78]"
        fi
        if ! gbe ssh sudo iptables -t nat -nvL | grep -qF gbe[f55fc128-6cec-4f38-9303-2e45b0010c79]; then
            gbe ssh sudo iptables -t nat -I POSTROUTING 2 -o w+ -p tcp -s "$default_network" -d "$traefik_ip" --dport 443 -j MASQUERADE -m comment --comment "gbe[f55fc128-6cec-4f38-9303-2e45b0010c79]"
        fi

        return
    fi

    echo -e "\n${BLUE}Updating ${BOLD}forwarded ports$RESET in Virtualbox.\n"

    vboxmanage showvminfo "$vm_cid" \
        | grep -E "^NIC ${nic_num} Rule\\([[:digit:]]+\\):.* name = tcp-pf-rule-[[:digit:]]+," \
        | awk '{print $6}' | tr -d , \
        | xargs -n 1 vboxmanage controlvm "$vm_cid" "natpf$nic_num" delete

    local add_end_nl=false

    local bosh_ports=""
    local cf_ports="80 443 2222"
    local concourse_ports="8080"
    local mysql_ports="3306"
    local shield_ports="10443"
    local prometheus_ports="3000 9090 9093"
    for tcp_port in $bosh_ports $cf_ports $concourse_ports $mysql_ports \
                    $shield_ports $prometheus_ports; do
        if ! vboxmanage showvminfo "$vm_cid" \
                | grep -qE "^NIC ${nic_num} Rule\\([[:digit:]]+\\):.*, guest port = $tcp_port\$"; then
            echo "  - $tcp_port"
            add_end_nl=true
            vboxmanage controlvm "$vm_cid" "natpf$nic_num" tcp-pf-rule-$tcp_port,tcp,,$tcp_port,10.0.2.15,$tcp_port
        fi
    done
    if [ "$add_end_nl" == true ]; then
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
