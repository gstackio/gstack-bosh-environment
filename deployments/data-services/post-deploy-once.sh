#!/usr/bin/env bash

set -ex

bosh run-errand sanity-test

bosh run-errand broker-registrar
