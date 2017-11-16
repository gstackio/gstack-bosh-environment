# Test the deployments

## Basic tests

These require no DNS setup. They grab the main IP address running
the `bosh envs | grep gcp | cut -f1` command.

### Concourse

To test Concourse, run `open http://$(bosh envs | grep gcp | cut -f1):8080` in
order to open the main page.

### Cloud Foundry

To test Cloud Foundry, run:

```bash
cd deployments/cf
curl -s -H "Host: api.$(bosh int ./conf/depl-vars.yml --path /system_domain)" \
    http://$(bosh envs | grep gcp | cut -f1)/v2/info \
    | jq .
```


## Further tests

For further tests like connecting to CF, and testing CF-MySQL, you'll need to
setup a DNS wildcard [as explaied here](./docs/reference.md#set-dns-wildcard)
and update the following variables:

 DNS-related Variable    | Config File
-------------------------|-------------------------------------
`system_domain`          | `deployments/cf/conf/depl-vars.yml`
`external_url_hostname`  | `deployments/concourse/conf/depl-vars.yml`
`cf_mysql_external_host` | `deployments/mysql/conf/depl-vars.yml`
`cf_api_url`             | `deployments/mysql/conf/depl-vars.yml`

In the following sections, we assume that we use the `*.cf.prototyp.it` DNS
wildcard .

### Concourse

To use the Concourse server, you should set a DNS name that match the
`external_url_hostname` property of the deployment.

In order to connect to concourse, use the properties below

Property              | File
----------------------|----------------------------------------------
`basic_auth_username` | `deployments/concourse/conf/depl-vars.yml`
`basic_auth_password` | `deployments/concourse/state/depl-creds.yml`

### Cloud Foundry

To target Cloud Foundry, using `direnv`:

```bash
cd deployments/cf
cf api --skip-ssl-validation https://api.$(bosh int "$DEPL_DIR/conf/depl-vars.yml" --path /system_domain)
```

Then you can login with username `admin`, push apps, browse marketplace, etc.

Property              | File
----------------------|---------------------------------------
`cf_admin_password`   | `deployments/cf/state/depl-creds.yml`


### CF-MySQL

Set the `cf_admin_password` property in `deployments/mysql/conf/depl-vars.yml`
to the one found for the same name in `deployments/cf/state/depl-creds.yml`.

From the `mysql` deployment directory, run `bosh run-errand broker-registrar`
to register the CF-MySQL service offering in Cloud Foundry.

Once logged in to Cloud Foundry, create a space with `cf create-space system`,
target it with `cf target -s system`, and see that the `p-mysql` service is
now registered:

```bash
cf marketplace
```

To list the available plans for the `p-mysql` service:

```bash
cf marketplace -s p-mysql
```
