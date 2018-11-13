Easy Foundry components
=======================

## Infrastructure modules

- [Cloud Foundry](https://github.com/cloudfoundry/cf-deployment), for pushing
  code and get deployed and working stateless web applications.

- [Concourse](https://github.com/concourse/concourse) for Continuous
  Integration.

- A 3-nodes [MariaDB](https://github.com/cloudfoundry/cf-mysql-release)
  cluster available as Database-as-a-Service in `cf marketplace`.

- A [Cassandra](https://github.com/orange-cloudfoundry/cassandra-boshrelease)
  cluster, provided as Database-as-a-Service in `cf marketplace` for Big Data
  needs.

- A [RabbitMQ](https://github.com/pivotal-cf/cf-rabbitmq-release) 2-nodes
  cluster with queue mirroring, for `cf marketplace` Message-Bus-as-a-Service.

- A [Redis](https://github.com/pivotal-cf/cf-redis-release) data service, for
  session replications between Java

- Docker-based data services (MySQL, PostgreSQL & Redis) for testing and
  development purpose.

- An [ELK](https://github.com/cloudfoundry-community/logsearch-boshrelease)
  cluster for logs aggregation.

- [Prometheus](https://github.com/bosh-prometheus/prometheus-boshrelease) for
  monitoring concerns.

- [SHIELD](https://github.com/starkandwayne/shield-boshrelease) for handling
  backups of your statefull database clusters.

- A [Minio](https://github.com/minio/minio-boshrelease) 4-nodes cluster for
  storing databse backups.

- A Docker-based [Scality S3 server](https://hub.docker.com/r/scality/s3server/)
  for testing and development purpose.

- A solution for on-demand PostgreSQL database clusters, based on
  [Dingo PostgreSQL](https://github.com/gstackio/dingo-postgresql-release).

- A [Neo4j](https://github.com/neo4j-contrib/neo4j-on-cloud-foundry/tree/master/neo4j-release)
  cluster.

- A [CockroachDB](https://github.com/cppforlife/cockroachdb-release) 3-nodes
  cluster.

- A [Kong CE](https://github.com/gstackio/kong-ce-boshrelease) application
  gateway solution.


## Application deployments

This is not provided yet. But when it is, this section will be updated.
