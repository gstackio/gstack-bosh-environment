
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

function setup_bbl() {
    local bbl_version=$1

    if which bbl > /dev/null 2>&1; then
        local existing_bbl_version
        existing_bbl_version=$(bbl --version | head -n 1 | cut -d' ' -f2)
        if [[ $existing_bbl_version =~ ^3\.2\. ]]; then
            return 0
        fi
    fi

    local bbl_bin=$BASE_DIR/bin/bbl
    if [[ -f $bbl_bin ]]; then
        return 0
    fi

    assert_utilities curl "to install bosh-bootloader"

    local bbl_repo=https://github.com/cloudfoundry/bosh-bootloader
    local linux_bin=bbl-${bbl_version}_linux_x86-64
    local darwin_bin=bbl-${bbl_version}_osx

    echo -e "\n${BLUE}Installing ${BOLD}bosh-bootloader CLI$RESET $bbl_version as: $bbl_bin\n"
    local url
    case $(platform) in
        darwin) url=$bbl_repo/releases/download/$bbl_version/$darwin_bin;;
        linux)  url=$bbl_repo/releases/download/$bbl_version/$linux_bin;;
    esac

    curl -sL -o "$bbl_bin" "$url"
    chmod +x "$bbl_bin"
}

function setup_terraform() {
    local tf_version=$1

    if which terraform > /dev/null 2>&1; then
        local existing_tf_version
        existing_tf_version=$(terraform --version | head -n 1 | cut -d' ' -f2)
        if [[ $existing_tf_version =~ ^v0\.9\. ]]; then
            return 0
        fi
    fi

    local tf_bin=$BASE_DIR/bin/terraform
    if [[ -f $tf_bin ]]; then
        return 0
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
    local bosh_cli_version=$1

    if which bosh > /dev/null 2>&1; then
        local existing_bosh_cli_version
        existing_bosh_cli_version=$(bosh --version | head -n 1 | cut -d' ' -f2 | cut -d- -f1)
        if [[ $existing_bosh_cli_version =~ ^2\.0\. ]]; then
            return 0
        fi
    fi

    local bosh_cli_bin=$BASE_DIR/bin/bosh
    if [[ -f $bosh_cli_bin ]]; then
        return 0
    fi

    assert_utilities curl "to install the Bosh CLI"

    echo -e "${BLUE}Installing ${BOLD}Bosh CLI$RESET v$bosh_cli_version as: $bosh_cli_bin"
    curl -sL "https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-${bosh_cli_version}-$(platform)-amd64" \
        -o "$bosh_cli_bin"
    chmod +x "$bosh_cli_bin"
}

function setup_credhub_cli() {
   local credhub_cli_version=$1

    if which credhub > /dev/null 2>&1; then
        local existing_credhub_cli_version
        existing_credhub_cli_version=$(credhub --version | head -n 1 | cut -d: -f2 | tr -d ' ')
        if [[ $existing_credhub_cli_version =~ ^1\.5\.3 ]]; then
            return 0
        fi
    fi

    local credhub_cli_bin=$BASE_DIR/bin/credhub
    if [[ -f $credhub_cli_bin ]]; then
        return 0
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
    local dnscontrol_version=$1

    if which dnscontrol > /dev/null 2>&1; then
        local existing_dnscontrol_version
        existing_dnscontrol_version=$(dnscontrol version | head -n 1 | cut -d' ' -f2 | cut -d- -f1)
        if [[ $existing_dnscontrol_version =~ ^0\.2\. ]]; then
            return 0
        fi
    fi

    local dnscontrol_bin=$BASE_DIR/bin/dnscontrol
    if [[ -f $dnscontrol_bin ]]; then
        return 0
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
    local cf_cli_version=$1

    if which cf > /dev/null 2>&1; then
        local existing_cf_cli_version
        existing_cf_cli_version=$(cf --version | head -n 1 | cut -d' ' -f3 | cut -d+ -f1)
        if [[ $existing_cf_cli_version =~ ^6\.33\. ]]; then
            return 0
        fi
    fi

    local cf_cli_bin=$BASE_DIR/bin/cf
    if [[ -f $cf_cli_bin ]]; then
        return 0
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
