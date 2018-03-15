#!/usr/bin/env bash

set -ex

# Notice: sanity test needs the data services to be registered with
# Cloud Foundry first. Here 'post-deploy-once.sh' is guaranteed to run
# before 'post-deploy.sh'
bosh run-errand sanity-test
