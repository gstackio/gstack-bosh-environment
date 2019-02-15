
function assert_utilities() {
    local utilities=()

    while # NOTE: emulating do-while, see <https://stackoverflow.com/a/27761760>
        utilities+=("$1"); shift
        [[ $# -gt 1 ]]
    do :; done
    local reason=$1; shift # last argument

    for utility in "${utilities[@]}"; do
        if ! which "$utility" > /dev/null; then
            fatal "ERROR: $project_name requires '$utility'${reason:+" $reason"}." \
                "Please install it first. Aborting."
        fi
    done
}

BBL_VERSION=3.2.6
BBL_ACCEPTED_VERSIONS='^3\.2\..*'
TERRAFORM_VERSION=0.9.11
TERRAFORM_ACCEPTED_VERSIONS='^v0\.9\..*'
BOSH_CLI_VERSION=5.3.1
BOSH_CLI_ACCEPTED_VERSIONS='^5\.3\..*'
SPRUCE_VERSION=1.18.2
SPRUCE_ACCEPTED_VERSIONS='^1\.18\..*'
CREDHUB_CLI_VERSION=1.5.3
CREDHUB_CLI_ACCEPTED_VERSIONS='^1\.5\.3'
DNSCONTROL_VERSION=0.2.3
DNSCONTROL_ACCEPTED_VERSIONS='^0\.2\..*'
CF_CLI_VERSION=6.40.0
CF_CLI_ACCEPTED_VERSIONS='^6\.40\..*'

readonly \
    BBL_VERSION         BBL_ACCEPTED_VERSIONS \
    TERRAFORM_VERSION   TERRAFORM_ACCEPTED_VERSIONS \
    BOSH_CLI_VERSION    BOSH_CLI_ACCEPTED_VERSIONS \
    SPRUCE_VERSION      SPRUCE_ACCEPTED_VERSIONS \
    CREDHUB_CLI_VERSION CREDHUB_CLI_ACCEPTED_VERSIONS \
    DNSCONTROL_VERSION  DNSCONTROL_ACCEPTED_VERSIONS \
    CF_CLI_VERSION      CF_CLI_ACCEPTED_VERSIONS

function setup_bbl() {
    local bbl_version=${1:-$BBL_VERSION}

    local existing_bbl_version
    if which bbl > /dev/null 2>&1; then
        existing_bbl_version=$(bbl --version | head -n 1 | cut -d' ' -f2)
        if [[ $existing_bbl_version =~ $BBL_ACCEPTED_VERSIONS ]]; then
            return 0
        fi
    fi

    local bbl_bin=$BASE_DIR/bin/bbl
    if [[ -f $bbl_bin ]]; then
        existing_bbl_version=$("$bbl_bin" --version | head -n 1 | cut -d' ' -f2)
        if [[ $existing_bbl_version =~ $BBL_ACCEPTED_VERSIONS ]]; then
            return 0
        fi
    fi

    assert_utilities curl "to install bosh-bootloader"

    local bbl_repo=https://github.com/cloudfoundry/bosh-bootloader
    local linux_bin=bbl-v${bbl_version}_linux_x86-64
    local darwin_bin=bbl-v${bbl_version}_osx

    echo -e "\n${BLUE}Installing ${BOLD}bosh-bootloader CLI$RESET v$bbl_version as: $bbl_bin\n"
    local url
    case $(platform) in
        darwin) url=$bbl_repo/releases/download/v$bbl_version/$darwin_bin;;
        linux)  url=$bbl_repo/releases/download/v$bbl_version/$linux_bin;;
    esac

    curl -sL -o "$bbl_bin" "$url"
    chmod +x "$bbl_bin"
}

