#!/usr/bin/env bash


usage() {
cat << EOF
usage: init.sh --root-password password ...
To be ran / setup once per cluster.
--password        (Required)    Password for the node key
--subject         (Optional)    Subject for the certificate, defaults to [..../CN=localhost]
--help                          Shows help menu
EOF
}


# Args
password=""
subject=""


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
            --password) shift
                password=$1
                ;;
            --subject) shift
                subject=$1
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
    if [ -z "${password}" ]; then
        err_message="\t- '--password' is required \n"
    fi

    if [ -n "${err_message}" ]; then
        echo -e "The following errors occurred: \n${err_message}"
        exit 1
    fi
}


parse_args "$@"
validate_args

# create the node cert
source \
    node/main.sh \
    --password "${password}" \
    --subject "${subject}"
