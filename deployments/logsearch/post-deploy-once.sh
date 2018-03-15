#!/usr/bin/env bash

set -ex

bosh run-errand create-uaa-client

bosh run-errand upload-kibana-objects
