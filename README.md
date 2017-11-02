GBE — Gstack BOSH Environment
=============================

This project establishes conventions and an opinionated workflow to help
creating and interacting with BOSH v2 environments.

The idea is for you to clone this Git repository, and use its structure as the
base of your own BOSH deployments. Examples are included for deploying
Concourse, Cloud Foundry, and a classical CF-MySQL cluster with its Cloud
Foundry service broker.


### Main goals

- Be able to rebase deployment manifests customizations onto new versions of
  upstream base deployment manifests, when these happen to evolve over time.

- Be able to work several environments: sandox, ci-drone, pre-prod,
  production, etc. Elegantly express in separate places the configurations or
  layouts that are different, and factor all sources of deployment manifests
  for what is similar.

- Integrate with Continuous Integration and Continuous Deployment (CI & CD)
  workflows: changes to the deployed infrastructure are first tried by team
  members in personal sandbox environments, then deployed in a CI-driven ci-
  drone environment and thoroughly tested by CI with automated test suites,
  then continuously deployed in production.

Note: GBE is work in progress and all these goals are not completely addressed
yet.


### Directories structure in a GBE

The base directory describes the deployment of the BOSH server, and under
`deployments/`, several directories describe the deployments that are managed
by the BOSH server. As a general convention in those places, configuration is
located in `conf/`, BOSH v2 operation files are located in `operations/`, and
infrastructure state are in `state/`.

[Direnv](https://direnv.net/) is used all over the place. The convention is
that when you enter a given directory, then the helper scripts located in the
`bin/` subdirectory are available on your path. Direnv also provides many
wiring environment variables depending on where you are, i.e. what is your
current working directory. As an example, these environment variables have you
automatically connected to the BOSH server when you enter the `deployments/`
directory.


### Limitations

- Currently, only BOSH-Lite on GCP is supported as a target infrastructure.

- Upstream base deployment manifests are pointed to as directories where
  `*-deployment` repositories are checked out, but the exact versions of these
  repos are not pinned down by GBE, nor tracked in Git.

- GBE doesn't suggest yet an elegant way of expressing differences between
  environments.


Prerequisites
-------------

- Install the [bosh-cli](https://github.com/cloudfoundry/bosh-cli), like
  `brew install cloudfoundry/tap/bosh-cli` or anyhting similar.

- Install `direnv`. Like `brew install direnv` or anything similar.

- Clone the [bosh-deployment](https://github.com/cloudfoundry/bosh-deployment)
  repo, next to this one. Its path will be configured in
  `UPSTREAM_DEPLOYMENT_DIR`.

- Install [bbl](https://github.com/cloudfoundry/bosh-bootloader) v3, which is
  no more the simple `brew install cloudfoundry/tap/bbl` or similar way,
  sadly. Instead, you'll need to fetch the
  [v3.2.6 binary](https://github.com/cloudfoundry/bosh-bootloader/releases/tag/v3.2.6)
  manually and put it to the `bin/` subdir at the root of the project.

- Install the `gcloud` CLI utility, like `brew cask install google-cloud-sdk`
  or anything similar.

- Configure your GCP service account as in the
  [Configure GCP](https://github.com/cloudfoundry/bosh-bootloader#configure-gcp)
  section of the [bosh-bootloader](https://github.com/cloudfoundry/bosh-bootloader)
  README, so that you have a `<service account name>.key.json` file.


How to configure
----------------

Configuration files are located in the `conf/` directory.

- In `service-account.key.json`, you put your GCP service account key, as
  created above.
  Something like `mv <service account name>.key.json conf/service-account.key.json`
  and `chmod 600 service-account.key.json`.

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

- In `env-depl-vars.yml` you set the configuration variables that will be
  injected into the patched deployment manifest for your BOSH environement.


Usage workflow
--------------

### Basic usage

1. Create your environment with the `create-env` command.

2. Setup your shell with `source bin/shell-setup.inc.bash`.

3. Go inside `deployments/` and play with your BOSH 2

   - If necessary, you can log into your BOSH running `jumpbox`.

4. Destroy your environment with the `delete-env` command.


### Advanced usage

1. Tweak your BOSH deployment, adding custom variables in `env-depl-vars.yml`,
   custom layout of operation files in `env-operations-layout.inc.bash`,
   possibly refering custom operation files in the `operation/` subdirectory.

2. Check the new setup interpolates nicely, running `verify-env`.

3. Go to [basic usage](#basic-usage) and have fun with your customized BOSH
   environment.


A note on state and credential files
------------------------------------

State files are located in the `state/` directory. These are generated runtime
files. Some need to be tracked in version control, some not, and for some it
depends on the context.

As `bbl-state.json` and `env-creds.yml` contain credentials, they are excluded
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


Deployments
-----------

1. Go inside a deployment directory.

2. Configure your deployment config, operations layout and deployment
   variables in the `conf/` directory.

3. Run `deploy`.

4. Play with your deployment.

5. Delete the deployment with `delete-deployment`.


### CF deployment notes

#### Missing firewal rules

With CF, you need to tweak the firewall rule in GCP to add ports `80,443,2222`
to the list of allowed TCP ports.

#### Set DNS wildcard

You'll need a DNS wildcard record for `*.((system_domain))` (the
`system_domain` is set in `depl-var.yml`) pointing to the address returned by:

    bosh2 int <(bbl --state-dir state bosh-deployment-vars) --path /external_ip

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

#### Targeting CF

Targeting the CF, you'll need to skip SSL validation.

    cf api --skip-ssl-validation https://api.$(bosh2 int "$DEPL_DIR/conf/depl-vars.yml" --path /system_domain)


### CF-MySQL deployment note

You'll need the DNS for CF to have converged before deploying CF-MySQL, as the
broker registrat will need the DNS name to register to CF.


Contributing
------------

Please feel free to submit issues and pull requests.


Author and License
------------------

Copyright © 2017, Benjamin Gandon

Like the rest of BOSH, the Gstack BOSH environment is released under the terms
of the [Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0).

<!--
# Local Variables:
# indent-tabs-mode: nil
# End:
-->
