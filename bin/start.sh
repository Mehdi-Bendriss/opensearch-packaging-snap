#!/usr/bin/env bash

"${SNAP}"/usr/bin/setpriv \
  --clear-groups \
  --reuid snap_daemon \
  --regid snap_daemon -- \
  "${OPENSEARCH_PATH_CONF}" "${SNAP_DATA}"/bin/opensearch
