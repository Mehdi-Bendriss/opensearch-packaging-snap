#!/usr/bin/env bash

set -eux


DAEMON_SYSTEMD_PATH="/etc/systemd/system/snap.opensearch.daemon.service.d"
mkdir -p "${DAEMON_SYSTEMD_PATH}"

script_log="${DAEMON_SYSTEMD_PATH}"/prepare-resources.log
exec 1>>"${script_log}"
exec 2>&1


function set_access_restrictions () {
    if [[ $# -eq 2 ]]; then
        chmod -R "$2" "$1"
    fi
    chown -R snap_daemon:snap_daemon "$1"
}

function add_folder () {
    mkdir -p "$1"
    set_access_restrictions "$1" "$2"
}

function add_file () {
    touch "$1"
    set_access_restrictions "$1" "$2"
}

function dir_copy_if_not_exists () {
    cp -R -n -r -p "${SNAP}/$1" "$2"

    if [[ $# -eq 3 ]]; then
        set_access_restrictions "$2/$1" "$3"
    else
        set_access_restrictions "$2/$1"
    fi
}

function set_property_line_if_not_exists () {
    if ! grep -q "^$2" "$1";
    then
        sed -i "s@.*$2.*@$3@" "$1"
    fi
}

function set_property () {
    sed -i "s@$2@$3@" "$1"
}

dir_copy_if_not_exists "bin" "${SNAP_DATA}" 770
dir_copy_if_not_exists "jdk" "${SNAP_DATA}" 770
dir_copy_if_not_exists "lib" "${SNAP_DATA}" 550
dir_copy_if_not_exists "modules" "${SNAP_DATA}" 550
dir_copy_if_not_exists "plugins" "${SNAP_DATA}" 770

dir_copy_if_not_exists "config" "${SNAP_COMMON}" 770

add_folder "${SNAP_COMMON}/data" 770
add_folder "${SNAP_COMMON}/logs" 774
add_folder "${SNAP_COMMON}/tmp" 770

set_property_line_if_not_exists "${SNAP_COMMON}/config/opensearch.yml" "path.data:" "path.data: ${SNAP_COMMON}/data"
set_property_line_if_not_exists "${SNAP_COMMON}/config/opensearch.yml" "path.logs:" "path.logs: ${SNAP_COMMON}/logs"

# add_file "${SNAP_COMMON}/logs/gc.log" 774

set_property "${SNAP_COMMON}/config/jvm.options" "=logs/" "=${SNAP_COMMON}/logs/"

echo "SNAP_COMMON"
ls -la ${SNAP_COMMON}

echo "-----"

echo "SNAP_DATA"
ls -la ${SNAP_DATA}
