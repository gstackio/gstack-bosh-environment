## GBE project structure reference

GBE is made of modular components called “subsystems” or *subsys* for short.
For those who know BOSH already, most subsystems are BOSH deployments, but
they can also be BOSH environments or BOSH configs.

A GBE project is made of one or more GBE environments. Be careful that a GBE
environment is made of a BOSH environment, but not only. It also contains a
cloud config, a runtime config.

Each such environment is made of a `bosh-environment` base subsystem, and two
`bosh-config` subsystems: one for the cloud config of the environment, and one
for the runtime config. For example, the default `ddbox` GBE environment is
made of these subsystems:

- `ddbox-env/`: the directory of the `bosh-environment` subsystem.
- `ddbox-env/cloud-config`: the directory of the cloud config subsystem for
  the GBE environment.
- `ddbox-env/runtime-config`: the directory of the cloud config subsystem for
  the GBE environment.


### Subsystems files

A subsystemis is typically made of:

 - A specification file (we say *spec* for short) in `conf/spec.yml`.

 - Optional features, made of operation files, in a `features/` subdirectory.

 - Optional hook scripts named `post-deploy.sh` or `pre-delete.sh` that run
   everytime the underlying event happens.

 - An optional once-for-all hook script named `post-deploy-once.sh` that run
   only once, before the very first deployment is made.


### Subsystems `spec.yml` file

#### The `subsys` root node

The `subsys` root node specifies the subsys name, type and some dependency
information.

```yaml
subsys:
  name: cf
  type: bosh-deployment
  deploy_after: shield-v7 # the name of another 'bosh-deployment' subsystem
```

Possible types: `bosh-environment`, `bosh-config` (for both cloud config and
runtime config), and `bosh-deployment`.


#### The `input_resources` section

The `input_resources` array defines the external resources that the subsystem
is built uppon.

Currently, theses resources can only be Git repositories. They are given a URI
that is passed to a `git clone` invocation, and a version that is passed to a
`git chackout` invocation.


#### The `main_deployment_file` and `operations_files` root nodes

The `main_deployment_file` is a path to a YAML file onto which ops files can
possibly be applied. This means that an empty file is not accepted. At least
`--- {}` must be specified.

The first component og the `main_deployment_file` path is a resource name, as
declared in the `input_resources` section. Where refering to a file that is
local to the subsystem, a dot `.` can be used instead of the resource name. In
this case, `.` refers to the root directory of the subsystem, so you need to
specify `./conf/plop-deployment.yml` to refer to a `plop-deployment.yml` file
within in the `conf/` subdirectory.

The `operations_files` root node defines named arrays of operation files. All
`.yml` suffixes are implied and must not be specified. The arrays are named
after a resource name (as declared in the `input_resources` section) and the
special `local` is accepted for ops files that are in the `features/`
subdirectory of the subsystem.

To ensure the order in which these groups are applied, you can prefix them
with a number followed by a dot. The names are sorted in lexicographic orcer
and the numeric prefixes atr stripped off.

For example:

```yaml
operations_files:
  10.cassandra-boshrelease:
    - deployment/operations/add-broker
  20.local:
    - set-versions
```

Here the `add-broker.yml` (the `.yml` is implied) file is to be found in the
`cassandra-boshrelease` input resource (this is the name with which this
resource was declared), and the `set-version.yml` file that is located in the
`features/` subdirectory of the subsystem.

As far as application order is concerned, `add-broker.yml` is applied first,
and `set-versions.yml` comes second. Because the prefix `10.` comes before
`20.` in a lexicographic order.


#### The `deployment_vars` section

This section lists the variables that are declared fot this subsystem. They
will be injected into the BOSH manifest. Any `foobar:` deployment variable
requires some `((foobar))` placeholders to be present in the manifest, for the
value to be injected.

Structured variables can be used, as the `((foo.bar))` syntax supports the dot
`.` notation as the hierarchical separator.


#### The `imported_vars` section

This section lists the variables to import from other subsystems.
