GBE — Gstack BOSH Environment
=============================

This project establishes conventions and a simple workflow to help you create
and work with a BOSH v2 environment, whose desired stated will be tracked in
Git.

The GBE repository provides examples for deploying [Concourse](concourse-site),
[Cloud Foundry](cf-site), and a typical [CF-MySQL](cf-mysql-repo) cluster that
provides MySQL Database-as-a-Service thanks to the included
[service broker](osbapi-site).


[concourse-site]: https://concourse.ci/
[cf-site]: https://cloudfoundry.org
[cf-mysql-repo]: https://github.com/cloudfoundry/cf-mysql-release
[osbapi-site]: https://www.openservicebrokerapi.org/


What problems does GBE solve?
-----------------------------

We do believe that people need *structure* when dealing with BOSH manifests.

Usually operators that start creating a [BOSH environment](bosh_env_def) have
a rough and unclear view of the whole picture, because BOSH in new to them.
They have to write several pieces of YAML manifests and run `bosh` commands
with many arguments. As they are learning BOSH, it's hard for them to get
rapidly organized.

So, they start their project scattering the various pieces in an unorganized
manner. Once they start putting these into Git, it's hard for them to
reorganize the whole thing in a meaningful manner. They are lacking
recommendations and best practice at organizing BOSH manifests, Ops files, and
command arguments.

Then come day-2 concerns. Because [deployment](dosh_depl_def) manifests are in
most cases based on 3rd party base manifests, shipped in Git repositories.
They evolve along with the software that is deployed. And it's not
straightforward to track those 3rd-party base manifests and keep the process
easy when it comes to upgrading the software along with its base deployment
manifests. Should the base manifests be copied/pasted into the environment
repository? Should they be submoduled? Or kept aside, as separate Git clones?

Finally, the various BOSH v2 commands involved in day-to-day interactions with
a BOSH environment quickly tend to involve lots of arguments, which are
definitely part of the desired state of the environment. The usual way of
versionning these, is to use simple shell scripts. But this naive approach
creates duplication for commands that share similar and related sets of
arguments. In this regard, getting it right at avoiding duplication is not
easy.

[bosh_env_def]: #what-do-we-mean-by-bosh-environment
[dosh_depl_def]: #how-is-a-bosh-deployment-described


### What solution does GBE bring?

The point with GBE is to follow an “infrastructure-as-code“ pattern where a
Git repository describes accurately the overall environment that is deployed.
BOSH will take care for converging your actual infrastructure towards the
*desired state* that is described.

When it comes to starting this Git repository, GBE helps you organize and
version the different pieces in a meaningful and consistent manner. As the
*desired state* is also made of command-line arguments, GBE captures them in a
meneangful way that avoids duplication.

Consequently, GBE also provides you with simple compound commands that easy
the interaction involved when managing the filecycle of your BOSH environment
and its managed deployments.



Getting started
---------------

The idea is for you to clone the GBE repository, and use it as the base for
your project.

For this, there are several requisites that you need to check first.

Then you'll need to get familiar with the overall directory structure of GBE
and the implemented conventions.


### Prerequisites

- Install the [Bosh v2 CLI](bosh_cli_v2), like
  `brew install cloudfoundry/tap/bosh-cli` or anyhting similar.

- Install `direnv`. Like `brew install direnv` on macOS. For other platforms,
  refer to [this direnv documentation](install_direnv).

- Install the `gcloud` CLI utility, like `brew cask install google-cloud-sdk`
  on macOS. For other platforms, go read
  [this GCP documentation](instal_cloud_sdk).

[bosh_cli_v2]: https://github.com/cloudfoundry/bosh-cli
[install_direnv]: https://github.com/direnv/direnv#install
[instal_cloud_sdk]: https://cloud.google.com/sdk/downloads


### Quick start

Here are the typical commands used to bootstrap your BOSH environment, then
deploy Concourse, Cloud Foundry and CF-MySQL into it.


#### 1. Start your project and install prerequisites

```bash
git clone https://github.com/cloudfoundry/bosh-deployment.git
git clone https://github.com/gstackio/gstack-bosh-environment.git my-project

cd my-project/
direnv allow # if using direnv (recommended)
             # (the current state of .envrc will be permanently allowed)
# otherwise:
source <(gbe env) # (only if not using direnv)

gbe bbl       # installs bbl 3.2.6 locally in your GBE project
gbe terraform # installs Terraform v0.9.11 locally in your GBE project
```

#### 2. Configure GCP access

1. Pick your own service account name, instead of the example
   `my-service-account` below.

2. Get your project ID from Google Cloud, and use it instead of the example
   `alpha-sandbox-717101` below.

```bash
gbe gcp "my-service-account" "alpha-sandbox-717101"
```

