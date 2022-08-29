#!/usr/bin/env bash

set -eux


function disable_security_plugin () {
    key="plugins.security.disabled:"
    conf_file="${OPENSEARCH_PATH_CONF}/opensearch.yml"

    if grep -q "^#\?\s*${key}" "${conf_file}";
    then
        sed -i "s@.*${key}.*@${key} true@" "${conf_file}"
    else
        echo "${key} true" >> "${conf_file}"
    fi
}


# -------------------------------

# system config
if ! snapctl is-connected systemd-write;
then
    echo "Please run the following command: sudo snap connect opensearch:systemd-write"
    echo "Then run: sudo snap restart opensearch.daemon"
    exit 1
fi

source "${OPS_ROOT}"/helpers/snap-logger.sh "daemon"

# source snap_logging "daemon"

# ---------------------------------

disable_security_plugin

# start
"${SNAP}"/usr/bin/setpriv \
    --clear-groups \
    --reuid snap_daemon \
    --regid snap_daemon -- \
    "${OPENSEARCH_HOME}"/bin/opensearch
