#!/usr/bin/env bash

usage() {
cat << EOF
usage: node/main.sh --password password ...
To be ran once a new node joins the cluster.
--password        (Required)    Password for encrypting the key
--name            (Required)    Name of certificate, i.e: "node1"
--subject         (Optional)    Subject for the certificate, defaults to ....CN=localhost
--help                          Shows help menu
EOF
}


CURRENT_DIR="$(dirname -- "$(readlink -f "${BASH_SOURCE}")")"


# args
name=""


# Args handling
function parse_args () {
    LONG_OPTS_LIST=(
        "password"
        "name"
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
            --name) shift
                name=$1
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
            -in "node.${name}".pem
    )

    key="plugins.security.nodes_dn"

    new_conf=$(yq "(.[\"${key}\"] - [\"dummy\"]) |= (. + [\"${inverted_subject}\"][] | unique)" "${CURRENT_DIR}"/opensearch.yml.part)

    echo -e "${new_conf}" >> "${OPENSEARCH_CONFIG}/opensearch.yml"
}


parse_args "$@"

printf "${OPS_ROOT}/helpers/create-certificate.sh: %s" "$@"
source "${OPS_ROOT}"/helpers/create-certificate.sh "$@"

update_opensearch_conf
