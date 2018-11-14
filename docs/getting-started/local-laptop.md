Deploying Easy Foundry locally on a laptop
==========================================

In this mode, we are running a Bash shell on a Linux or macOS system that we
call our “local machine”, and we are deploying on this same machine.


## Prerequisites

1. An Ubuntu 16.04, or a recent macOS 10.12+ (Sierra) local machine.

    a. 16GB RAM

    b. A high bandwith network

2. These software installed on our local machine:

    a. Ansible 2.7+

    b. [Bash 4.x+](../prerequisites/bash.md)

    c. [Ruby](../prerequisites/ruby.md)

    d. `jq` 1.5+ (with `apt install jq` or `brew install jq`)

    e. GNU Make 3.x+

    f. Git v2.x+ and the `git-lfs` extension

    g. Utilities: `curl`, `unzip`

3. Install Virtualbox 5.2+. On macOS, run `brew cask install virtualbox` and on
   Linux, [follow the documentation][vbox_install].

[vbox_install]: https://www.virtualbox.org/wiki/Linux_Downloads


## Start the GBE project

```bash
git clone https://github.com/gstackio/gstack-bosh-environment.git

cd gstack-bosh-environment/

source <(./bin/gbe env)  # adds 'gbe' to our $PATH
```


## Configure the BOSH environment

Provided that `$EDITOR` points to our favorite text editor, we first adjust
the VM size for the `ddbox` environment.

```bash
$EDITOR ddbox-env/features/scale-vm-size.yml # set the number of CPUs to 4,
                                             # and VM memory size to 8000 MB
```

We edit the `ddbox-env` environment's `spec.yml` file.

```bash
$EDITOR ddbox-env/conf/spec.yml
```

And we set the `dns` section like this:

```yaml
dns:
  zone: sslip.io
  subdomain: 192-168-50-6
```


## Converge the BOSH environment

Basically, we need to congerge the BOSH server VM. Before that, we make sure
that we target the `ddbox` environment.
Finally, we need to reload the updated environment variables.

```bash
export GBE_ENVIRONMENT=ddbox-env
source <(./bin/gbe env)  # add 'gbe' to our $PATH
gbe up
source <(./bin/gbe env)  # reload the updated environment variables
```

If necessary, `gbe up` will install the supported versions of
`bosh`, `dnscontrol`
or any other required utilities, as local binaries for our project.
And the necessary routing table entries will also be created, calling
`gbe routes` for us.


## Converge all infrastructure modules

For converging all Easy Foundry infrastructure modules at once, we run the
following compound command.

```bash
gbe converge all
```

This imports any compiled BOSH Releases that might have been cached with
`gbe export` for saving compilation time. Please note that this is a time
saver only if our network bandwith is very high, though. In case the
`gbe import` step is too slow because of restricted network bandwidth, we can
use the alternative `gbe converge deployments` compound command.

As an alternative, we can also run the `make all` target to converge all Easy
Foundry [infrastructure modules](../components.md).


## Conclusion

Given the DNS setup above, we now have our infrastructure modules available at
those URLs.

Be default, staging Let's Encrypt certificates (Red lock HTTPS) are
provisionned for serving those URLs. But setting `acme_staging: false` in our
`deployments/traefik/conf/spec.yml` config, we can have production Let's
Encrypt certificates (Green lock HTTPS) easily.

 Component            | URL
----------------------|----------------------------------------------------
Cloud Foundry console | `https://console.sys.easyfoundry.example.com`
Cloud Foundry API     | `https://api.sys.easyfoundry.example.com`
Grafana               | `https://monitoring.sys.easyfoundry.example.com`
Prometheus            | `https://prometheus.sys.easyfoundry.example.com`
Alert Manager         | `https://alertmanager.sys.easyfoundry.example.com`
SHIELD v7             | `https://backups.sys.easyfoundry.example.com`
SHIELD v8             | `https://shield.sys.easyfoundry.example.com`
Concourse CI          | `https://ci.easyfoundry.example.com`
Træfik dashboard      | `https://traefik.easyfoundry.example.com`

Arrived at this point, we can keep our Easy Foundry project live, pull any
updates with `git pull` whenever necessary, and converge our environment
again... Like forever.


### Destroy the BOSH environment (optional)

If we ever needs to take the whole thing down, we can delete our BOSH
environment with these commands.

```bash
gbe delete all
gbe down
```
