#!/usr/bin/env bash

set -eux

source "${OPS_ROOT}"/helpers/snap-logger.sh "daemon"


# system config
if ! snapctl is-connected systemd-write;
then
    echo "Please run the following command: sudo snap connect opensearch:systemd-write"
    echo "Then run: sudo snap restart opensearch.daemon"
    exit 1
fi


# start
"${SNAP}"/usr/bin/setpriv \
    --clear-groups \
    --reuid snap_daemon \
    --regid snap_daemon -- \
    "${OPENSEARCH_HOME}"/bin/opensearch
