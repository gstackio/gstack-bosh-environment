local_operations=(
    set-versions
    expose-admin-user-as-link

    add-prometheus-uaa-clients # sym-linked from Prometheus release
    add-grafana-uaa-clients # sym-linked from Prometheus release
)
upstream_operations=(
    operations/bosh-lite
)
