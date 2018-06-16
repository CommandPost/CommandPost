#!/bin/bash
xattr -cr scripts/inc/uninstall/Uninstall\ CommandPost.app
codesign --verbose --force --sign "Developer ID Application: LateNite Films Pty Ltd" scripts/inc/uninstall/Uninstall\ CommandPost.app
codesign -dv --verbose=4 scripts/inc/uninstall/Uninstall\ CommandPost.app