GBE — Gstack BOSH Environment
=============================

This project establishes conventions and a simple workflow to help you create
and work with a BOSH v2 environment, whose desired stated will be tracked in
Git.

The GBE repository provides examples for deploying [Concourse](https://concourse.ci),
[Cloud Foundry](https://cloudfoundry.org), and a typical [CF-MySQL](https://github.com/cloudfoundry/cf-mysql-release) cluster that
provides MySQL Database-as-a-Service thanks to the included
[service broker](https://www.openservicebrokerapi.org).


[concourse-site]: <https://concourse.ci>
[cf-site]: <https://cloudfoundry.org>
[cf-mysql-repo]: <https://github.com/cloudfoundry/cf-mysql-release>
[osbapi-site]: <https://www.openservicebrokerapi.org>


What problems does GBE solve?
-----------------------------

We do believe that people need *structure* when dealing with BOSH manifests.

Usually operators that start creating a [BOSH environment](./docs/faq.md#what-do-we-mean-by-bosh-environment) have
a rough and unclear view of the whole picture, because BOSH in new to them.
They have to write several pieces of YAML manifests and run `bosh` commands
with many arguments. As they are learning BOSH, it's hard for them to get
rapidly organized.

So, they start their project scattering the various pieces in an unorganized
manner. Once they start putting these into Git, it's hard for them to
reorganize the whole thing in a meaningful manner. They are lacking
recommendations and best practice at organizing BOSH manifests, Ops files, and
command arguments.

Then come day-2 concerns. Because [deployment](./docs/faq.md#how-is-a-bosh-deployment-described) manifests are in
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

[bosh_env_def]: <./docs/faq.md#what-do-we-mean-by-bosh-environment>
[dosh_depl_def]: <./docs/faq.md#how-is-a-bosh-deployment-described>


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

- Install the [Bosh v2 CLI](https://github.com/cloudfoundry/bosh-cli), like
  `brew install cloudfoundry/tap/bosh-cli` or anyhting similar.

- Install `direnv`. Like `brew install direnv` on macOS. For other platforms,
  refer to [this direnv documentation](https://github.com/direnv/direnv#install).

- Install the `gcloud` CLI utility, like `brew cask install google-cloud-sdk`
  on macOS. For other platforms, go read
  [this GCP documentation](https://cloud.google.com/sdk/downloads).

[bosh_cli_v2]: <https://github.com/cloudfoundry/bosh-cli>
[install_direnv]: <https://github.com/direnv/direnv#install>
[instal_cloud_sdk]: <https://cloud.google.com/sdk/downloads>


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


Other Documentation
-------------------

- [GBE reference documentation](./docs/reference.md)
- [GBE frequently asked questions](./docs/faq.md)
- [GBE goals and limitations](./docs/goals-limitations.md)



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
