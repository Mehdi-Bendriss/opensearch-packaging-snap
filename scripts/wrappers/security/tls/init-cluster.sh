#!/usr/bin/env bash


usage() {
cat << EOF
usage: init.sh --root-password password ...
To be ran / setup once per cluster.
--root-password   (Required)    Password for encrypting the root key
--admin-password  (Required)    Password for encrypting the admin key
--subject         (Optional)    Subject for the certificate, defaults to [..../CN=localhost]
--rest-with-tls   (Optional)    Enum of either: yes (default), no. Enables the certificate for both the transport and rest layers or just the former
--help                          Shows help menu
EOF
}


# Args
root_password=""
admin_password=""
subject=""
rest_with_tls=""


# Args handling
function parse_args () {
    LONG_OPTS_LIST=(
        "root-password"
        "admin-password"
        "subject"
        "rest-with-tls"
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
            --root-password) shift
                root_password=$1
                ;;
            --admin-password) shift
                admin_password=$1
                ;;
            --subject) shift
                subject=$1
                ;;
            --rest-with-tls) shift
                rest_with_tls=$1
                ;;
            --help) usage
                exit
                ;;
        esac
        shift
    done
}


function validate_args () {
    err_message=""
    if [ -z "${root_password}" ]; then
        err_message="- '--root-password' is required \n"
    fi

    if [ -z "${admin_password}" ]; then
        err_message="${err_message}- '--admin-password' is required \n"
    fi

    if [ -n "${err_message}" ]; then
        echo -e "The following errors occurred: \n${err_message}Refer to the help menu."
        exit 1
    fi
}


parse_args "$@"
validate_args

# pushd "${OPS_ROOT}/security/tls" || exit

TLS_DIR="${OPS_ROOT}/security/tls"

# create the root cert
source \
    "${TLS_DIR}"/root/main.sh \
    --password "${root_password}" \
    --rest-with-tls "${rest_with_tls}" \
    --subject "${subject}" \
    --target-dir "${OPENSEARCH_PATH_CERTS}"

# create the admin cert
source \
    "${TLS_DIR}"/admin/main.sh \
    --password "${admin_password}" \
    --subject "${subject}" \
    --target-dir "${OPENSEARCH_PATH_CERTS}"

# popd || exit
