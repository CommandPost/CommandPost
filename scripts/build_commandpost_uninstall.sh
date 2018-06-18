#!/bin/bash
rm -rf scripts/inc/uninstall/Uninstall\ CommandPost.app
osacompile -x -o scripts/inc/uninstall/Uninstall\ CommandPost.app scripts/inc/uninstall/Uninstall\ CommandPost.scpt
cp scripts/inc/uninstall/applet.icns scripts/inc/uninstall/Uninstall\ CommandPost.app/Contents/Resources/applet.icns
xattr -cr scripts/inc/uninstall/Uninstall\ CommandPost.app
codesign --verbose --force --sign "Developer ID Application: LateNite Films Pty Ltd" scripts/inc/uninstall/Uninstall\ CommandPost.app
codesign -dv --verbose=4 scripts/inc/uninstall/Uninstall\ CommandPost.app