#!/usr/bin/env bash

set -ex

if bosh instances | grep -qF broker-registrar; then
    bosh run-errand "broker-registrar"
fi
