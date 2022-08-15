#!/usr/bin/env bash

set -eux

DAEMON_SYSTEMD_PATH="/etc/systemd/system/snap.opensearch.daemon.service.d"
script_log="${DAEMON_SYSTEMD_PATH}"/start.log
exec 1>>$script_log
exec 2>&1


function disable_security_plugin () {
    key="plugins.security.disabled:"
    conf_file="${OPENSEARCH_PATH_CONF}/opensearch.yml"

    if ! grep -q "^${key}" "${conf_file}";
    then
        sed -i "s@.*${key}.*@${key}: true@" "${conf_file}"
    fi
}

disable_security_plugin

export OPENSEARCH_TMPDIR=${OPENSEARCH_TMPDIR}

# start
"${SNAP}"/usr/bin/setpriv \
  --clear-groups \
  --reuid snap_daemon \
  --regid snap_daemon -- \
  "${OPENSEARCH_HOME}"/bin/opensearch
