# Standard GBE CLI workflow

## Bootstrap a new GBE environment:

- `$GBE_ENVIRONMENT` is the environment variable used to designate the GBE
  environment that GBE should work with. Such an environment is made of a
  `bosh-environment`subsystem and its related `bosh-config`s subsystems for
  the cloud config and runtime config.

- `source /dev/stdin <<<"$(./bin/gbe env)"` to get the `gbe` CLI added to your
  shell `$PATH`.

- `gbe up` to converge the infrastructure.

- `source /dev/stdin <<<"$(./bin/gbe env)"` to load the new environment
  variables, that show up now that the BOSH environment is created.

- `gbe converge all`: to converge all `bosh-deployment` subsystems. Be careful
  that this needs 50+ GB RAM for the complete Easy Foundry environment. If you
  want to deploy only a subset of Easy Foundry, thes list the subsystems with
  `gbe converge list` and then deploy the subsystems you need with
  `gbe converge <subsys> -n`, one by one.


## Update an already existing GBE environment

- `gbe update <cloud-config|runtime-config>` when changes have been made to
  the cloud config or the runtime config.

- `gbe converge <subsys> -n` to converge a specific subsystem that has been
  modified.

- `gbe up` or `gbe converge` to converge GBE environment when its desired
  state has been modified.


## Destroy a GBE environment

- `gbe delete all` but this is currently optional, as `gbe down` will destroy
  all the `bosh-deployment`subsystems anyway.

- `gbe down` to delete the GBE environment altogether.
