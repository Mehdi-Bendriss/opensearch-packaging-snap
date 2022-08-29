#!/usr/bin/env bash


usage() {
cat << EOF
usage: snap-logger.sh --name step-name --override yes ...
To be ran / setup once per cluster.
--name        (Required)    Name of the log step / file to write
--override    (Optional)    Override the log file if exists (default: yes)
--help                          Shows help menu
EOF
}


name=""
override="yes"

# Args handling
function parse_args () {
    LONG_OPTS_LIST=(
        "name"
        "override"
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
            --name) shift
                name=$1
                ;;
            --override) shift
                override=$1
                ;;
            --help) usage
                exit
                ;;
        esac
        shift
    done
}

function set_defaults () {
    if [ -z "${override}" ] || [ "${override}" != "no" ]; then
        override="yes"
    fi
}

function validate_args () {
    err_message=""
    if [ -z "${name}" ]; then
        err_message="- '--name' is required \n"
    fi

    if [ -n "${err_message}" ]; then
        echo -e "The following errors occurred: \n${err_message}Refer to the help menu."
        exit 1
    fi
}


function log() {
    while read -r
    do
        echo "$(date) $REPLY" >> "${LOG_FILE_PATH}"
    done
}


parse_args "$@"
set_defaults
validate_args


mkdir -p "${SNAP_LOG_DIR}/"

LOG_FILE_PATH="${SNAP_LOG_DIR}/${name}.log"
if [ "${override}" == "yes" ]; then
    rm -f "${LOG_FILE_PATH}"
fi

exec 3>&1 1>> >(log) 2>&1
