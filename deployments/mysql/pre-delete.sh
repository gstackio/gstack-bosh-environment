#!/usr/bin/env bash

set -ex

bosh run-errand deregister-and-purge-instances