This is a once-for-all setup that will create the private
`./conf/gcp-service-account.key.json` file
[as recommended](https://github.com/cloudfoundry/bosh-bootloader/tree/v3.2.6#configure-gcp).


#### 3. Configure and create your BOSH environment

Starting from here and after, you'll require `direnv` to be installed.

```bash
vi ./conf/env-config.inc.bash
direnv allow # (to refresh any values modified above)
vi ./conf/env-infra-vars.yml

gbe up
```

#### 4. Prepare the deployments

```bash
cd deployments/
direnv allow # (will be necessary only once in this directory)

# Now you're connected to your BOSH server as soon as you enter the
# 'deployments/' directory.

cd _cloud-config/
direnv allow # (will be necessary only once in this directory)
update-cloud-config

cd ../_runtime-config/
direnv allow # (will be necessary only once in this directory)
udpate-runtime-config
```

#### 5. Deploy the Concourse CI server

```bash
cd ../concourse/
direnv allow # (will be necessary only once in this directory)
upload-stemcell
deploy
```

#### 6. Deploy Cloud Foundry platform

```bash
cd ../cf/
direnv allow # (will be necessary only once in this directory)
upload-stemcell
deploy
```

#### 7. Deploy the CF-MySQL DBaaS

```bash
cd ../mysql/
direnv allow # (will be necessary only once in this directory)
upload-stemcell
deploy
```

#### 8. Destroy the BOSH environment

When finished, you can delete the BOSH environment altogether.

```bash
gbe down
```


Reference documentation
-----------------------


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


### How to configure

Configuration files are located in the `conf/` directory.

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


### Usage workflow

#### Basic usage

1. Create your environment with the `create-env` command.

2. Setup your shell with `source bin/shell-setup.inc.bash`.

3. Go inside `deployments/` and play with your BOSH 2

   - If necessary, you can log into your BOSH Virtual Machine running `jumpbox`.

4. Destroy your environment with the `delete-env` command.


#### Advanced usage

1. Tweak your BOSH deployment, adding custom variables in `env-depl-vars.yml`,
   custom layout of operation files in `env-operations-layout.inc.bash`,
   possibly refering custom operation files in the `operation/` subdirectory.

2. Check the new setup interpolates nicely, running `verify-env`.

3. Go to [basic usage](#basic-usage) and have fun with your customized BOSH
   environment.


### A note on state and credential files

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


### Deployments

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

#### Targeting CF

Targeting the CF, you'll need to skip SSL validation.

    cf api --skip-ssl-validation https://api.$(bosh int "$DEPL_DIR/conf/depl-vars.yml" --path /system_domain)


### CF-MySQL deployment note

You'll need the DNS for CF to have converged before deploying CF-MySQL, as the
broker registrat will need the DNS name to register to CF.



Frequently Asked Questions
--------------------------


### What do we mean by BOSH environment?

Working with BOSH, what we call an *environemnt* is the combination of these
components:

1. A BOSH server, who is responsible for driving an underlying automated
   infrastructure (most of the time a IaaS, many of those are supported).

2. One or many *deployments* (of distributed software), made on that uderlying
   infrastructure. The lifecycle of these deployments is fully managed by the
   BOSH server above. So that you rarely need interacting directly with the
   underlying infrastructure in your day-to-day work.

Tricky detail: the BOSH server above is itself described as a BOSH deployment,
that is managed by the `bosh` command-line tool, because it has the ability to
behave locally like a small BOSH server. This solves the chicken-and-egg
problem when it comes to deploying BOSH with BOSH.


### How is a BOSH deployment described?

With BOSH v2, your “infrastructure-as-code” is made of one or many
*deployments* and BOSH will take care for converging these towards a desired
state. Each of these desired states are composed of several pieces:

1. A base deployment manifest (usually provided by a 3rd party `*-deployment`
   Git repository).

2. Any standard set patches to be applied to the base deployment manifest,
   that will implement specific features that are relevant to your context.
   These are expressed as *operation files* (from the 3rd party `*-deployment`
   repository).

3. Possibly some custom operation files that you'll provide in order to
   implement non-standard variants to the base deployment.

4. Custom values for any variables that need being defined. These will be
   provided by you, and shall reflect your use-cases.

Those 4 types of pieces are tied toghether when they get passed as arguments
to the BOSH commands that are involved in the day-to-day work with the
deployments. In the end, these arguments are part of the desired state that
needs to be captured in Git.



Goals and limitations of the project
------------------------------------


### Other (non-trivial) goals for GBE

Note: GBE is work in progress and all these goals are not completely addressed
yet.

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


### Limitations

- Currently, only BOSH-Lite on GCP is supported as a target infrastructure.

- Upstream base deployment manifests are pointed to as directories where
  `*-deployment` repositories are checked out, but the exact versions of these
  repos are not pinned down by GBE, nor tracked in Git.

- GBE doesn't suggest yet an elegant way of expressing differences between
  environments.



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
