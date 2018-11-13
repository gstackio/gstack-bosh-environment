GBE (Gstack BOSH Environment) & Easy Foundry
============================================

### GBE

GBE is a set of tools and conventions that establish best practice for
managing “infrastructure as code”, through the _description_ of an expected
infrastructure state, and _convergence_ towards that state.

GBE a **convergent infrastructure framework** if you like, where the idea of
“converging” infrastructure is a essential concept that embraces both initial
deployment and any further updates or upgrades. It's a solution for both day 1
_and_ day 2 concerns.

### Easy Foundry

_Easy Foundry_ is an Open Source distribution of Cloud Foundry, based on GBE.
By “_distribution_”, we mean a set of [infrastructure modules](./docs/components.md)
around Cloud Foundry that are consistently glued together to provide usable
features. Those modules can be opted-in or out, whenever necessary, and have
dependencies. You can think of it like a package manager for deploying
distributed systems.

One of the main design goals of Easy Foundry is to have minimal coupling with
proprietary Cloud services, and thus reduce the risk of being tied with any
Cloud Provider. This preserves Easy Foundry adopters freedom to chose the
provider they want, and still being free to switch whenever necessary.



Overall picture
---------------

GBE brings a solution to several separate concerns:

1. Bootstrap a BOSH environment. This is mainly about creating a BOSH server,
   properly configured to pilot some _automated infrastructure_*. Here we
   basically propose a (big) wrapper around `bosh create-env` for making
   things easy, smooth, and provide a completely automated bootstrap process.

2. Converge [infrastructure modules](./docs/components.md), targeting a given
   BOSH environment. This could be seen as a (big) wrapper around
   `bosh deploy` for making things easy, smooth, and ensure modularity.

3. Converge application deployments on top of the converged infrastructure
   modules. This is not finished yet, but is planned for the near future.

Those are separated. You could create your BOSH environment with any other
solution like [BUCC][bucc], and still be able to deploy Easy Foundry on top of
it.


_* Automated Infrastructure_: BOSH supports various [Iaas][iaas] like public
or private clouds, [Bare-Metal][bare_metal]-as-a-Service solutions like
RackHD, or container orchestration platforms like Kubernetes.

[bucc]: https://github.com/starkandwayne/bucc
[iaas]: https://en.wikipedia.org/wiki/Infrastructure_as_a_service
[bare_metal]: https://en.wikipedia.org/wiki/Bare-metal_server



Topologies
----------

### Deployment modes

We address several deployment modes that are worth being explained.

- **Multi VMs**: This is the classical BOSH mode, as used by many Fortune 500
  companies for their production infrastructures. The BOSH server runs alone
  on its VM, and all managed nodes are running on their own VM too. This mode
  provides proper isolation between workloads and thus higher robustness, for
  higher costs.

- **Single VM**: This is the classical _BOSH-Lite_ mode, where one single VM
  runs both the BOSH server, and managed nodes. The BOSH server is on the VM
  itself, whereas managed nodes are deployed in containers, on the same VM.
  This mode provides poor isolation of workloads, for absolute minimal costs.

- **Hybrid VMs**: One VM, that only runs the BOSH server, and a second one for
  running the managed nodes only. This is a hybrid setup where the BOSH server
  is on its VM alone, whereas managed nodes are deployed in containers, on a
  separate VM. This mode provides improved isolation, for very reduced costs.

### Support status

#### `gbe up`-based environments

Infrastructure     | Topology   | System | Status             | GBE Flavor
-------------------|------------|--------|--------------------|------------
Bare-Metal server  | Single VM  | Linux  | Supported          | `ddbox`
Bare-Metal server  | Hybrid VMs | Linux  | Actively supported | `ddbox`
Bare-Metal server  | Multi VMs  | Linux  | Not planned        | `ddbox`
Google Cloud (GCP) | Single VM  | Linux  | Supported          | `gcp`
Google Cloud (GCP) | Hybrid VMs | Linux  | Not supported      | `gcp`
Google Cloud (GCP) | Multi VMs  | Linux  | Not supported      | `gcp`
Local Virtualbox   | Single VM  | Linux  | Supported          | `ddbox`
Local Virtualbox   | Hybrid VMs | Linux  | Actively supported | `ddbox`
Local Virtualbox   | Multi VMs  | Linux  | Not planned        | `ddbox`
Local Virtualbox   | Single VM  | macOS  | Supported          | `ddbox`
Local Virtualbox   | Hybrid VMs | macOS  | Supported          | `ddbox`
Local Virtualbox   | Multi VMs  | macOS  | Not planned        | `ddbox`

#### `bucc up`-based environments

Infrastructure     | Topology  | System | Status
-------------------|-----------|--------|--------
AWS                | Multi VM  | Linux  | Supported
Azure              | Multi VM  | Linux  | Supported
Azure Stack        | Multi VM  | Linux  | Supported
Docker             | Single VM | Linux  | Not supported
Google Cloud (GCP) | Multi VM  | Linux  | Supported
OpenStack          | Multi VM  | Linux  | Supported
Virtualbox         | Single VM | Linux  | Supported
vSphere            | Multi VM  | Linux  | Supported



Getting started
---------------

Basically, you need to:

1. Check some prerequisites.

2. `gbe up` for converging the base infrastructure environment.

3. `gbe converge` for converging [infrastructure modules](./docs/components.md)
   or application deployments.


### Deployment guides

We have several deployment guides for some topologies that we support.

- [Bare-Metal server](./docs/getting-started/bare-metal.dm)
- [Google Cloud VM](./docs/getting-started/gcp-vm.dm)
- [Local laptop](./docs/getting-started/local-vbox.dm)

In case you encounter issues, please refer to the [troubleshooting](./docs/troubleshooting.md)
chapter of the documentation.



Documentation
-------------

The `gbe` CLI provides inline help with `gbe help`. And generally, help on a
given command can be obtained with `gbe <command> -h`.

Other documentations are available in the [docs](./docs/) directory:

- [GBE Command Line Interface workflow](./docs/cli-workflow.md)
- [GBE Command Line Interface reference](./docs/cli-reference.md)
- [GBE file structure reference](./docs/gbe-structure-reference.md)
- [Troubleshooting GBE](./docs/troubleshooting.md)



Contributing
------------

Please feel free to submit issues and pull requests.



Author and License
------------------

Copyright © 2017-2018, Benjamin Gandon, Gstack

Like the rest of BOSH, the Gstack BOSH environment is released under the terms
of the [Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0).

<!--
# Local Variables:
# indent-tabs-mode: nil
# End:
-->
