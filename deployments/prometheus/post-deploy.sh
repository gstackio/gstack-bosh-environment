#!/usr/bin/env bash

set -ueo pipefail

BASE_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}
SUBSYS_DIR=${SUBSYS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

source "${BASE_DIR}/lib/hooks-api/common.inc.bash"
source "${BASE_DIR}/lib/hooks-api/cloud-foundry.inc.bash"

function grafana_api() {
    local verb=$1 uri_path=$2; shift 2

    curl --insecure --silent --fail --show-error --location \
        --request "${verb}" \
        --url "${GRAFANA_BASE_URI}${uri_path}" \
        --user "${GRAFANA_USERNAME}:${GRAFANA_PASSWORD}" \
        --header "Accept: application/json" \
        --header "Content-Type: application/json" \
        "$@"
}

function dashboard_payload() {
    local dashboard_definition_file=$1

    jq --null-input \
            --slurpfile "dashboards" "${dashboard_definition_file}" \
            --argjson "folder_id" "${RABBITMQ38_FOLDER_ID}" \
            '{
                "dashboard": ($dashboards | first
                        | .title |= sub("^(RabbitMQ-)?"; "RabbitMQ-3.8-")
                        | .tags = [ "RabbitMQ" ]
                        | .links +=
                            [
                                {
                                    "asDropdown": true,
                                    "icon": "external link",
                                    "includeVars": true,
                                    "keepTime": true,
                                    "tags": [
                                        "RabbitMQ"
                                    ],
                                    "targetBlank": false,
                                    "title": "RabbitMQ",
                                    "type": "dashboards"
                                }
                            ]
                    ),
                "folderId": $folder_id,
                "overwrite": true
            }' \
        | jq '.dashboard.templating.list =
                    [
                        {
                            "allValue": null,
                            "current": {},
                            "datasource": null,
                            "definition": "",
                            "hide": 0,
                            "includeAll": false,
                            "label": "Deployment",
                            "multi": false,
                            "name": "bosh_deployment",
                            "options": [],
                            "query": "label_values(rabbitmq_identity_info, bosh_deployment)",
                            "refresh": 1,
                            "regex": "",
                            "skipUrlSync": false,
                            "sort": 1,
                            "tagValuesQuery": "",
                            "tags": [],
                            "tagsQuery": "",
                            "type": "query",
                            "useTags": false
                        },
                        {
                            "allValue": null,
                            "current": {},
                            "datasource": null,
                            "definition": "",
                            "hide": 0,
                            "includeAll": false,
                            "label": "Job",
                            "multi": false,
                            "name": "bosh_job_name",
                            "options": [],
                            "query": "label_values(rabbitmq_identity_info{bosh_deployment=~\"$bosh_deployment\"}, bosh_job_name)",
                            "refresh": 1,
                            "regex": "",
                            "skipUrlSync": false,
                            "sort": 1,
                            "tagValuesQuery": "",
                            "tags": [],
                            "tagsQuery": "",
                            "type": "query",
                            "useTags": false
                        },
                        {
                            "allValue": null,
                            "current": {},
                            "datasource": null,
                            "definition": "",
                            "hide": 0,
                            "includeAll": true,
                            "label": "Host",
                            "multi": false,
                            "name": "host",
                            "options": [],
                            "query": "label_values(rabbitmq_identity_info{bosh_deployment=~\"$bosh_deployment\",bosh_job_name=~\"$bosh_job_name\"}, bosh_job_ip)",
                            "refresh": 1,
                            "regex": "",
                            "skipUrlSync": false,
                            "sort": 1,
                            "tagValuesQuery": "",
                            "tags": [],
                            "tagsQuery": "",
                            "type": "query",
                            "useTags": false
                        }
                    ]
            ' \
        | jq '.dashboard.panels |= map(
                    if .type == "row"
                    then .
                    else (.targets |= map(
                        .expr |= gsub(" \\* on\\(instance\\) group_left\\(rabbitmq_cluster(, rabbitmq_node)?\\) rabbitmq_identity_info\\{rabbitmq_cluster=\"\\$rabbitmq_cluster\"\\}"; "")
                    ))
                    end
                )' \
        | jq '.dashboard.panels |= map(
                    if .type == "row"
                    then .
                    else (.targets |= map(
                        .expr |= gsub("(?<metric_name>rabbitmq_[0-9a-z_]+)"; .metric_name + if .metric_name == "rabbitmq_node" then "" else "{bosh_deployment=~\"$bosh_deployment\",bosh_job_name=~\"$bosh_job_name\",bosh_job_ip=~\"$bosh_job_ip\"}" end)
                    ))
                    end
                )'
}

function post_dashboard() {
    local dashboard_definition_file=$1

    if [[ ! -f ${dashboard_definition_file} ]]; then
        echo "WARN: the '$(basename "${dashboard_definition_file}")' dashboard definition file does not exist. Skipping."
        return
    fi

    echo "INFO: converging dashboard for file '$(basename "${dashboard_definition_file}")'"
    set +e
    dashboard_payload "${dashboard_definition_file}" \
        | grafana_api "POST" "/api/dashboards/db" \
            --data "@-" \
        | jq -r '.status'
    status_code=$?
    set -e
    if [[ ${status_code} -ne 0 ]]; then
        echo "ERROR: posting dashboard to the Grafana API failed. Retrying request in verbose mode for debugging."
        set -x
        dashboard_payload "${dashboard_definition_file}" \
            | tee "/dev/stderr" \
            | grafana_api "POST" "/api/dashboards/db" \
                --verbose --data "@-" \
            | tee "/dev/stderr"
        set +x
        return ${status_code}
    fi
}

function _config() {
    local grafana_hostname system_domain
    grafana_hostname=$(spec_var "/deployment_vars/grafana_hostname")
    system_domain=$(cf_file_var "private-config" "/system_domain")

    GRAFANA_BASE_URI="https://${grafana_hostname}.${system_domain}"
    DASHBOARDS_REPO_DIR="${BASE_DIR}/.cache/resources/prometheus-rabbitmq-dashboards"

    GRAFANA_USERNAME=$(state_var "depl-manifest" "/instance_groups/name=grafana/jobs/name=grafana/properties/grafana/security/admin_user")
    GRAFANA_PASSWORD=$(state_var "depl-creds" "/grafana_password")
}

function main() {
    _config

    # Converge folder
    local folder_json
    folder_json=$(grafana_api "GET" "/api/folders" | jq -r '.[] | select(.title == "RabbitMQ 3.8")')
    RABBITMQ38_FOLDER_ID=$(jq -r '.id' <<< "${folder_json}")
    if [[ -z ${RABBITMQ38_FOLDER_ID} ]]; then
        folder_json=$(
            grafana_api "POST" "/api/folders" \
                --data-raw '{ "title": "RabbitMQ 3.8" }'
        )
        RABBITMQ38_FOLDER_ID=$(jq -r '.id' <<< "${folder_json}")
    fi

    # Converge dashboards
    post_dashboard "${DASHBOARDS_REPO_DIR}/docker/grafana/dashboards/RabbitMQ-Overview.json"
    post_dashboard "${DASHBOARDS_REPO_DIR}/docker/grafana/dashboards/RabbitMQ-Quorum-Queues-Raft.json"
    post_dashboard "${DASHBOARDS_REPO_DIR}/docker/grafana/dashboards/Erlang-Distribution.json"
}

main "$@"
