#!/usr/bin/env bash

set -eux


usage() {
cat << EOF
usage: admin/main.sh --password password ...
To be ran / setup once per cluster.
--password        (Required)    Password for the admin key
--root-password   (Required)    Password for the root key
--subject         (Optional)    Subject for the certificate, defaults to CN=localhost
--target-dir      (Optional)    The target directory where the certificates and related resources are created
--help                          Shows help menu
EOF
}

CURRENT_DIR="$(dirname -- "$(readlink -f "${BASH_SOURCE}")")"

# args
password=""
root_password=""
subject=""
target_dir=""


# Args handling
function parse_args () {
    local LONG_OPTS_LIST=(
        "password"
        "root-password"
        "subject"
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
            --root-password) shift
                root_password=$1
                ;;
            --subject) shift
                subject=$1
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


# Opensearch conf part change
function update_opensearch_conf () {
    inverted_subject=$(
        openssl x509 \
            -subject \
            -nameopt RFC2253 \
            -noout \
            -passin pass:"${password}" \
            -in "${target_dir}/admin.pem"
    )
    inverted_subject=${inverted_subject##subject=}

    key="plugins.security.authcz.admin_dn"
    new_conf=$(yq ".[\"${key}\"] = [\"${inverted_subject}\"]" "${CURRENT_DIR}"/opensearch.yml.part)

    echo -e "${new_conf}" >> "${OPENSEARCH_PATH_CONF}/opensearch.yml"
}


parse_args "$@"

source \
    "${OPS_ROOT}"/helpers/create-certificate.sh \
    --password "${password}" \
    --root-password "${root_password}" \
    --subject "${subject}" \
    --target-dir "${target_dir}" \
    --type "admin"

update_opensearch_conf
