#!/usr/bin/env bash

set -ex

# Sanity test needs the data services to be registered with Cloud Foundry first
bosh run-errand broker-registrar

bosh run-errand sanity-test
