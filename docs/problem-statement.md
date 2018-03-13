
This project establishes conventions and a simple workflow to help you create
and work with a BOSH v2
[environment](./docs/faq.md#what-do-you-mean-by-bosh-environment) along with
any [deployments](./docs/faq.md#how-is-a-bosh-deployment-described), whose
desired state will be tracked in Git.

The GBE repository provides examples for deploying
[Concourse](https://concourse.ci), [Cloud Foundry](https://cloudfoundry.org),
and a typical [CF-MySQL](https://github.com/cloudfoundry/cf-mysql-release)
cluster that provides MySQL Database-as-a-Service to Cloud Foundry
applications.


[concourse-site]: <https://concourse.ci>
[cf-site]: <https://cloudfoundry.org>
[cf-mysql-repo]: <https://github.com/cloudfoundry/cf-mysql-release>
[osbapi-site]: <https://www.openservicebrokerapi.org>

## What problems was GBE initially meant to solve?

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


## What solutions does GBE bring?

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
