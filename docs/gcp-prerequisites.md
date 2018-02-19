# GCP prerequisites

1. A high-bandwidth network access, for the machine that will run GBE.
   Especially a minimum of 50 Mbits/s when uploading to the cloud, giving
   approximatively 5 MB/s uploads.

2. [Install the Google Cloud CLI utility](https://cloud.google.com/sdk/downloads)
   (i.e. `gcloud`). On macOS, just run `brew cask install google-cloud-sdk`.

3. Create on Google Cloud an account, then run `gcloud init` as
   [told in the quickstarts](https://cloud.google.com/sdk/docs/quickstarts).

4. Install Ruby. You don't need the latest version. Usually `apt install ruby`
   is enough. (No need for
   [fancy install of latest Ruby](https://gorails.com/setup/ubuntu/16.04#ruby)
   involving `rbenv`.)

5. Installing `direnv` is optional. In case you do, run `brew install direnv`
   on macOS or `apt install direnv` on Ubuntu 16.04 or later. For other
   platforms, refer to
   [this Direnv documentation](https://github.com/direnv/direnv#install).

[bosh_cli_v2]: <https://github.com/cloudfoundry/bosh-cli>
[instal_cloud_sdk]: <https://cloud.google.com/sdk/downloads>
[install_direnv]: <https://github.com/direnv/direnv#install>