function setup_terraform() {
    local tf_version=${1:-$TERRAFORM_VERSION}

    local existing_tf_version
    if which terraform > /dev/null 2>&1; then
        existing_tf_version=$(terraform --version | head -n 1 | cut -d' ' -f2)
        if [[ $existing_tf_version =~ $TERRAFORM_ACCEPTED_VERSIONS ]]; then
            return 0
        fi
    fi

    local tf_bin=$BASE_DIR/bin/terraform
    if [[ -f $tf_bin ]]; then
        existing_tf_version=$("$tf_bin" --version | head -n 1 | cut -d' ' -f2)
        if [[ $existing_tf_version =~ $TERRAFORM_ACCEPTED_VERSIONS ]]; then
            return 0
        fi
    fi

    assert_utilities curl unzip "to install terraform"

    local base_url=https://releases.hashicorp.com/terraform

    echo -e "${BLUE}Installing ${BOLD}terraform CLI$RESET v$tf_version as: $tf_bin"
    local url
    url=$base_url/$tf_version/terraform_${tf_version}_$(platform)_amd64.zip

    local temp_dir
    temp_dir=$(mktemp -d)
    pushd "$temp_dir"
        curl -sL -o tf.zip "$url"
        unzip tf.zip
        rm tf.zip
        mv terraform "$tf_bin"
        chmod +x "$tf_bin"
    popd
    rm -rf "$temp_dir"
}

function setup_bosh_cli() {
    local bosh_cli_version=${1:-$BOSH_CLI_VERSION}

    local existing_bosh_cli_version
    if which bosh > /dev/null 2>&1; then
        existing_bosh_cli_version=$(bosh --version | head -n 1 | cut -d' ' -f2 | cut -d- -f1)
        if [[ $existing_bosh_cli_version =~ $BOSH_CLI_ACCEPTED_VERSIONS ]]; then
            return 0
        fi
    fi

    local bosh_cli_bin=$BASE_DIR/bin/bosh
    if [[ -f $bosh_cli_bin ]]; then
        existing_bosh_cli_version=$("$bosh_cli_bin" --version | head -n 1 | cut -d' ' -f2 | cut -d- -f1)
        if [[ $existing_bosh_cli_version =~ $BOSH_CLI_ACCEPTED_VERSIONS ]]; then
            return 0
        fi
    fi

    assert_utilities curl "to install the Bosh CLI"

    echo -e "${BLUE}Installing ${BOLD}Bosh CLI$RESET v$bosh_cli_version as: $bosh_cli_bin"
    curl -sL "https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${bosh_cli_version}-$(platform)-amd64" \
        -o "$bosh_cli_bin"
    chmod +x "$bosh_cli_bin"
}

function setup_spruce() {
    local spruce_version=${1:-$SPRUCE_VERSION}

    if which spruce > /dev/null 2>&1; then
        local existing_spruce_version
        existing_spruce_version=$(spruce --version | head -n 1 | cut -d' ' -f4)
        if [[ $existing_spruce_version =~ $SPRUCE_ACCEPTED_VERSIONS ]]; then
            return 0
        fi
    fi

    local spruce_bin=$BASE_DIR/bin/spruce
    if [[ -f $spruce_bin ]]; then
        return 0
    fi

    assert_utilities curl "to install the Spruce CLI"

    echo -e "${BLUE}Installing ${BOLD}Spruce CLI$RESET v$spruce_version as: $spruce_bin"
    curl -sL "https://github.com/geofffranks/spruce/releases/download/v${spruce_version}/spruce-$(platform)-amd64" \
        -o "$spruce_bin"
    chmod +x "$spruce_bin"
}

function setup_credhub_cli() {
   local credhub_cli_version=${1:-$CREDHUB_CLI_VERSION}

    local existing_credhub_cli_version
    if which credhub > /dev/null 2>&1; then
        existing_credhub_cli_version=$(credhub --version | head -n 1 | cut -d: -f2 | tr -d ' ')
        if [[ $existing_credhub_cli_version =~ $CREDHUB_CLI_ACCEPTED_VERSIONS ]]; then
            return 0
        fi
    fi

    local credhub_cli_bin=$BASE_DIR/bin/credhub
    if [[ -f $credhub_cli_bin ]]; then
        existing_credhub_cli_version=$("$credhub_cli_bin" --version | head -n 1 | cut -d: -f2 | tr -d ' ')
        if [[ $existing_credhub_cli_version =~ $CREDHUB_CLI_ACCEPTED_VERSIONS ]]; then
            return 0
        fi
    fi

    assert_utilities curl tar "to install the CredHub CLI"

    local base_url=https://github.com/cloudfoundry-incubator/credhub-cli/releases/download

    echo -e "${BLUE}Installing ${BOLD}CredHub CLI$RESET v$credhub_cli_version as: $credhub_cli_bin"
    local url
    url=$base_url/$credhub_cli_version/credhub-$(platform)-$credhub_cli_version.tgz

    local temp_dir
    temp_dir=$(mktemp -d)
    pushd "$temp_dir"
        curl -sL -o credhub.tgz "$url"
        tar -zxf credhub.tgz
        rm credhub.tgz
        mv credhub "$credhub_cli_bin"
        chmod +x "$credhub_cli_bin"
    popd
    rm -rf "$temp_dir"
}

