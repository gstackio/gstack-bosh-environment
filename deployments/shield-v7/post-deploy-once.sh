#!/usr/bin/env bash

set -ex

bosh run-errand create-buckets
bosh run-errand mc # creates minio buckets
