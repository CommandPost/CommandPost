#!/bin/sh

### This script will instruct CommandPost to use the developer source directory as the location for extensions and plugins.

CP_PATH="$HOME/Library/Application Support/CommandPost"
EXT_PATH="$CP_PATH/Extensions"
PLUGIN_PATH="$CP_PATH/Plugins"

if [ -L "$EXT_PATH" ]; then
	echo "Unlinking existing CommandPost extensions."
	unlink "$EXT_PATH"
fi

if [ -L "$PLUGIN_PATH" ]; then
	echo "Unlinking existing CommandPost plugins."
	unlink "$PLUGIN_PATH"
fi

if [ ! -d "$PLUGIN_PATH" ]; then
	echo "Creating empty Plugin path."
	mkdir -p "$PLUGIN_PATH"
fi

defaults write org.latenitefilms.CommandPost MJConfigFile "$PWD/src/extensions/init.lua"

echo "CommandPost will load extensions and plugins from GitHub 'src' folders."