# These operations files are relative to the 'operations' subdirectory here in
# this project. The '.yml' extension is implied.
local_operations=(
    enable-local-access
    inject-versions
)
# These operation files are relative to the UPSTREAM_DEPLOYMENT_DIR set in
# the '.envrc' config file. The '.yml' extension is implied.
upstream_operations=(
    gcp/cpi
    gcp/bosh-lite-vm-type
    bosh-lite
    bosh-lite-runc
    jumpbox-user
    external-ip-not-recommended
)
