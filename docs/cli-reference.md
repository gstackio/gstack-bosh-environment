# GBE Commands-Line reference

When you need inline help for a given command, adding the `-h` argument should
usually provide what you need. For example, help on `gbe up` can be obtained
with `gbe up -h`.


## BOSH environment commands

- `gbe up`: converges the infrastructure (i.e. a BOSH environment) towards
  its desired states. Note that `gbe converge` with no more arguments is an
  alias for `gbe up`.

- `gbe update <cloud-config|runtime-config>`: updates the cloud config or the
  runtime config of the BOSH environment.

- `gbe down`: deletes the Bosh environment and the related infrastructure.

- `gbe ssh`: logs into the Bosh environment VM with SSH

- `gbe ip`: outputs the main exernal IP address of the environment

- `gbe dns push `: converge DNS zone towards its desired state. This operation
  is one of the steps that `gbe up` performs.

- `gbe dns preview`: preview the changes that are required to be applied to
  the DNS zone in order to converge it towards its desired state.


## Managed deployments commands

- `gbe converge <some-subsys|all>`: converges one or all subsystems towards
  their desired states.

- `gbe recreate <some-subsys|all>`: recreates one or all subsystems
  towards their desired states.

- `gbe delete <some-subsys|all>`: deletes one or all BOSH deployments.

- `gbe <converge|delete> list`: lists the subsystems to be converged or
  deleted, in the order they will be treated. As the dependendy system is in
  its early stage, this can be useful to detect possible issues with the order
  in which `bosh-deployment`subsystems are converged.


## Compiled releases cache managemnt commands

- `gbe export`: popoulate the local cache with all compiled releases

- `gbe import`: import all compiled releases from the cache to the Bosh server

- `gbe cleanup`: delete stale compiled releases from the cache


## Setup

- `gbe env`: prints the envrionment variables that are necessary to use the
  `gbe` CLI. With Bash, this is usually used with the
  `source /dev/stdin <<<"$(./bin/gbe env)"` combo (which is mainly a
  workaround to circumvent a Bash bug). Note that these must be reloaded after
  creating the infrastructure with `gbe up`.

- `gbe gcp`: configures the Google Cloud credentials

- `gbe alias`: creates or re-creates the correct alias for the current BOSH
  environment.

- `gbe firewall`: configures the Google Cloud firewall rules

- `gbe tunnel start`: creates a SSH tunnel to enabling access the BOSH server,
  acting as a SOCKS5 proxy.

- `gbe tunnel stop`: stops the SSH tunnel.

- `gbe tunnel status`: show the status of the SSH tunnel.

- `gbe tunnel logs`: outputs the logs of the SSH command that has establised
  the SSH tunnel.


## Utilities setup

- `gbe bbl`: Installs locally the supported version of Bosh-Bootloader CLI

- `gbe cf`: Installs locally the supported version of Cloud Foundry CLI

- `gbe bosh`: Installs locally the supported version of Bosh CLI

- `gbe dnscontrol`: Installs locally the supported version of DNSControl CLI

- `gbe terraform`: Installs locally the supported version of Terraform CLI
