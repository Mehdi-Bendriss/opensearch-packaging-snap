#!/usr/bin/env bash

BASE_URL="https://opensearch-builds.s3.eu-west-1.amazonaws.com"
PLUGINS_URL="${BASE_URL}/plugins"

# Fetch the list of installed plugins
INSTALLED_PLUGINS=$("${SNAP_HOME}"/bin/elasticsearch-plugin list)

# install the security plugin if not installed already
SECURITY_PLUGIN_URL="${PLUGINS_URL}/security/opensearch-security-${SNAPCRAFT_PROJECT_VERSION}.0.zip"

if echo "${INSTALLED_PLUGINS}" | grep -q
then
  echo y | bin/opensearch-plugin install "${SECURITY_PLUGIN_URL}"
fi

