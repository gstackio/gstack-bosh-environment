#!/usr/bin/env bash

set -ex

# Uncomment the following errand invocation if you want to destroy all backup
# archives when deleting this SHIELD v7 subsystem. This is acceptable for
# demos, but not for production.
#
# bosh run-errand remove-buckets
