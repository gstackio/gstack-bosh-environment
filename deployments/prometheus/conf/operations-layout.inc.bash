upstream_operations=(
    # Bosh monitoring
    manifests/operators/monitor-bosh
    manifests/operators/enable-bosh-uaa

    # CF monitoring
    manifests/operators/monitor-cf

    # CF integration
    manifests/operators/enable-cf-route-registrar
    manifests/operators/enable-grafana-uaa
)
local_operations=(
    set-versions
    # expose-ports
    customize-routing
)
