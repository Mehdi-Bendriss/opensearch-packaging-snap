#!/usr/bin/env bash

set -eux


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

function dir_copy_if_not_exists () {
    cp -R -n -r -p "${SNAP}/$1" "$2"

    if [[ $# -eq 3 ]]; then
        set_access_restrictions "$2/$1" "$3"
    else
        set_access_restrictions "$2/$1"
    fi
}

function set_property_if_not_exists () {
    if ! grep -q "^$2" "$1";
    then
        sed -i "s@.*$2.*@$3@" "$1"
    fi
}

dir_copy_if_not_exists "bin" "${SNAP_DATA}" 770
dir_copy_if_not_exists "jdk" "${SNAP_DATA}" 770
dir_copy_if_not_exists "lib" "${SNAP_DATA}" 550
dir_copy_if_not_exists "modules" "${SNAP_DATA}" 550
dir_copy_if_not_exists "plugins" "${SNAP_DATA}" 770

dir_copy_if_not_exists "config" "${SNAP_COMMON}"

add_folder "${SNAP_COMMON}/data" 770
add_folder "${SNAP_COMMON}/logs" 774
add_folder "${SNAP_COMMON}/tmp" 770

set_property_if_not_exists "${SNAP_COMMON}/config/opensearch.yml" "path.data:" "path.data: ${SNAP_COMMON}/data"
set_property_if_not_exists "${SNAP_COMMON}/config/opensearch.yml" "path.logs:" "path.logs: ${SNAP_COMMON}/logs"
