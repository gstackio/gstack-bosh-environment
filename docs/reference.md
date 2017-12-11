# Reference documentation


## Directories structure in a GBE

The base directory describes the deployment of the BOSH server, and under
`deployments/`, several directories describe the deployments that are managed
by the BOSH server. As a general convention in those places, configuration is
located in `conf/`, BOSH v2 operation files are located in `operations/`, and
infrastructure state are in `state/`.

[Direnv](https://direnv.net/) is used all over the place, but has become
optional since the `gbe` CLI was introduced. The convention with `direnv` is
that when you enter a given directory, then the helper scripts located in the
`bin/` subdirectory are available on your path.

Direnv also provides many `bosh`-related environment variables depending on
the current working directory.

- When you are under the `deployments/` directory, then you are automagically
  connected to the bosh server. Any `bosh` commands will be aware of the
  correct credentials.

- When you are the subdirectory of a specific deployment, then all the
  deployment-related `bosh` commands will be aware of that and tharget *that*
  deployment.


## Configuration

### Configuring the base envrionment

As a general convention, configuration files are located in `conf/`
directories.

- In `env-config.inc.bash`, set a few variables and don't forget to re-run
  `direnv allow` after that.

  - Set `UPSTREAM_DEPLOYMENT_DIR` to be the path to the deployment repo clone,
    as mentioned above.

  - Set `MAIN_DEPLOYMENT_FILE` to point to the main deployment file, usually
    in the upstream deployment directory.

  - Set `BOSH_ENVIRONMENT` to be the alias of your BOSH environement, as you'll
    see it in `bosh environments` and in `-e` arguments to the BOSH CLI v2.

- In `env-infra-vars.yml` you set various GCP infrastructure settings for the
  BOSH environment.

- In `env-operations-layout.inc.bash` you can configure the set of operation
  files that will patch (using
  [go-patch](https://github.com/cppforlife/go-patch/blob/master/docs/examples.md))
  the main deployment file.

- In `depl-vars.yml` you set the configuration variables that will be
  injected into the patched deployment manifest for your BOSH environement.

### Configuring the managed deployments

Reminder: Deployments are located in subdirectories of `deployments/` and
their subdirectory name donesn't start with an underscore `_` character.

In deployments directories, the configuration is grouped into the
`conf/depl-vars.yaml` file.

The `upstream_base_deployment_manifests:` root YAML key describes where to
find the base deployment manifest, which is usually provided by a 3rd party in
a Git repository.

- The base deployment manifest is often provide by a 3rd party Git repository.
  In this case, the configuration is as follows.

  - `name`: a name for the upstream git repository, used when cloning it into
    GBE cache.

  - `git_repo`: a Git remote (usually a URL) that specifies where to fetch the
    Git repository.

  - `version`: anything that can be accepted by `git checkout` to fetch the
    correct revision of the git repository. E.g., a tag name or a Git hash.
    Branch name are possible but not recommended as it might change over time
    and thus break the reproductibility of your deployment.

  - `main_deployment_file`: the file name of the base deployment manifest,
    within the designated Git repository

- The base deployment manifest can be a plain file, provided in you GBE-based
  project.

  - `local_dir`: the directory (relative to the deployment directory) where to
    find the base manifest file.

  - `main_deployment_file`: the file name of the base deployment manifest.


## Usage workflow

### Basic usage

1. Create your environment with the `gbe up` command. (This is a compoound
   for `gbe bbl`, `gbe terraform`, `create-env`, and `gbe firewall`.)

3. Run `source /dev/stdin <<<"$(gbe env)"` (or go inside `deployments/`, when
   using Direnv) and play with your BOSH 2

   - If necessary, you can log into your BOSH Virtual Machine running `gbe ssh`
     or `jumpbox`.

4. Destroy your environment with `gbe down` (or `delete-env` when using
   Direnv).


### Advanced usage

1. Tweak your BOSH deployment, adding custom variables in `depl-vars.yml`,
   custom layout of operation files in `env-operations-layout.inc.bash`,
   possibly refering custom operation files in the `operation/` subdirectory.

2. Check the new setup interpolates nicely, running `verify-env`.

3. Go to [basic usage](#basic-usage) and have fun with your customized BOSH
   environment.


## How to get connected to the BOSH server

Either go inside the `deployments/` directory (when using `direnv`).

Or (when not using `direnv`) you can run `source /dev/stdin <<<"$(gbe env)"`
(in Bash), or the simpler `source <(gbe env)` in Zsh.


## A note on state and credentials files

State files are located in the `state/` directory. These are generated runtime
files. Some need to be tracked in version control, some not, and for some it
depends on the context.

As `bbl-state.json` and `depl-creds.yml` contain credentials, they are excluded
from version control, as you'll see in `.gitignore`.

On the opposite, `env-infra-state.json` doesn't contain credentials, but
identification data useful to manage the infrastructure of your BOSH
environment.

Generally, infrastructure state files are advised to be tracked by version
control when they refers to a perpetual environements, or environments that
don't change often. When they refer to ephemeral environements, then you can
exclude them from version control.

The `env-depl-manifest.yml` doesn't contain any credentials either. It
reflects the current state the superstructure of your BOSH environment. It is
to be tracked by version control.

The `jumpbox.key` is the private SSH key used to log into the BOSH server. Its
permissions are restricted and it is excluded from version control.


## Deployments

1. Configure your deployment config and operations layout in the
   `deployments/<deployment-name>/conf/` directory.

2. Run `gbe converge <deployment-name>`.

3. Play with your deployment.

4. Delete the deployment with `gbe delete <deployment-name>`.

### Direnv-based (alternate) workflow

1. Go inside a deployment directory.

2. Configure your deployment config, operations layout and deployment
   variables in the `conf/` directory.

3. Run `deploy`.

4. Play with your deployment.

5. Delete the deployment with `delete-deployment`.


## CF deployment notes

### A note on firewal rules

As a user, you only need to use `gbe firewall` in order to fix firewal rules,
and this is already done by `gbe up` for you. The rest of this section gives
you hints about what is actually done by the `gbe firewall` command.

With CF, you need to tweak the firewall rule in GCP to add ports
`80,443,2222,4443` to the list of allowed TCP ports.

To access Concourse, you'll need the `8080` port to be open. And for MySQL to
properly deploy, you'll need CF to be accessible.

All in all, you'll need to go to your GCP console, in “VPC Network” ›
“Firewall rules”, find the `bbl-env-*-bosh-open` rule and modify it
from `icmp; tcp:22,6868,25555` to
`icmp; tcp:22,80,443,2222,3306,4443,6868,8080,25555`.

### Set DNS wildcard

You'll need a DNS wildcard record for `*.((system_domain))` (the
`system_domain` is set in `depl-var.yml`) pointing to the address returned by:

    bosh int <(bbl --state-dir state bosh-deployment-vars) --path /external_ip

We suggest you use `dnscontrol` for keeping things “as-code”. You'll find a
`dnsconfig.js` example below.

```js
var REG_NONE = NewRegistrar('none', 'NONE');
var GANDI = NewDnsProvider("gandi", "GANDI");

D("example.com", REG_NONE, DnsProvider(GANDI),
    DefaultTTL('5m'),

    // Gstack GCP experiment
    A('cf', '35.189.75.199'),
    CNAME('*.cf', 'cf'),

    {'ns_ttl': '600'} // On domain apex NS RRs
)
```

Then running `dnscontrol preview` then `dnscontrol push` and you're good to
go.

### Targeting CF

Targeting the CF, you'll need to skip SSL validation.

    cf api --skip-ssl-validation https://api.$(bosh int "$DEPL_DIR/conf/depl-vars.yml" --path /system_domain)


## CF-MySQL deployment note

You'll need the DNS for CF to have *converged* before deploying CF-MySQL, as the
broker registrat will need the DNS name to register to CF.
