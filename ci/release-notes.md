### Improvements

- Traefik now runs smoke tests after being deployed.
- Bumped the `broker-registrar` release to v3.5.1, removing the workaround
  implemented in `cassandra`, `data-services`, `postgres` and  `rabbitmq`
  subsystems.
- Version updates, see below.

### Fixes

- The Postgres subsystem was not working because Prometheus v23.3.0 is not
  compatible with the Postgres v11.x shipped by the Postgres release v36.
  This version of Easy Foundry properly pins the Postgres version to `v31` for
  Prometheus.

  A next release version of Easy Foundry will upgrade both the Postgres
  database and the Prometheus version. The tested upgrade path is the
  following:

  1. Prometheus `v23.3.0` + Postgres `v31`
  2. Prometheus `v25.0.0` + Postgres `v32` (and follow instruction from
     [these release notes](https://github.com/cloudfoundry/postgres-release/releases/tag/v32))
  3. Prometheus `v25.0.0` + Postgres `v36`

### Notice

- `log-cache` is disabled in Cloud Foundry, because of excessive memory
  consumption in BOSH-Lite.

### Components Versions

Component | New Version | Old Version
---|---|---
Træfik | [1.6.0](https://github.com/gstackio/traefik-boshrelease/releases/tag/v1.6.0) | 1.5.0
