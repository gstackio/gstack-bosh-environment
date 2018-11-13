Bare-metal deployment guide
===========================

In this mode, you are running a Bash shell on a Linux or macOS system that we
call your “local machine”, and you are deploying on a remote Linux server.


## Virtualbox prerequisites

1. A remote server (virtual or bare-metal) with 32GB RAM, connected to high
   bandwith networks, and an Ubuntu 16.04+ server operating system.

2. An Ubuntu 16.04 or recent macOS 10.12+ (Sierra) local machine, with those
   software installed:

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


## Provision Virtualbox on the remote server

Run the provided Ansible playbook to install Virtualbox and setup the network.

Provided that `$EDITOR` points to your favorite text editor:

```bash
cd ddbox-env/provision
$EDITOR ansible.cfg # review your username, and make sure it has your public key in its '~/.ssh/authorized_keys' file
$EDITOR inventory.cfg # put the IP address of your remote box in the 'dedibox' section
ansible-playbook -i inventory.cfg --ask-become provision.yml
```


## Configure your BOSH environment

Select the `ddbox-standalone-bosh` environment.

```bash
export GBE_ENVIRONMENT=ddbox-standalone-bosh-env
```

Edit the `ddbox-env` environment's `spec.yml` file.

```bash
$EDITOR ddbox-env/conf/spec.yml
```

In the `operations_files` section, enable the `virtualbox/remote` ops file.

In the `deployment_vars` section, input these variables

```yaml
  external_ip: "192.168.50.6"
  vbox_host: "<the public IP of your distant box>"
  vbox_username: "<an SSH-accessible username on the distant box>"
  vbox_ssh:
    private_key: |
      -----BEGIN RSA PRIVATE KEY-----
      <a valid SSH key for accessing the distant box with the specified username>
      -----END RSA PRIVATE KEY-----
```

Establish a tunnel from your local machine to your distant box, using the same
IP address and username.

```bash
sshuttle -r <username>@<distant-box-ip> 192.168.50.0/24 10.244.0.0/16
```


## Configure an external DNS zone

To fully enjoy Cloud Foundry, you must setup a few DNS records that will point
to your Easy Foundry installation. As a helper, GBE provides a way to converge
a DNS zone that you would dedicate to Easy Foundry.

The DNS zone and subdomain setup is made in the environment `conf/spec.yml`,
under the `dns:` section.

Then provide a [DNSControl](https://github.com/StackExchange/dnscontrol)
`creds.json` file and adjust the `dns/conf/zone-config-template.js` file. The
DNS zone is converged as part of the `gbe up` checklist only when a
`creds.json` file is provided. You'll end up with this layout under the `dns/`
subdirectory:

```
dns/
└── conf
    ├── creds.json
    └── zone-config-template.js
```


## Converge the BOSH environment

You first need to congerge the Garden backend VM, and then the BOSH server VM.
Finally, you need to reload the updated environment variables.

```bash
source <(./bin/gbe env)
GBE_ENVIRONMENT=ddbox-standalone-garden-env gbe up \
    && GBE_ENVIRONMENT=ddbox-standalone-bosh-env gbe up
source <(./bin/gbe env)
```

As an alternative, you can run the compound `base-env` target.

```bash
make base-env
source <(./bin/gbe env)
```

If necessary, these commands will install the supported versions of `bosh`,
`dnscontrol` or any other required utilities, as local binaries for your
project. And the necessary NAT rules will also be set, running `gbe firewall`
for you.


## Converge all infrastructure modules

Run this compound command for converging all Easy Foundry infrastructure
modules at once.

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
