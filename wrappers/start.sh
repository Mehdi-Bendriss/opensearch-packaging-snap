#!/usr/bin/env bash

set -eux

DAEMON_SYSTEMD_PATH="/etc/systemd/system/snap.${PROJECT_NAME}.daemon.service.d"
script_log="${DAEMON_SYSTEMD_PATH}"/start.log
exec 1>>$script_log
exec 2>&1


export ES_TMPDIR=${ES_TMPDIR}

# start
"${SNAP}"/usr/bin/setpriv \
  --clear-groups \
  --reuid snap_daemon \
  --regid snap_daemon -- \
  "${OPENSEARCH_PATH_CONF}" "${OPENSEARCH_HOME}"/bin/opensearch
