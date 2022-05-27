#!/bin/bash

#
# COMMANDPOST BUILD RELEASE SCRIPT:
#

set -eu
set -o pipefail

#
# Define Variables:
#

export SENTRY_ORG=commandpost
export SENTRY_PROJECT=commandpost
export SENTRY_LOG_LEVEL=debug

export SCRIPT_HOME ; SCRIPT_HOME="$(dirname "$(greadlink -f "$0")")"
export COMMANDPOST_HOME ; COMMANDPOST_HOME="$(greadlink -f "${SCRIPT_HOME}/../")"
export VERSION ; VERSION=$(cd "${COMMANDPOST_HOME}/../CommandPost-App/" || fail "Unable to enter ${COMMANDPOST_HOME}/../CommandPost-App/" ; git describe --abbrev=0)

echo " * Moving to CommandPost-App Directory..."
cd "${COMMANDPOST_HOME}/../CommandPost-App/"

echo " * Notorizing DMG..."
./scripts/build.sh notarize -z "${COMMANDPOST_HOME}/../CommandPost-Releases/${VERSION}/CommandPost_${VERSION}.dmg"

echo " * CommandPost has been successfully built!"