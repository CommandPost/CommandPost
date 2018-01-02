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
HAMMERSPOON_HOME="$(greadlink -f "${SCRIPT_HOME}/../")" # fully qualified directory of the parent directiry of the script location

# Import our function library
# shellcheck source=scripts/librelease.sh disable=SC1091
source "${SCRIPT_HOME}/inc/librelease.sh"

build # run the build function from librelease

# clean up the unsigned build
rm -fr "$(xcodebuild -workspace Hammerspoon.xcworkspace -scheme Hammerspoon -configuration Release -showBuildSettings | sort | uniq | grep " BUILT_PRODUCTS_DIR =" | awk '{ print $3 }')/CommandPost.app"

#
# Sign App with self-signed certificate:
#
codesign --verbose --sign "Internal Code Signing" "build/CommandPost.app/Contents/Frameworks/Sparkle.framework/Versions/A"
codesign --verbose --sign "Internal Code Signing" "build/CommandPost.app/Contents/Frameworks/LuaSkin.framework/Versions/A"
codesign --verbose --sign "Internal Code Signing" "build/CommandPost.app"
