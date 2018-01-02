#!/bin/bash
# failsafes
set -eu
set -o pipefail
#
# Compile CommandPost:
#

# set directory variables
# export SCRIPT_NAME
export SCRIPT_HOME
export HAMMERSPOON_HOME

# SCRIPT_NAME="$(basename "$0")"
SCRIPT_HOME="$(dirname "$(greadlink -f "$0")")" # fully qualified directory of this script
HAMMERSPOON_HOME="$(greadlink -f "${SCRIPT_HOME}/../../CommandPost-App")" # fully qualified directory of the CommandPost-App repository

# Import our function library
# shellcheck source=scripts/inc/librelease.sh disable=SC1091
source "${SCRIPT_HOME}/inc/librelease.sh"

build_hammerspoon_dev # run the build-dev function from librelease

# clean up the unsigned build
rm -fr "$(xcodebuild -workspace ${HAMMERSPOON_HOME}/Hammerspoon.xcworkspace -scheme Hammerspoon -configuration Release -showBuildSettings | sort | uniq | grep " BUILT_PRODUCTS_DIR =" | awk '{ print $3 }')/CommandPost.app"

#
# Sign App with self-signed certificate:
#
codesign --verbose --sign "Internal Code Signing" "${HAMMERSPOON_HOME}/build/CommandPost.app/Contents/Frameworks/Sparkle.framework/Versions/A"
codesign --verbose --sign "Internal Code Signing" "${HAMMERSPOON_HOME}/build/CommandPost.app/Contents/Frameworks/LuaSkin.framework/Versions/A"
codesign --verbose --sign "Internal Code Signing" "${HAMMERSPOON_HOME}/build/CommandPost.app"
