Compiled Release One-Off helper subsystem
=========================================


## Overview

This subsystem is meant to provide a way to extract compiled release
tarballs for releases that are only introduced by the runtime-config.
The resulting tarballs are then put it in the GBE `compiled-releases`
cache.

Without this one-off subsystem, there is no way to issue a correct
`bosh-extract-release` invocation because the `--deployment` argument
is mandatory but other deployment don't reference the runtime-config
releases for de-coupling reasons.

As a solution, this subsystem introduce a dummy deployment that
reference those runtime-config release, just for the sake of issuing a
correct `bosh extract-release --deployment <something>` invocation.
After this is done, the dummy one-off deployment can disapear.


## Usage

In order to use this one-off subsystem, you must first update the
runtime config with `gbe update runtime-config -n`, and then run
`gbe converge zzz-compiled-release-helper -n`.


## Design

A `post-deploy-once` hook is used to extract the compiled releases and
put them in GBE cache. Only the Linux `bosh-dns` job is extracted.
After this, the hook deletes the dummy one-off deployment because it
is not needed anymore.

This subsystem is named with a `zzz-` prefix so that it is excluded
from `gbe converge list` or `gbe delete list` by default. This makes
this subsys being a kind of one-off task (we could even say a “GBE
errand”) to compute and extract some compiled releases that can't be
extracted otherwise.
