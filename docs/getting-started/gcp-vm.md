Google Cloud Virtual Machine deployment guide
=============================================

In this mode, we are running a Bash shell on a Linux or macOS system that we
call our “local machine”, and we are deploying on a remote VM in Google Cloud,
that is created on demand.


## Prerequisites

1. Create on Google Cloud an account, then run `gcloud init` as
   [told in the quickstarts][gcloud_quickstarts].

2. An Ubuntu 16.04, or a recent macOS 10.12+ (Sierra) local machine.

    a. A high-bandwidth network access. Especially a minimum of 50 Mbits/s
       when uploading to the cloud, giving approximatively 5 MB/s uploads.

3. These software installed on our local machine:

    a. [Install the Google Cloud CLI utility][instal_cloud_sdk] (i.e. `gcloud`).
       On macOS, just run `brew cask install google-cloud-sdk`.

    b. [Bash 4.x+](../prerequisites/bash.md)

    c. [Ruby](../prerequisites/ruby.md)

    d. `jq` 1.5+ (with `apt install jq` or `brew install jq`)

    e. GNU Make 3.x+

    f. Git v2.x+ and the `git-lfs` extension

    g. Utilities: `sshuttle`, `curl`, `unzip`

4. Installing `direnv` is optional. For this, we can run `brew install direnv`
   on macOS or `apt install direnv` on Ubuntu 16.04 or later. For other
   platforms, refer to [this Direnv documentation][install_direnv].

[instal_cloud_sdk]: https://cloud.google.com/sdk/downloads
[gcloud_quickstarts]: https://cloud.google.com/sdk/docs/quickstarts
[install_direnv]: https://github.com/direnv/direnv#install


## Start the GBE project

```bash
git clone https://github.com/gstackio/gstack-bosh-environment.git

cd gstack-bosh-environment/

source <(./bin/gbe env)  # adds 'gbe' to our $PATH
```


## Configure the BOSH environment

Provided that `easyfoundry-service-account` is the name we want to give to our
GCP service account, and `operator-happy-123456` is our project ID from Google
Cloud, we run the setup command below.

```bash
gbe gcp "easyfoundry-service-account" "operator-happy-123456"
```

We now have created a GCP service account, and its private access key file is
here: `gcp-env/conf/gcp-service-account.key.json` inside our project.

Provided that `$EDITOR` points to our favorite text editor, we edit the `gcp`
environment's `spec.yml` file.

```bash
$EDITOR gcp-env/conf/spec.yml
```

In the `infra_vars:` section set the GCP `region` & `zone` as shown below. We
also check the GCP project ID that has been set by the `gbe gcp` command
above.

```yaml
infra_vars:
  # ...
  region: europe-west3 # Germany
  zone: europe-west1-b
  project_id: operator-happy-123456
```


## Configure an external DNS zone

To fully enjoy Cloud Foundry, we must setup a few DNS records that will point
to our Easy Foundry installation. As a helper, GBE provides a way to converge
a DNS zone that we dedicate entirely to Easy Foundry. (Contributions are
welcome to improve this.)

We setup the DNS zone and subdomain in the environment's
`gcp-env/conf/spec.yml` file, under the `dns:` section.
In the example below, the wildcard DNS entry `*.easyfoundry.example.com` will
resolve to the `external_ip` that we have setup at the previous step above.

```yaml
dns:
  zone: example.com
  subdomain: easyfoundry
```

Then we provide a [DNSControl](https://github.com/StackExchange/dnscontrol)
`creds.json` file and adjust the `dns/conf/zone-config-template.js` file if
necessary.

The DNS zone is converged as part of the `gbe up` checklist only when a
`creds.json` file is provided. We end up with this layout under the `dns/`
subdirectory:

```
dns/
└── conf
    ├── creds.json
    └── zone-config-template.js
```


## Converge the BOSH environment

Basically, we need to congerge the BOSH server VM. Before that, we make sure
that we target the `gcp` environment.
Finally, we need to reload the updated environment variables.

```bash
export GBE_ENVIRONMENT=gcp-env
source <(./bin/gbe env)  # add 'gbe' to our $PATH
gbe up
source <(./bin/gbe env)  # reload the updated environment variables
```

If necessary, `gbe up` will install the supported versions of
`bbl`, `terraform`, `bosh`, `dnscontrol`
or any other required utilities, as local binaries for our project.
And the necessary firewall rules will also be set, invoking `gbe firewall` for
us.


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
