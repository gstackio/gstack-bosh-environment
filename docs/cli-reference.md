# GBE Commands-Line reference

When you need inline help for a given command, adding the `-h` argument should
usually provide what you need. For example, help on `gbe up` can be obtained
with `gbe up -h`.


## BOSH environment commands

- `gbe up [--recreate]`: converges the infrastructure (i.e. a BOSH
  environment) towards its desired states. Note that `gbe converge` with no
  more arguments is an alias for `gbe up`.

- `gbe update [-y] <cloud-config|runtime-config> ...`: updates the cloud
  config or the runtime config of the BOSH environment.

- `gbe down`: deletes the BOSH environment and the related infrastructure.

- `gbe ssh`: logs into the BOSH environment VM with SSH

- `gbe ip`: outputs the main exernal IP address of the environment

- `gbe dns push `: converge DNS zone towards its desired state. This operation
  is one of the steps that `gbe up` performs.

- `gbe dns preview`: preview the changes that are required to be applied to
  the DNS zone in order to converge it towards its desired state.


## Managed deployments commands

- `gbe converge all`: converges all subsystems towards their desired states.
  Dependencies between subsystems are properly taken into consideration by
  this command.
  Any compiled release exported to the cache is imported too, but this might
  be reworked in future releases of GBE.

- `gbe converge deployments`: same as `gbe converge all`, but doesn't
  import any compiled release. (EXPERIMENTAL: this might be suppressed in
  future releases of GBE)

- `gbe converge [-y] <subsys> [<subsys> ...]`: converges one or many
  subsystems towards their desired states.

  With the `--manifest` option, only the deployment manifest and credentials
  are generated in the state directory, and the subsystem is not actually
  converged.

- `gbe recreate all`: recreates all subsystems at their desired state.

- `gbe recreate [-y] <subsys> [<subsys> ...]`: recreates one or many
  subsystems at their desired states.

- `gbe delete all`: deletes all infrastructure modules subsystems. This is
  very destructive, as all data is lost.

- `gbe delete [-y] <subsys> [<subsys> ...]`: deletes one or many
  infrastructure modules subsystems.

- `gbe <converge|delete> list`: lists the subsystems to be converged or
  deleted, in the order they will be treated. This shows how GBE treats
  the subsystems dependencies.


## Compiled releases cache managemnt commands

- `gbe export`: popoulate the local cache with all compiled BOSH Releases, in
  order to save compilation time for future convergence jobs.

- `gbe import`: import all compiled releases from the cache to the BOSH
  server.

- `gbe cleanup`: delete stale compiled releases from the cache. This command
  is experimental and might not provide expected result in some cases.


## Setup

- `gbe env`: prints the envrionment variables that are necessary to use the
  `gbe` CLI. With Bash, this is usually used with the
  `source <(./bin/gbe env)` command. Note that these must be reloaded after
  creating the infrastructure with `gbe up`.

- `gbe gcp`: configures the Google Cloud credentials.

- `gbe routes`: adds the necessary routing table entries for accessing the
  BOSH environment private network.

- `gbe alias`: creates or re-creates the correct alias for the current BOSH
  environment.

- `gbe bosh-installation`: shows the path where the `bosh` CLI has installed
  files for converging the BOSH environment. (EXPERIMENTAL: this might be
  suppressed in future releases of GBE)

- `gbe firewall`: configures the Google Cloud firewall rules

- `gbe tunnel start`: creates a SSH tunnel to enabling access the BOSH server,
  acting as a SOCKS5 proxy. (OUTDATED: this is to be reworked in future
  releases of GBE)

- `gbe tunnel stop`: stops the SSH tunnel. (OUTDATED: this is to be reworked
  in future releases of GBE)

- `gbe tunnel status`: show the status of the SSH tunnel. (OUTDATED: this is
  to be reworked in future releases of GBE)

- `gbe tunnel logs`: outputs the logs of the SSH command that has establised
  the SSH tunnel. (OUTDATED: this is to be reworked in future releases of GBE)


## Utilities setup

- `gbe bbl`: Installs locally the supported version of Bosh-Bootloader CLI

- `gbe bosh`: Installs locally the supported version of Bosh CLI

- `gbe cf`: Installs locally the supported version of Cloud Foundry CLI

- `gbe credhub`: Installs locally the supported version of CredHub CLI

- `gbe dnscontrol`: Installs locally the supported version of DNSControl CLI

- `gbe terraform`: Installs locally the supported version of Terraform CLI
