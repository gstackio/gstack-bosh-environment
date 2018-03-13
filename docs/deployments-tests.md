# Test the deployments

## Basic tests

The basic tests require no DNS setup. They grab the main IP address running
the `bosh envs | grep gcp | cut -f1` command.

### Concourse

To test Concourse, open the main page in a web browser:

```bash
open http://$(bosh envs | grep gcp | cut -f1):8080/
```

### Cloud Foundry

To test Cloud Foundry, run:

```bash
cd deployments/cf

curl -s -H "Host: api.$(bosh int ./deployments/cf/conf/spec.yml --path /deployment_vars/system_domain)" \
    http://$(bosh envs | grep "$BOSH_ENVIRONMENT" | cut -f1)/v2/info \
    | jq .
```


## Further tests

For further tests like connecting to CF, and testing CF-MySQL, you'll need to
setup a DNS wildcard [as explained here](./reference.md#set-dns-wildcard)
and update the following variables:

 DNS-related Variable    | Config File
-------------------------|-------------------------------------
`system_domain`          | `deployments/cf/conf/depl-vars.yml`
`external_url_hostname`  | `deployments/concourse/conf/depl-vars.yml`
`cf_mysql_external_host` | `deployments/mysql/conf/depl-vars.yml`
`cf_api_url`             | `deployments/mysql/conf/depl-vars.yml`


### Concourse

To use the Concourse server, you should set a DNS name that match the
`external_url_hostname` property of the deployment.

In order to connect to Concourse, use the properties below.

Property              | File
----------------------|----------------------------------------------
`basic_auth_username` | `deployments/concourse/conf/depl-vars.yml`
`basic_auth_password` | `deployments/concourse/state/depl-creds.yml`

### Cloud Foundry

To target Cloud Foundry, [install the `cf` CLI](http://docs.cloudfoundry.org/cf-cli/install-go-cli.html)
then target your Cloud Foundry platform:

```bash
cd deployments/cf

cf api --skip-ssl-validation https://api.$(bosh int ./conf/depl-vars.yml --path /system_domain)
```

Then you can login with username `admin`. You'll find the necessary password
as detaled in the table below.

Property              | File
----------------------|---------------------------------------
`cf_admin_password`   | `deployments/cf/state/depl-creds.yml`

Once logged in, you can push apps (See `cf push -h`), browse marketplace with
`cf marketplace`, provision data services, bind them to your applications,
etc.

As an example, you can push the Stratos web console, as explained below.


### CF-MySQL database-as-a-service cluster

Set the `cf_admin_password` property in `deployments/mysql/conf/depl-vars.yml`
to the one found for the same name in `deployments/cf/state/depl-creds.yml`.
Then converge the deployment running `gbe converge mysql`.

To register the MySQL services in Cloud Foundry

```
bosh -d gstack-one-mysql run-errand broker-registrar
```

Or when using `direnv`, go inside the `deployments/mysql` directory, and run
`bosh run-errand broker-registrar` to register the CF-MySQL service offering
in Cloud Foundry.

When logged in to Cloud Foundry (see above), create a space with
`cf create-space system`, target it with `cf target -s system`, and list the
available services:

```bash
cf marketplace
```

You should see that the `mysql-shared` service is now registered.

Then, list the available plans for the `mysql-shared` service:

```bash
cf marketplace -s mysql-shared
```


### SHIELD backup system

The SHIELD web interface can be reached as following.

```
cd deployments/shield

open https://$(bosh int ./conf/depl-vars.yml --path /shield_domain):10443/
```


### Prometheus monitoring

Access to the Prometheus user interfaces goes through the routing system of
Cloud Foundry and thus requires it to be deployed.

The Prometheus web interface:

```
cd deployments/prometheus
open http://$(bosh int ./conf/depl-vars.yml --path /prometheus_domain)
```

Use the `admin` usename and the `prometheus_password` from
`deployments/prometheus/state/depl-creds.yml`.

Grafana web interface:

```
cd deployments/prometheus
open http://$(bosh int ./conf/depl-vars.yml --path /grafana_domain)
```

Use the `admin` usename and the `grafana_password` from
`deployments/prometheus/state/depl-creds.yml`.

Alert manager web interface:

```
cd deployments/prometheus
open http://$(bosh int ./conf/depl-vars.yml --path /alertmanager_domain)
```

Use the `admin` usename and the `alertmanager_password` from
`deployments/prometheus/state/depl-creds.yml`.


### Stratos web console

Connect to your Cloud Foundry first, as detailed above. Then simply run:

```
git clone https://github.com/SUSE/stratos-ui.git
cd stratos-ui
cf push
```

Now the web console is getting pushed to Cloud Foundry, which takes
approximatively 4 minutes and 30 seconds. One it is done, access it like this:

```
pushd deployments/cf
open https://console.$(bosh int ./conf/depl-vars.yml --path /system_domain)
popd
```
