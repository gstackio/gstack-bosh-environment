
VERB?=converge

all: configs concourse prometheus logsearch shield-v8 cassandra data-services mysql neo4j postgres rabbitmq redis

all-depls-in-order: traefik cf concourse prometheus logsearch minio scality shield-v7 shield-v8 cassandra data-services mysql neo4j postgres rabbitmq redis

all-with-infra: base-env import-all configs all-depls-in-order



base-env: ddbox-standalone-bosh-env

ddbox-standalone-garden-env:
	GBE_ENVIRONMENT=$@ gbe up

ddbox-standalone-bosh-env: ddbox-standalone-garden-env
	GBE_ENVIRONMENT=$@ gbe up



import-all: base-env
	gbe import



configs: cloud-config runtime-config

cloud-config:
	gbe update -y $@

runtime-config:
	gbe update -y $@



traefik: configs
	gbe $(VERB) -y $@

cf: traefik
	gbe $(VERB) -y $@

concourse: cf
	gbe $(VERB) -y $@



prometheus: cf # base-env
	gbe $(VERB) -y $@

logsearch: cf
	gbe $(VERB) -y $@



minio:
	gbe $(VERB) -y $@

scality:
	gbe $(VERB) -y $@

shield: shield-v7

shield-v7: minio scality
	gbe $(VERB) -y $@

shield-v8:
	gbe $(VERB) -y $@



cassandra: shield cf
	gbe $(VERB) -y $@

cockroachdb:
	gbe $(VERB) -y $@

data-services: cf
	gbe $(VERB) -y $@

mysql: cf
	gbe $(VERB) -y $@

neo4j:
	gbe $(VERB) -y $@

postgres: cf
	gbe $(VERB) -y $@

rabbitmq: cf
	gbe $(VERB) -y $@

redis: shield cf
	gbe $(VERB) -y $@

