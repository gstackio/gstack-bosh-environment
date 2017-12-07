local_operations=(
    set-versions
    use-cf-admin-user-link
    inject-variables # must be after 'use-cf-admin-user-link'
    fix-broker-registrar-vm-names # must be last
)
upstream_operations=(
    operators/cf-integration
    operators/services/mysql56
    operators/services/postgresql96
    operators/services/redis32
)
