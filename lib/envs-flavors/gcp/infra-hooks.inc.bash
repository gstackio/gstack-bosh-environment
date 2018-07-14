#!/usr/bin/env bash

function internal_ip_hook() {
    bosh int <(bbl_invoke bosh-deployment-vars) --path /internal_ip
}

function external_ip_hook() {
    bosh int <(bbl_invoke bosh-deployment-vars) --path /external_ip
}

function reachable_ip_hook() {
    external_ip
}

function pre_create_env_hook() {
    echo -e "\n${BLUE}Running ${BOLD}bbl up$RESET to create infrastructure for the BOSH environment\n"

    local bbl_state_file=$(state_dir "$GBE_ENVIRONMENT")/bbl-state.json
    if [[ -f "$bbl_state_file" && ! -s "$bbl_state_file" ]]; then
        # State file might exist and be empty, in which case we must delete it
        # here as a safeguard
        rm -f "$bbl_state_file"
    fi
    local iaas region zone project_id
    iaas=$(spec_var --required /infra_vars/iaas)
    region=$(spec_var --required /infra_vars/region)
    zone=$(spec_var --required /infra_vars/zone)
    project_id=$(spec_var --required /infra_vars/project_id)
    bbl_invoke up \
        --iaas "$iaas" \
        --gcp-region "$region" \
        --gcp-zone "$zone" \
        --gcp-service-account-key "$BASE_DIR/$GBE_ENVIRONMENT/conf/gcp-service-account.key.json" \
        --gcp-project-id "$project_id" \
        --no-director

    # Ensure restricted permissions for state files containing sensitive
    # informations. Please not that 'bbl-state.json' must not be created before
    # invoking `bbl up`.
    restrict_permissions \
        "$bbl_state_file" \
        "$(state_dir "$GBE_ENVIRONMENT")/depl-creds.yml"


    # Proxy must not interfere when (re)creating the Bosh environment
    old_BOSH_ALL_PROXY=$BOSH_ALL_PROXY
    stop_tunnel > /dev/null
    unset BOSH_ALL_PROXY
}

function extern_infra_vars_hook() {
    # Note: BBL's bosh-deployment-vars contain credentials
    bbl_invoke bosh-deployment-vars
}

function post_create_env_hook() {
    # Restore any previous proxy setup, now that Bosh env is (re)created
    if [[ -n $old_BOSH_ALL_PROXY ]]; then
        export BOSH_ALL_PROXY=$old_BOSH_ALL_PROXY
        unset old_BOSH_ALL_PROXY
    fi
}

function ensure_reachability_hook() {
    ensure_tunnel
}

function cease_reachability_hook() {
    stop_tunnel
    unset BOSH_ALL_PROXY
}

function env_exports_hook() {
    echo "export BOSH_ALL_PROXY=socks5://127.0.0.1:$TUNNEL_PORT"
}

function setup_firewall_hook() {
    assert_utilities gcloud "to update firewall rules"

    local fw_rule_name
    fw_rule_name=$(bbl_invoke env-id)-bosh-open

    local allowed=icmp
    # Note: the 'gcloud' CLI v180.0.0 doesn't support the shorter syntax with
    #       semicolons, like "icmp; tcp:22,6868,25555". So we revert to the
    #       more verbose syntax here, e.g. "icmp,tcp:22,tcp:6868,tcp:25555".
    local bosh_ports="22 6868"
    local cf_ports="80 443 2222" # seems that 4443 is not used anymore, for good!
    local concourse_ports="8080"
    local mysql_ports="3306"
    local shield_ports="10443"
    local prometheus_ports="3000 9090 9093"
    for tcp_port in $bosh_ports $cf_ports $concourse_ports $mysql_ports \
                    $shield_ports $prometheus_ports; do
        allowed=$allowed,tcp:$tcp_port
    done

    echo -e "\n${BLUE}Updating ${BOLD}firewall rules$RESET in GCP.\n"
    gcloud compute firewall-rules update "$fw_rule_name" --allow="$allowed"
}

function pre_delete_env_hook() {
    :
}

function post_delete_env_hook() {
    if [[ x$1 == x-k ]]; then
        echo -e "\n${BLUE}Skipping ${BOLD}bbl destroy$RESET, as per user request\n"
    elif [[ ! -e $(state_dir "$GBE_ENVIRONMENT")/bbl-state.json ]]; then
        echo -e "\n${BLUE}Skipping ${BOLD}bbl destroy$RESET, as the 'state/bbl-state.json' file is absent\n"
    else
        echo -e "\n${BLUE}Running ${BOLD}bbl destroy$RESET to destroy infrastructure for the BOSH environment\n"
        bbl_invoke destroy --no-confirm --skip-if-missing
    fi
}

# Local Variables:
# indent-tabs-mode: nil
# End:
