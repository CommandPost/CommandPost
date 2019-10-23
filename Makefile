
SHELL 		= /bin/bash

# list of executables required for the makefile to run.
EXECUTABLES = defaults luarocks unlink busted
K := $(foreach exec,$(EXECUTABLES),\
    	$(if $(shell which $(exec)),some string,$(error No `$(exec)` in PATH)))

BundleID	= org.latenitefilms.CommandPost
APP_SUPPORT_PATH	= ~/Library/Application\ Support
CP_PATH		= $(APP_SUPPORT_PATH)/CommandPost
BID_PATH	= $(APP_SUPPORT_PATH)/$(BundleID)
EXT_PATH	= $(CP_PATH)/Extensions
PLUGIN_PATH = $(CP_PATH)/Plugins
PREFS_PATH	= ~/Library/Preferences
PREFS_FILE	= $(PREFS_PATH)/$(BundleID).plist

CACHES_PATH	= ~/Library/Caches
CACHES		= $(CACHES_PATH)/$(BundleID) $(CACHES_PATH)/io.fabric.sdk.mac.data/$(BundleID)  $(CACHES_PATH)/com.crashlytics.data/$(BundleID) $(CACHES_PATH)/com.apple.nsurlsessiond/Downloads/$(BundleID) ~/Library/WebKit/$(BundleID)

.PHONY: appscripts devscripts trashprefs trashsupport trashcaches

test:
	@busted --help

devscripts: $(PLUGIN_PATH)
	@defaults write $(BundleID) MJConfigFile "${PWD}/src/extensions/init.lua"
	@echo "CommandPost will load extensions and plugins from GitHub '${PWD}/src' folders."

appscripts:
	@defaults delete $(BundleID) MJConfigFile
	@echo "CommandPost will load extensions and plugins from the bundled sources."

trashprefs:
	@echo "Trashing CommandPost Preferences..."
	@defaults delete $(PREFS_FILE)
	@rm $(PREFS_FILE)

trashsupport:
	@echo "Trashing CommandPost Application Support..."
	#@rm -R $(CP_PATH)
	#@rm -R $(BID_PATH)

trashcaches:
	echo "Trashing Caches..."
	$(foreach cache,$(CACHES),\
    	$(shell rm -R $(cache))
