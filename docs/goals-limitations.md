# Goals and limitations of GBE

Before you read this, please make sure you have read the
[main problem statement](../README.md#what-problems-does-gbe-solve) first.

[main_goals]: ../README.md#what-problems-does-gbe-solve


## Other (non-trivial) goals for GBE

Note: GBE is work in progress and all these goals are not completely addressed
yet.

- Be able to rebase deployment manifests customizations onto new versions of
  upstream base deployment manifests, when these happen to evolve over time.

- Be able to work several environments: sandox, ci-drone, pre-prod,
  production, etc. Elegantly express in separate places the configurations or
  layouts that are different, and factor all sources of deployment manifests
  for what is similar.

- Integrate with Continuous Integration and Continuous Deployment (CI & CD)
  workflows: changes to the deployed infrastructure are first tried by team
  members in personal sandbox environments, then deployed in a CI-driven ci-
  drone environment and thoroughly tested by CI with automated test suites,
  then continuously deployed in production.


## Limitations

- Currently, only BOSH-Lite on GCP is supported as a target infrastructure.

- Upstream base deployment manifests are pointed to as directories where
  `*-deployment` repositories are checked out, but the exact versions of these
  repos are not pinned down by GBE, nor tracked in Git.

- GBE doesn't suggest yet an elegant way of expressing differences between
  environments.
