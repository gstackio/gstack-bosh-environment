
DNS_CREDS_FILE=dns/conf/creds.json

function has_dns_enabled() {
    [ -s "$BASE_DIR/$DNS_CREDS_FILE" ]
}

function render_dns_zone_config() {
    local state_dir external_ip dns_zone dns_subdomain

    state_dir=$(state_dir dns)
    mkdir -p "$state_dir"

    external_ip=$(external_ip)
    dns_zone=$(spec_var --required /dns/zone "$BASE_DIR/$GBE_ENVIRONMENT")
    dns_subdomain=$(spec_var --required /dns/subdomain "$BASE_DIR/$GBE_ENVIRONMENT")

    sed -e "s/EXTERNAL_IP/$external_ip/g; s/DNS_ZONE/$dns_zone/g; s/DNS_SUBDOMAIN/$dns_subdomain/g;" \
        "$BASE_DIR/dns/conf/zone-config-template.js" > "$state_dir/zone-config.js"
}

function preview_dns_config() {
    render_dns_zone_config

    assert_utilities dnscontrol "to preview DNS zone changes"

    dnscontrol preview \
        --creds "$BASE_DIR/$DNS_CREDS_FILE" \
        --config "$(state_dir dns)/zone-config.js"
    local status=$?

    if [ "$status" -eq 0 ]; then
        echo -e "\nIf the above is correct for you," \
            "then you can run '${BLUE}${BOLD}gbe dns push${RESET}' now.\n"
    fi
    exit $status
}

function push_dns_config() {
    render_dns_zone_config

    assert_utilities dnscontrol "to push DNS zone updates"

    dnscontrol push \
        --creds "$BASE_DIR/$DNS_CREDS_FILE" \
        --config "$(state_dir dns)/zone-config.js"
}

# Local Variables:
# indent-tabs-mode: nil
# End:
