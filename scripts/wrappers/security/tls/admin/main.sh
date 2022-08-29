#!/usr/bin/env bash

usage() {
cat << EOF
usage: admin/main.sh --password password ...
To be ran / setup once per cluster.
--password        (Required)    Password for the admin key
--subject         (Optional)    Subject for the certificate, defaults to CN=localhost
--help                          Shows help menu
EOF
}


CURRENT_DIR="$(dirname -- "$(readlink -f "${BASH_SOURCE}")")"


exit 1


# Args handling
function parse_args () {
    LONG_OPTS_LIST=(
        "password"
        "subject"
        "help"
    )
    opts=$(getopt \
      --longoptions "$(printf "%s:," "${LONG_OPTS_LIST[@]}")" \
      --name "$(basename "$0")" \
      --options "" \
      -- "$@"
    )
    eval set -- "${opts}"

    while [ $# -gt 0 ]; do
        case $1 in
            --password | --subject) shift
                shift
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
            -in admin.pem
    )

    key="plugins.security.authcz.admin_dn"
    new_conf=$(yq ".[\"${key}\"] = [\"${inverted_subject}\"]" "${CURRENT_DIR}"/opensearch.yml.part)

    echo -e "${new_conf}" >> "${OPENSEARCH_CONFIG}/opensearch.yml"
}


parse_args "$@"

source \
    "${OPS_ROOT}"/helpers/create-certificate.sh \
    --type admin \
    "$@"

update_opensearch_conf
