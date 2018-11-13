Google Cloud Virtual Machine deployment guide
=============================================

In this mode, you are running a Bash shell on a Linux or macOS system that we
call your “local machine”, and you are deploying on a remote VM in Google
Cloud, that is created on demand.


## GCP prerequisites

1. Create on Google Cloud an account, then run `gcloud init` as
   [told in the quickstarts][gcloud_quickstarts].

2. An Ubuntu 16.04, or a recent macOS 10.12+ (Sierra) local machine.

    a. A high-bandwidth network access. Especially a minimum of 50 Mbits/s
       when uploading to the cloud, giving approximatively 5 MB/s uploads.

2. These software installed on your local machine:

    a. [Install the Google Cloud CLI utility][instal_cloud_sdk] (i.e. `gcloud`).
       On macOS, just run `brew cask install google-cloud-sdk`.

    b. [Bash 4.x+](../prerequisites/bash.md)

    c. [Ruby](../prerequisites/ruby.md)

    d. `jq` 1.5+ (with `apt install jq` or `brew install jq`)

    e. GNU Make 3.x+

    f. Git v2.x+ and the `git-lfs` extension

5. Installing `direnv` is optional. In case you do, run `brew install direnv`
   on macOS or `apt install direnv` on Ubuntu 16.04 or later. For other
   platforms, refer to [this Direnv documentation][install_direnv].

[instal_cloud_sdk]: https://cloud.google.com/sdk/downloads
[gcloud_quickstarts]: https://cloud.google.com/sdk/docs/quickstarts
[install_direnv]: https://github.com/direnv/direnv#install


## Start your project

```bash
git clone https://github.com/gstackio/gstack-bosh-environment.git

cd gstack-bosh-environment/

source <(./bin/gbe env)
```


## Configure GCP access

1. Pick your own service account name, instead of the example
   `my-service-account` below.

2. Get your project ID from Google Cloud, and use it instead of the example
   `alpha-sandbox-717101` below.

```bash
gbe gcp "my-service-account" "alpha-sandbox-717101"
```

This is a once-for-all setup that will create the private key file
`base-env/conf/gcp-service-account.key.json` inside your project.
The `base-env/conf/env-infra-vars.yml` file will also be updated with your
specific GCP project ID. You can tweak your GCP zone, though and change the
`zone: europe-west1-d` to whatever suits you best.


## Configure your BOSH environment

Select the `gcp` environment.

```bash
export GBE_ENVIRONMENT=gcp-env
```

Edit the “gcp” environment's `spec.yml` file.

```bash
$EDITOR gcp-env/conf/spec.yml # in the 'infra_vars' section,
                              # set the GCP region & zone,
                              # and also check GCP project ID
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

```bash
source <(./bin/gbe env)  # add 'gbe' to the $PATH
gbe up
source <(./bin/gbe env)  # reload the updated environment variables
```

If necessary, this will install the supported versions of `bbl`, `terraform`,
`bosh`, `dnscontrol` or any other required utilities, as local binaries for
your project. And the necessary firewall rules will also be set, invoking
`gbe firewall` for you.


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
