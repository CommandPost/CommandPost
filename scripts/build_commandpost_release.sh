#!/bin/bash

#
# Compile CommandPost:
#

cd ../CommandPost-App/

make clean
make release
make docs

rm -fr `xcodebuild -workspace Hammerspoon.xcworkspace -scheme Hammerspoon -configuration DEBUG -showBuildSettings | sort | uniq | grep " BUILT_PRODUCTS_DIR =" | awk '{ print $3 }'`/CommandPost.app