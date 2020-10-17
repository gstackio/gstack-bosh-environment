#!/usr/bin/env bash

set -ueo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}

function main() {
    local subsys=$1

    if [[ ${subsys} == "credhub" ]]; then
        local cert expiry_date
        for name in $(credhub find --output-json | jq --raw-output '.credentials[].name'); do
            echo "${name}"
            set +e
            cert=$(credhub get --name "${name}" --key "certificate")
            set -e
            if [[ -z ${cert} ]]; then
                continue
            fi
            expiry_date=$(openssl x509 -enddate -noout <<< "${cert}" \
                | sed 's/notAfter=//')
            if ! openssl x509 -checkend 0 -noout <<< "${cert}"; then
                echo "ERROR: certificate '${name}' from Credhub has expired on '${expiry_date}'"
            elif ! openssl x509 -checkend $(( 30 * 86400 )) -noout <<< "${cert}"; then
                echo "WARN: certificate '${name}' from Credhub is about to expire on '${expiry_date}'"
            else
                echo "INFO: certificate '${name}' from Credhub is valid until '${expiry_date}'"
            fi
        done
    elif [[ -n ${subsys} ]]; then
        check_expiry "${subsys}"
    else
        for subsys in $(find "${BASE_DIR}/state" -mindepth 1 -maxdepth 1); do
            check_expiry "${subsys}"
        done
    fi
}

function check_expiry() {
    local subsys=$1

    local all_creds
    all_creds=($(spruce json "${BASE_DIR}/state/${subsys}/depl-creds.yml" \
        | jq -r 'keys | .[]'))
    for key in "${all_creds[@]}"; do
        check_cert "${subsys}" "/${key}/certificate"
        check_cert "${subsys}" "/${key}/ca"
    done

    
}

function check_cert() {
    local subsys=$1
    local prop_path=$2

    local cert
    cert=$(bosh interpolate --path "${prop_path}" \
            "${BASE_DIR}/state/${subsys}/depl-creds.yml" 2> /dev/null || true)

    # local base_path
    # base_path=$(dirname "${prop_path}")
    verify_cert "${cert}" "${subsys}" "${prop_path}"
}

function verify_cert() {
    local cert=$1
    local subsys=$2
    local prop_path=$3

    local expiry_date
    if [[ -n "${cert}" ]]; then
        expiry_date=$(openssl x509 -enddate -noout <<< "${cert}" \
            | sed 's/notAfter=//')
        if ! openssl x509 -checkend 0 -noout <<< "${cert}"; then
            echo "ERROR: certificate '${prop_path}' from subsys '${subsys}' has expired on '${expiry_date}'"
        elif ! openssl x509 -checkend $(( 30 * 86400 )) -noout <<< "${cert}"; then
            echo "WARN: certificate '${prop_path}' from subsys '${subsys}' is about to expire on '${expiry_date}'"
        else
            echo "INFO: certificate '${prop_path}' from subsys '${subsys}' is valid until '${expiry_date}'"
        fi
    fi
}

main "$@"
