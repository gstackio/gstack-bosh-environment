
VERB?=converge

all: cloud-config runtime-config concourse prometheus logsearch shield-v8 cassandra data-services mysql neo4j postgres rabbitmq redis

all-depls-in-order: traefik cf concourse prometheus logsearch minio scality shield-v7 shield-v8 cassandra data-services mysql neo4j postgres rabbitmq redis



cloud-config:
	gbe update -y $@

runtime-config:
	gbe update -y $@



traefik:
	gbe $(VERB) -y $@

concourse-manifest:
	gbe converge -y --manifest concourse

cf: traefik concourse-manifest
	gbe $(VERB) -y $@

concourse: cf
	gbe $(VERB) -y $@



prometheus: cf
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

data-services: cf
	gbe $(VERB) -y $@

mysql: cf
	gbe $(VERB) -y $@

neo4j: cf
	gbe $(VERB) -y $@

postgres: cf
	gbe $(VERB) -y $@

rabbitmq: cf
	gbe $(VERB) -y $@

redis: shield cf
	gbe $(VERB) -y $@

