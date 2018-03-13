BOSH DNS Compiled Release subsystem
===================================

This subsystem is meant to provide a way to extract a compiled release
for the `bosh-dns` release, and put it in GBE `compiled-releases`
cache. Otherwise, as the release is defined in the runtime-config, you
can never issue a `bosh extract-release` with the correct
`--deployment` argument to download what you need.

A `post-deploy-once` hook is used to extract the compiled release and
put it in GBE cache. Only the Linux `bosh-dns` job is extracted. After
this, the hook deletes the GBE subsystem deployment because it is not
needed anymore.

This subsystem is named with a `zzz-` prefix so that it is not
included in `gbe converge list` or `gbe delete list` by default. This
makes this subsys being a kind of one-off task (we could even say a
“GBE errand”) to compute and extract a compiled release.
