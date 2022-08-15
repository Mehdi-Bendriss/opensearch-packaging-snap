#!/usr/bin/env bash


PLUGINS_URL="https://opensearch-builds.s3.eu-west-1.amazonaws.com/plugins"


function install_plugin () {

    # Fetch the list of installed plugins
    INSTALLED_PLUGINS=$("${OPENSEARCH_HOME}"/bin/opensearch-plugin list)

    if ! echo "${INSTALLED_PLUGINS}" | grep -q "$1"
    then
      echo y | "${OPENSEARCH_HOME}"/bin/opensearch-plugin install "$2"
    fi

    INSTALLATION_PATH="${OPENSEARCH_HOME}/plugins/$1"
    CONFIG_PATH="${OPENSEARCH_HOME}/config/$1"

    for path in "${INSTALLATION_PATH}" "${CONFIG_PATH}"; do
        chmod -R 770 "${path}"
        chown -R snap_daemon:snap_daemon "${path}"
    done

}


# installed the security plugin if not already
SECURITY_PLUGIN_URL="${PLUGINS_URL}/security/opensearch-security-${PROJECT_VERSION}.0.zip"
install_plugin "opensearch-security" "${SECURITY_PLUGIN_URL}"
