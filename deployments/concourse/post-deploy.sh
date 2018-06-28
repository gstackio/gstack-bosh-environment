#!/usr/bin/env bash

set -euo pipefail

SUBSYS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

set -x

"$SUBSYS_DIR/sanity-tests"
