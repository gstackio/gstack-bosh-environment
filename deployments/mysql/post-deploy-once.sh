#!/usr/bin/env bash

set -ex

bosh run-errand broker-registrar

# bosh run-errand smoke-tests # does not work yet
