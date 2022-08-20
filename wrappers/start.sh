#!/usr/bin/env bash

set -eux


function snap_logging () {
    SNAP_ACTIONS_LOG_DIR="/etc/systemd/system/snap.${PROJECT_NAME}.daemon.service.d/logs"

    script_log="${SNAP_ACTIONS_LOG_DIR}/$1.log"
    exec 1>>"${script_log}"
    exec 2>&1
}


function disable_security_plugin () {
    key="plugins.security.disabled:"
    conf_file="${OPENSEARCH_PATH_CONF}/opensearch.yml"

    if grep -q "^${key}" "${conf_file}";
    then
        sed -i "s@.*${key}.*@${key} true@" "${conf_file}"
    else
        echo "${key} true" >> "${conf_file}"
    fi
}

snap_logging "service-start"

disable_security_plugin

export OPENSEARCH_TMPDIR=${OPENSEARCH_TMPDIR}

# start
"${SNAP}"/usr/bin/setpriv \
  --clear-groups \
  --reuid snap_daemon \
  --regid snap_daemon -- \
  "${OPENSEARCH_HOME}"/bin/opensearch
