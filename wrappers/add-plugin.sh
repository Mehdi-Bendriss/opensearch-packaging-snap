#!/usr/bin/env bash


name=""
location=""  # zip served through https:// or file:///


function parse_args () {
    while [ $# -gt 0 ]; do
        if [[ $1 == "--help" ]]; then
            usage
            exit 0
        elif [[ $1 == *"--"* ]]; then
            param="${1/--/}"
            declare "$param"="$2"
        fi
        shift
    done
}


function install_plugin () {

    # Fetch the list of installed plugins
    INSTALLED_PLUGINS=$("${OPENSEARCH_HOME}"/bin/opensearch-plugin list)

    if ! echo "${INSTALLED_PLUGINS}" | grep -q "$1";
    then
        echo y | "${OPENSEARCH_HOME}"/bin/opensearch-plugin install "$2"
    fi

    INSTALLATION_PATH="${OPENSEARCH_HOME}/plugins/$1"
    CONFIG_PATH="${OPENSEARCH_PATH_CONF}/$1"

    for path in "${INSTALLATION_PATH}" "${CONFIG_PATH}"; do
        chmod -R 770 "${path}"
        chown -R snap_daemon:snap_daemon "${path}"
    done

}


if [[ ! ${name} == "opensearch-*" ]];
then
    name="opensearch-${name}"
fi
install_plugin "${name}" "${location}"
