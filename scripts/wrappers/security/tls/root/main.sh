#!/usr/bin/env bash

set -eux

usage() {
cat << EOF
usage: root/main.sh --password password ...
To be ran / setup once per cluster.
--password        (Required)    Password for the root key
--rest-with-tls   (Optional)    Enum of either: yes (default), no. Enables the certificate for both the transport and rest layers or just the former
--subject         (Optional)    Subject for the certificate, defaults to CN=localhost
--target-dir      (Optional)    The target directory where the certificates and related resources are created
--help                          Shows help menu
EOF
}


CURRENT_DIR="$(dirname -- "$(readlink -f "${BASH_SOURCE}")")"

# Args
rest_with_tls="yes"
subject=""
password=""
target_dir=""


# Args handling
function parse_args () {
    local LONG_OPTS_LIST=(
        "password"
        "subject"
        "rest-with-tls"
        "target-dir"
        "help"
    )
    local opts=$(getopt \
      --longoptions "$(printf "%s:," "${LONG_OPTS_LIST[@]}")" \
      --name "$(readlink -f "${BASH_SOURCE}")" \
      --options "" \
      -- "$@"
    )
    eval set -- "${opts}"

    while [ $# -gt 0 ]; do
        case $1 in
            --password) shift
                password=$1
                ;;
            --subject) shift
                subject=$1
                ;;
            --rest-with-tls) shift
                rest_with_tls=$1
                ;;
            --target-dir) shift
                target_dir=$1
                ;;
            --help) usage
                exit
                ;;
        esac
        shift
    done
}


function set_defaults () {
    if [ -z "${rest_with_tls}" ] || [ "${rest_with_tls}" != "no" ]; then
        rest_with_tls="yes"
    fi
}


function update_opensearch_conf () {
    sub_conf_file="opensearch.yaml.part.min"
    if [ "${rest_with_tls}" == "yes" ]; then
        sub_conf_file="opensearch.yml.part.full"
    fi

    cat "${CURRENT_DIR}/${sub_conf_file}" >> "${OPENSEARCH_PATH_CONF}/opensearch.yml"
}


parse_args "$@"
set_defaults

source \
    "${OPS_ROOT}"/helpers/create-certificate.sh \
    --password "${password}" \
    --subject "${subject}" \
    --target-dir "${target_dir}" \
    --type "root"


update_opensearch_conf
