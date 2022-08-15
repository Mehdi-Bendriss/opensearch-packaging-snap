#!/usr/bin/env bash


PLUGINS_URL="https://opensearch-builds.s3.eu-west-1.amazonaws.com/plugins"


DAEMON_SYSTEMD_PATH="/etc/systemd/system/snap.opensearch.daemon.service.d"
mkdir -p "${DAEMON_SYSTEMD_PATH}"

script_log="${DAEMON_SYSTEMD_PATH}"/install-plugins.log
exec 1>>"${script_log}"
exec 2>&1


function install_plugin () {

    # Fetch the list of installed plugins
    INSTALLED_PLUGINS=$("${OPENSEARCH_HOME}"/bin/opensearch-plugin list)

    if ! echo "${INSTALLED_PLUGINS}" | grep -q "$1"
    then
      echo y | "${OPENSEARCH_HOME}"/bin/opensearch-plugin install "$2"
    fi

    echo "exposed plugins"
    INSTALLATION_PATH="${OPENSEARCH_HOME}/plugins/$1"
    ls -la ${INSTALLATION_PATH}

    echo "exposed conf"
    CONFIG_PATH="${OPENSEARCH_PATH_CONF}/$1"
    ls -la ${CONFIG_PATH}

    echo "confined dir"
    ls -la ${SNAP}/config/

    for path in "${INSTALLATION_PATH}" "${CONFIG_PATH}"; do
        chmod -R 770 "${path}"
        chown -R snap_daemon:snap_daemon "${path}"
    done

}


# installed the security plugin if not already
SECURITY_PLUGIN_URL="${PLUGINS_URL}/security/opensearch-security-${PROJECT_VERSION}.0.zip"
install_plugin "opensearch-security" "${SECURITY_PLUGIN_URL}"
