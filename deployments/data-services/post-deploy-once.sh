#!/usr/bin/env bash

set -eo pipefail -x

bosh run-errand broker-registrar
