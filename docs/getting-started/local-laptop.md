Deploying Easy Foundry locally on your laptop
=============================================

In this mode, you are running a Bash shell on a Linux or macOS system that we
call your “local machine”, and you are deploying on this same machine.


## Virtualbox prerequisites

1. An Ubuntu 16.04, or a recent macOS 10.12+ (Sierra) local machine.

    a. 16GB RAM

    b. A high bandwith network

2. These software installed on your local machine:

    a. Ansible 2.4

    b. [Bash 4.x+](../prerequisites/bash.md)

    c. [Ruby](../prerequisites/ruby.md)

    d. `jq` 1.5+ (with `apt install jq` or `brew install jq`)

    e. GNU Make 3.x+

    f. Git v2.x+ and the `git-lfs` extension


## Start your project

```bash
git clone https://github.com/gstackio/gstack-bosh-environment.git

cd gstack-bosh-environment/

source <(./bin/gbe env)
```


## Install Virtualbox

Install Virtualbox 5.2+. On macOS, run `brew cask install virtualbox` and on
Linux, [follow the documentation](https://www.virtualbox.org/wiki/Linux_Downloads).


#### Configure your BOSH environment

Select the `ddbox` environment.

```bash
export GBE_ENVIRONMENT=ddbox-env
```

Adjust the VM size for the “ddbox” environment.

```bash
$EDITOR ddbox-env/features/scale-vm-size.yml # set the number of CPUs to 4,
                                             # and VM memory size to 8000 MB
```

Edit the `ddbox-env` environment's `spec.yml` file.

```bash
$EDITOR ddbox-env/conf/spec.yml
```

And set the `dns` section like this:

```yaml
dns:
  zone: sslip.io
  subdomain: 192-168-50-6
```


## Converge the BOSH environment

```bash
source <(./bin/gbe env)  # add 'gbe' to the $PATH
gbe up
source <(./bin/gbe env)  # reload the updated environment variables
```

If necessary, this will install the supported versions of `bosh` and
`dnscontrol` or any other required utilities, as local binaries for your
project. And the necessary routing table entries will also be created, calling
`gbe routes` for you.


## Converge all infrastructure modules

There is a compound command for converging all Easy Foundry subsystems at
once.

```bash
gbe converge all
```

This command also imports any compiled BOSH Releases that might have been
saved with `gbe export` in order to save compilation time. Plea note that this
is a time saver only if your network bandwith is very high, though. If you
need to skip the `gbe import` step, you can use the alternative
`gbe converge deployments` compound command.

As an alternative, you can also run the `make all` target to converge all Easy
Foundry [infrastructure modules](../components.md).


## Destroy the BOSH environment (optional)

After having fun with Easy Foundry, if you ever needs to take the whole thing
down, you can delete the BOSH environment.

```bash
gbe down
```