function setup_dnscontrol() {
    local dnscontrol_version=${1:-$DNSCONTROL_VERSION}

    local existing_dnscontrol_version
    if which dnscontrol > /dev/null 2>&1; then
        existing_dnscontrol_version=$(dnscontrol version | head -n 1 | cut -d' ' -f2 | cut -d- -f1)
        if [[ $existing_dnscontrol_version =~ $DNSCONTROL_ACCEPTED_VERSIONS ]]; then
            return 0
        fi
    fi

    local dnscontrol_bin=$BASE_DIR/bin/dnscontrol
    if [[ -f $dnscontrol_bin ]]; then
        existing_dnscontrol_version=$("$dnscontrol_bin" version | head -n 1 | cut -d' ' -f2 | cut -d- -f1)
        if [[ $existing_dnscontrol_version =~ $DNSCONTROL_ACCEPTED_VERSIONS ]]; then
            return 0
        fi
    fi

    assert_utilities curl "to install the DNSControl CLI"

    echo -e "${BLUE}Installing ${BOLD}DNSControl CLI$RESET v$dnscontrol_version as: $dnscontrol_bin"

    local system=$(platform)
    local suffix=$(tr '[:lower:]' '[:upper:]' <<< ${system:0:1})${system:1}
    curl -sL "https://github.com/StackExchange/dnscontrol/releases/download/v$dnscontrol_version/dnscontrol-$suffix" \
        -o "$dnscontrol_bin"
    chmod +x "$dnscontrol_bin"
}

function setup_cf_cli() {
    local cf_cli_version=${1:-$CF_CLI_VERSION}

    local existing_cf_cli_version
    if which cf > /dev/null 2>&1; then
        existing_cf_cli_version=$(cf --version | head -n 1 | cut -d' ' -f3 | cut -d+ -f1)
        if [[ $existing_cf_cli_version =~ $CF_CLI_ACCEPTED_VERSIONS ]]; then
            return 0
        fi
    fi

    local cf_cli_bin=$BASE_DIR/bin/cf
    if [[ -f $cf_cli_bin ]]; then
        existing_cf_cli_version=$("$cf_cli_bin" --version | head -n 1 | cut -d' ' -f3 | cut -d+ -f1)
        if [[ $existing_cf_cli_version =~ $CF_CLI_ACCEPTED_VERSIONS ]]; then
            return 0
        fi
    fi

    assert_utilities curl tar "to install the Cloud Foundry CLI"

    local base_url=https://packages.cloudfoundry.org/stable

    echo -e "${BLUE}Installing ${BOLD}Cloud Foundry CLI$RESET v$cf_cli_version as: $cf_cli_bin"
    case $(platform) in
        darwin) cf_cli_release=macosx64-binary ;;
        linux)  cf_cli_release=linux64-binary  ;;
    esac
    local url="$base_url?release=$cf_cli_release&version=$cf_cli_version"

    local temp_dir
    temp_dir=$(mktemp -d)
    pushd "$temp_dir"
        curl -sL -o cf.tgz "$url"
        tar -zxf cf.tgz cf
        rm cf.tgz
        mv cf "$cf_cli_bin"
        chmod +x "$cf_cli_bin"
    popd
    rm -rf "$temp_dir"
}
