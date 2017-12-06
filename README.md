GBE — Gstack BOSH Environment
=============================

This project establishes conventions and a simple workflow to help you create
and work with a BOSH v2
[environment](./docs/faq.md#what-do-you-mean-by-bosh-environment) along with
any [deployments](./docs/faq.md#how-is-a-bosh-deployment-described), whose
desired stated will be tracked in Git.

The GBE repository provides examples for deploying
[Concourse](https://concourse.ci), [Cloud Foundry](https://cloudfoundry.org),
and a typical [CF-MySQL](https://github.com/cloudfoundry/cf-mysql-release)
cluster that provides MySQL Database-as-a-Service to Cloud Foundry
applications.


[concourse-site]: <https://concourse.ci>
[cf-site]: <https://cloudfoundry.org>
[cf-mysql-repo]: <https://github.com/cloudfoundry/cf-mysql-release>
[osbapi-site]: <https://www.openservicebrokerapi.org>


What problems does GBE solve?
-----------------------------

We do believe that people need *structure* when dealing with BOSH manifests.

Usually operators that start creating a [BOSH environment](./docs/faq.md#what-do-you-mean-by-bosh-environment) have
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

[bosh_env_def]: <./docs/faq.md#what-do-you-mean-by-bosh-environment>
[dosh_depl_def]: <./docs/faq.md#how-is-a-bosh-deployment-described>


### What solutions does GBE bring?

The point with GBE is to follow an “infrastructure-as-code“ pattern where a
Git repository describes accurately the overall things that are deployed. BOSH
will take care for converging your actual infrastructure towards the
*desired state* that is described.

When it comes to starting this Git repository, GBE helps you organize and
version the different pieces in a meaningful and consistent manner. As the
*desired state* is also made of command-line arguments, GBE captures them in a
meneangful way that avoids duplication.

Consequently, GBE also provides you with simple compound commands that ease
the interactions involved when managing the filecycle of your BOSH environment
and its managed deployments.



Getting started
---------------

The idea is for you to clone the GBE repository, and use it as the base for
your project. There are some requisites to this, so please review them first.

Then go read the [reference documentation](./docs/reference.md) to get
familiar with the directory structure and conventions of GBE.


### Prerequisites

1. A high-bandwidth network access, for the machine that will run GBE.
   Especially a minimum of 50 Mbits/s when uploading to the cloud, giving
   approximatively 5 MB/s uploads.

2. Install the `gcloud` CLI utility, like `brew cask install google-cloud-sdk`
   on macOS. For other platforms, go read
   [this GCP documentation](https://cloud.google.com/sdk/downloads).

3. Create on Google Cloud an account and a project, then target those with
   `gcloud config set account ...` and  `gcloud config set project ...` and
   authenticate with `gcloud auth login`. Refer to `gcloud --help` if
   necessary.

4. Some version of Ruby is required, but not necessarily the latest. Usually
   `apt install ruby` is enough. (No need for
   [fancy install of latest Ruby](https://gorails.com/setup/ubuntu/16.04#ruby)
   involving `rbenv`.)

5. Installing `direnv` is optional. In case you do, run `brew install direnv`
   on macOS or `apt install direnv` on Ubuntu 16.04 or later. For other
   platforms, refer to
   [this Direnv documentation](https://github.com/direnv/direnv#install).

[bosh_cli_v2]: <https://github.com/cloudfoundry/bosh-cli>
[instal_cloud_sdk]: <https://cloud.google.com/sdk/downloads>
[install_direnv]: <https://github.com/direnv/direnv#install>


### Quick start

Here are the typical commands used to bootstrap your BOSH environment, then
deploy Concourse, Cloud Foundry and CF-MySQL with it.


#### 1. Start your project

```bash
git clone https://github.com/gstackio/gstack-bosh-environment.git my-project

cd my-project/

source /dev/stdin <<<"$(./bin/gbe env)" # a Bash workaround for: `source <(./bin/gbe env)`
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
The `conf/env-infra-vars.yml` file will also be updated with your specific GCP
project ID.


#### 3. Configure and create your BOSH environment

```bash
vi ./conf/env-infra-vars.yml # set GCP region & zone, and also check GCP project ID

gbe up
```

If necessary, this will install the supported versions of `bbl` and
`terraform`, as local binaries for your project. The necessary firewall rules
will also be set, calling `gbe firwall` for you.


#### 4. Converge your deployments

There is a compound command for converging all the deployments that are
defined in your project. By default, 3 of those are given as examples.

```bash
gbe converge all
```

This is basically all you need to do.

Or, you can run through converging these deployments one by one:

```bash
# Prepare the deployments
gbe update cloud-config
gbe udpate runtime-config

gbe converge concourse  # Deploy a Concourse CI server
gbe converge cf         # Deploy a simple Cloud Foundry platform.
gbe converge mysql      # Deploy the CF-MySQL DBaaS cluster
```


#### 5. Destroy the BOSH environment

When finished, you can delete the BOSH environment altogether.

```bash
gbe down
```



Other Documentation
-------------------

For more information, run `gbe help`.

- [How to tests the created deployments](./docs/deployments-tests.md)
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
