#!/usr/bin/env bash


function snap_logging () {
    SNAP_ACTIONS_LOG_DIR="/etc/systemd/system/snap.${PROJECT_NAME}.daemon.service.d/logs"

    script_log="${SNAP_ACTIONS_LOG_DIR}/$1.log"
    exec 1>>"${script_log}"
    exec 2>&1
}

snap_logging "list-plugins"


# Fetch the list of installed plugins
INSTALLED_PLUGINS=$("${OPENSEARCH_HOME}"/bin/opensearch-plugin list)
echo "${INSTALLED_PLUGINS}"