Concourse deployment notes
==========================

The `conf/concourse-deployment.yml` is a copy/paste with no change of the
[example manifest](http://concourse.ci/clusters-with-bosh.html#section_deploying-concourse)
from the Concourse documentation.

All necessary changes to this base manifest happen in custom operation files.
This way, we try to minimize our effort when that upstream base manifest is
updated.
