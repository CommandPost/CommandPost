#!/bin/bash

#
# Trash CommandPost Preferences, Settings & Caches:
#
echo "Trashing Preferences..."
/usr/bin/defaults delete ~/Library/Preferences/org.latenitefilms.CommandPost.plist
rm ~/Library/Preferences/org.latenitefilms.CommandPost.plist

echo "Trashing Application Support..."
rm -R ~/Library/Application\ Support/CommandPost
rm -R ~/Library/Application\ Support/org.latenitefilms.CommandPost

echo "Trashing Caches..."
rm -R ~/Library/Caches/org.latenitefilms.CommandPost
rm -R ~/Library/WebKit/org.latenitefilms.CommandPost
rm -R ~/Library/Caches/io.fabric.sdk.mac.data/org.latenitefilms.CommandPost
rm -R ~/Library/Caches/com.crashlytics.data/org.latenitefilms.CommandPost
rm -R ~/Library/Caches/com.apple.nsurlsessiond/Downloads/org.latenitefilms.CommandPost