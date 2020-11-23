Bare-metal deployment guide
===========================

In this mode, we are running a Bash shell on a Linux or macOS system that we
call our “local machine”, and we are deploying on a remote Linux server.


## Prerequisites

1. A remote server (virtual or bare-metal) with 32GB RAM, connected to high
   bandwith networks, and an Ubuntu 18.04+ server operating system.

2. An Ubuntu 18.04 or recent macOS 10.14+ (Mojave) local machine, with those
   software installed:

    a. Ansible 2.7+

    b. [Bash 4.x+](../prerequisites/bash.md)

    c. [Ruby](../prerequisites/ruby.md)

    d. `jq` 1.5+ (with `apt install jq` or `brew install jq`)

    e. GNU Make 3.x+

    f. Git v2.x+ and the `git-lfs` extension

    g. Utilities: `sshuttle`, `curl`, `unzip`

4. An SSH access to the remote server

    a. The required SSH key is configured on our local machine

    b. Our user on the remote server is sudoer


## Start the GBE project

```bash
git clone https://github.com/gstackio/gstack-bosh-environment.git gstack-prod

cd gstack-prod/

source <(./bin/gbe env)  # adds 'gbe' to our $PATH
```


## Provision Virtualbox on the remote server

In order to install Virtualbox and setup networking config on the remote
server, we run the [`provision` Ansible playbook](./ddbox-standalone-bosh-env/provision).

Provided that `$EDITOR` points to our favorite text editor, and `11.22.33.44`
is the IP address of your remote server, we verify the Ansible configuration
and run the `provision` playbook.

```bash
cd ddbox-standalone-bosh-env/provision/
$EDITOR ansible.cfg # We review our username, and we make sure this user has
                    # our public key in its '~/.ssh/authorized_keys' file.
ansible-playbook -i inventory.cfg --ask-become provision.yml \
         -e target_host=11.22.33.44 -e garden_vm_ip=192.168.50.7
```


Optionally:

```
$EDITOR inventory.cfg # We put the IP address of our remote box
                      # in the 'dedibox' section.
```

## Configure the BOSH environment

We need to edit the `spec.yml` file for both `ddbox-standalone-bosh` and
`ddbox-standalone-garden` environments.

```bash
${EDITOR:-emacs} \
    ddbox-standalone-bosh-env/conf/spec.yml \
    ddbox-standalone-garden-env/conf/spec.yml
```

1. In the `operations_files:` section, we enable the `virtualbox/remote` ops
   file.

2. In the `deployment_vars:` section, we give the correct values for the
   variables below.

    ```yaml
    deployment_vars:
      # ...
      external_ip: "11.22.33.44" # The public IP address or our remote server
      vbox_host: "11.22.33.44"   # The public IP address or our remote server
      vbox_username: "ubuntu"    # an SSH-accessible username on the remote server
    ```

Finally, we establish a tunnel from our local machine to our remote server,
using the same IP address and username.

```bash
VBOX_USERNAME=$(bosh int --path /deployment_vars/vbox_username ddbox-standalone-bosh-env/conf/spec.yml)
VBOX_HOST=$(bosh int --path /deployment_vars/vbox_host ddbox-standalone-bosh-env/conf/spec.yml)
sshuttle -r "${VBOX_USERNAME}@${VBOX_HOST}" 192.168.50.0/24 10.244.0.0/16
The authenticity of host '11.22.33.44 (11.22.33.44)' can't be established.
ECDSA key fingerprint is SHA256:cQrRqCLZz/XrtDGJV04e2lFlpPgz748uUMOyJzMqriw.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '11.22.33.44' (ECDSA) to the list of known hosts.
ubuntu@11.22.33.44's password:
client: Connected.
```

When you see `client: Connected.`, then you're done. The VPN tunnel is working!


## Configure DNS

See the separate chapter for [configuring DNS records](./configure-dns-records.md).


## Converge the BOSH environment

Basically, we need to congerge the Garden backend VM first, and then the BOSH
server VM. Before that, we make sure that we target the
`ddbox-standalone-bosh-env` environment.
Finally, we need to reload the updated environment variables.

```bash
export GBE_ENVIRONMENT=ddbox-standalone-bosh-env
source <(./bin/gbe env)  # add 'gbe' to our $PATH
GBE_ENVIRONMENT=ddbox-standalone-garden-env gbe up # may ask you a password if you don't have any SSH key access yet
cp -p ddbox-standalone-garden-env/conf/id_rsa* \
      ddbox-standalone-bosh-env/conf/ # use the same SSH key for both envs
gbe up
source <(./bin/gbe env)  # reload the updated environment variables
GBE_ENVIRONMENT=ddbox-standalone-garden-env gbe routes
```

As an alternative, we could run the compound `base-env` Makefile target.

```bash
export GBE_ENVIRONMENT=ddbox-standalone-bosh-env
source <(./bin/gbe env)
make base-env
source <(./bin/gbe env)
GBE_ENVIRONMENT=ddbox-standalone-garden-env gbe routes
```

If necessary, `gbe up` will install the supported versions of
`bosh`, `dnscontrol`
or any other required utilities, as local binaries for our project.
And the necessary NAT rules will also be set, running `gbe firewall` for us.


## Converge base infrastructure modules

```bash
gbe update -y cloud-config runtime-config
${EDITOR:-emacs} deployments/traefik/conf/private-config.yml
gbe converge -y traefik cf
```


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
