--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  			  ===========================================
--
--  			             F C P X    H A C K S
--
--			      ===========================================
--
--
--  Thrown together by Chris Hocking @ LateNite Films
--  https://latenitefilms.com
--
--  You can download the latest version here:
--  https://latenitefilms.com/blog/final-cut-pro-hacks/
--
--  Please be aware that I'm a filmmaker, not a programmer, so... apologies!
--
--------------------------------------------------------------------------------
--  LICENSE:
--------------------------------------------------------------------------------
--
-- The MIT License (MIT)
--
-- Copyright (c) 2016 Chris Hocking.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   T H E    M A I N    S C R I P T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- BEGIN MODULE:
--------------------------------------------------------------------------------

local mod = {}

--------------------------------------------------------------------------------
-- STANDARD EXTENSIONS:
--------------------------------------------------------------------------------

local application								= require("hs.application")
local base64									= require("hs.base64")
local chooser									= require("hs.chooser")
local console									= require("hs.console")
local distributednotifications					= require("hs.distributednotifications")
local drawing 									= require("hs.drawing")
local eventtap									= require("hs.eventtap")
local fnutils 									= require("hs.fnutils")
local fs										= require("hs.fs")
local geometry									= require("hs.geometry")
local host										= require("hs.host")
local hotkey									= require("hs.hotkey")
local http										= require("hs.http")
local image										= require("hs.image")
local inspect									= require("hs.inspect")
local keycodes									= require("hs.keycodes")
local logger									= require("hs.logger")
local menubar									= require("hs.menubar")
local messages									= require("hs.messages")
local mouse										= require("hs.mouse")
local notify									= require("hs.notify")
local osascript									= require("hs.osascript")
local pasteboard								= require("hs.pasteboard")
local pathwatcher								= require("hs.pathwatcher")
local screen									= require("hs.screen")
local settings									= require("hs.settings")
local sharing									= require("hs.sharing")
local timer										= require("hs.timer")
local window									= require("hs.window")
local windowfilter								= require("hs.window.filter")

--------------------------------------------------------------------------------
-- EXTERNAL EXTENSIONS:
--------------------------------------------------------------------------------

local ax 										= require("hs._asm.axuielement")

local fcp										= require("hs.finalcutpro")
local plist										= require("hs.plist")

--------------------------------------------------------------------------------
-- MODULES:
--------------------------------------------------------------------------------

local metadata									= require("hs.fcpxhacks.metadata")
local dialog									= require("hs.fcpxhacks.modules.dialog")
local slaxdom 									= require("hs.fcpxhacks.modules.slaxml.slaxdom")
local slaxml									= require("hs.fcpxhacks.modules.slaxml")
local tools										= require("hs.fcpxhacks.modules.tools")
local just										= require("hs.just")

--------------------------------------------------------------------------------
-- PLUGINS:
--------------------------------------------------------------------------------

local clipboard									= require("hs.fcpxhacks.modules.clipboard")
local hacksconsole								= require("hs.fcpxhacks.modules.hacksconsole")
local hackshud									= require("hs.fcpxhacks.modules.hackshud")
local voicecommands 							= require("hs.fcpxhacks.modules.voicecommands")

local shortcut									= require("hs.commands.shortcut")

--------------------------------------------------------------------------------
-- DEFAULT SETTINGS:
--------------------------------------------------------------------------------

local defaultSettings = {
												["enableHacksShortcutsInFinalCutPro"] 			= false,
												["enableVoiceCommands"]							= false,
												["chooserRememberLast"]							= true,
												["chooserShowShortcuts"] 						= true,
												["chooserShowHacks"] 							= true,
												["chooserShowVideoEffects"] 					= true,
												["chooserShowAudioEffects"] 					= true,
												["chooserShowTransitions"] 						= true,
												["chooserShowTitles"] 							= true,
												["chooserShowGenerators"] 						= true,
												["chooserShowMenuItems"]						= true,
												["menubarToolsEnabled"] 						= true,
												["menubarHacksEnabled"] 						= true,
												["enableCheckForUpdates"]						= true,
												["hudShowInspector"]							= true,
												["hudShowDropTargets"]							= true,
												["hudShowButtons"]								= true,
												["checkForUpdatesInterval"]						= 600,
												["notificationPlatform"]						= {},
}

--------------------------------------------------------------------------------
-- VARIABLES:
--------------------------------------------------------------------------------

local execute									= hs.execute									-- Execute!
local log										= logger.new("fcpx10-3")

mod.debugMode									= false											-- Debug Mode is off by default.
mod.releaseColorBoardDown						= false											-- Color Board Shortcut Currently Being Pressed
mod.shownUpdateNotification		 				= false											-- Shown Update Notification Already?

mod.finalCutProShortcutKey 						= nil											-- Table of all Final Cut Pro Shortcuts
mod.finalCutProShortcutKeyPlaceholders 			= nil											-- Table of all needed Final Cut Pro Shortcuts
mod.newDeviceMounted 							= nil											-- New Device Mounted Volume Watcher
mod.lastCommandSet								= nil											-- Last Keyboard Shortcut Command Set
mod.allowMovingMarkers							= nil											-- Used in generateMenuBar
mod.FFPeriodicBackupInterval 					= nil											-- Used in generateMenuBar
mod.FFSuspendBGOpsDuringPlay 					= nil											-- Used in generateMenuBar
mod.FFEnableGuards								= nil											-- Used in generateMenuBar
mod.FFAutoRenderDelay							= nil											-- Used in generateMenuBar

mod.hacksLoaded 								= false											-- Has FCPX Hacks Loaded Yet?

mod.isFinalCutProActive 						= false											-- Is Final Cut Pro Active? Used by Watchers.
mod.wasFinalCutProOpen							= false											-- Used by Assign Transitions/Effects/Titles/Generators Shortcut


--------------------------------------------------------------------------------
-- RETRIEVES THE PLUGINS MANAGER:
-- If `pluginPath` is provided, the named plugin will be returned. If not,
-- the plugins module is returned.
--------------------------------------------------------------------------------
function plugins(pluginPath)
	if not mod._plugins then
		mod._plugins = require("hs.plugins")
		mod._plugins.init("hs.fcpxhacks.plugins")
	end

	if pluginPath then
		return mod._plugins(pluginPath)
	else
		return mod._plugins
	end
end

--------------------------------------------------------------------------------
-- RETRIEVES THE MENU MANAGER:
--------------------------------------------------------------------------------
function menuManager()
	if not mod._menuManager then
		mod._menuManager = plugins("hs.fcpxhacks.plugins.menu.manager")

		--- TODO: Remove this once all menu manaement is migrated to plugins.
		local manualSection = mod._menuManager.addSection(10000)
		manualSection:addItems(0, function() return generateMenuBar(true) end)

		local preferences = plugins("hs.fcpxhacks.plugins.menu.preferences")
		preferences:addItems(10000, function() return generatePreferencesMenuBar() end)

		local menubarPrefs = plugins("hs.fcpxhacks.plugins.menu.preferences.menubar")
		menubarPrefs:addItems(10000, function() return generateMenubarPrefsMenuBar() end)
	end
	return mod._menuManager
end

--------------------------------------------------------------------------------
-- LOAD SCRIPT:
--------------------------------------------------------------------------------
function loadScript()

	--------------------------------------------------------------------------------
	-- Debug Mode:
	--------------------------------------------------------------------------------
	mod.debugMode = settings.get("fcpxHacks.debugMode") or false
	debugMessage("Debug Mode Activated.")

	--------------------------------------------------------------------------------
	-- Activate Menu Manager
	--------------------------------------------------------------------------------
	menuManager()

	--------------------------------------------------------------------------------
	-- Need Accessibility Activated:
	--------------------------------------------------------------------------------
	hs.accessibilityState(true)

	--------------------------------------------------------------------------------
	-- Limit Error Messages for a clean console:
	--------------------------------------------------------------------------------
	console.titleVisibility("hidden")
	hotkey.setLogLevel("warning")
	--windowfilter.setLogLevel(0) -- The wfilter errors are too annoying.
	--windowfilter.ignoreAlways['System Events'] = true

	--------------------------------------------------------------------------------
	-- First time running 10.3? If so, let's trash the settings incase there's
	-- compatibility issues with an older version of the script:
	--------------------------------------------------------------------------------
	if settings.get("fcpxHacks.firstTimeRunning103") == nil then

		writeToConsole("First time running Final Cut Pro 10.3. Trashing settings.")

		--------------------------------------------------------------------------------
		-- Trash all Script Settings:
		--------------------------------------------------------------------------------
		for i, v in ipairs(settings.getKeys()) do
			if (v:sub(1,10)) == "fcpxHacks." then
				settings.set(v, nil)
			end
		end

		settings.set("fcpxHacks.firstTimeRunning103", false)

	end

	--------------------------------------------------------------------------------
	-- Check for Final Cut Pro Updates:
	--------------------------------------------------------------------------------
	local lastFinalCutProVersion = settings.get("fcpxHacks.lastFinalCutProVersion")
	if lastFinalCutProVersion == nil then
		settings.set("fcpxHacks.lastFinalCutProVersion", fcp:getVersion())
	else
		if lastFinalCutProVersion ~= fcp:getVersion() then
			for i, v in ipairs(settings.getKeys()) do
				if (v:sub(1,10)) == "fcpxHacks." then
					if v:sub(-16) == "chooserMenuItems" then
						settings.set(v, nil)
					end
				end
			end
			settings.set("fcpxHacks.lastFinalCutProVersion", fcp:getVersion())
		end
	end

	--------------------------------------------------------------------------------
	-- Apply Default Settings:
	--------------------------------------------------------------------------------
	for k, v in pairs(defaultSettings) do
		if settings.get("fcpxHacks." .. k) == nil then
			settings.set("fcpxHacks." .. k, v)
		end
	end

	--------------------------------------------------------------------------------
	-- Setup Watches:
	--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Final Cut Pro Application Watcher:
		--------------------------------------------------------------------------------
		fcp:watch({
			active		= finalCutProActive,
			inactive	= finalCutProNotActive,
		})

		--------------------------------------------------------------------------------
		-- Final Cut Pro Window Watcher:
		--------------------------------------------------------------------------------
		finalCutProWindowWatcher()

		--------------------------------------------------------------------------------
		-- Watch For Hammerspoon Script Updates:
		--------------------------------------------------------------------------------
		local bundleID = hs.processInfo["bundleID"]
		if bundleID == "org.hammerspoon.Hammerspoon" then
			hammerspoonWatcher = pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hammerspoonConfigWatcher):start()
		end

		--------------------------------------------------------------------------------
		-- Watch for Final Cut Pro plist Changes:
		--------------------------------------------------------------------------------
		preferencesWatcher = pathwatcher.new("~/Library/Preferences/", finalCutProSettingsWatcher):start()

		--------------------------------------------------------------------------------
		-- Watch for Shared Clipboard Changes:
		--------------------------------------------------------------------------------
		local sharedClipboardPath = settings.get("fcpxHacks.sharedClipboardPath")
		if sharedClipboardPath ~= nil then
			if tools.doesDirectoryExist(sharedClipboardPath) then
				sharedClipboardWatcher = pathwatcher.new(sharedClipboardPath, sharedClipboardFileWatcher):start()
			else
				writeToConsole("The Shared Clipboard Directory could not be found, so disabling.")
				settings.set("fcpxHacks.sharedClipboardPath", nil)
				settings.set("fcpxHacks.enableSharedClipboard", false)
			end
		end

		--------------------------------------------------------------------------------
		-- Watch for Shared XML Changes:
		--------------------------------------------------------------------------------
		local enableXMLSharing = settings.get("fcpxHacks.enableXMLSharing") or false
		if enableXMLSharing then
			local xmlSharingPath = settings.get("fcpxHacks.xmlSharingPath")
			if xmlSharingPath ~= nil then
				if tools.doesDirectoryExist(xmlSharingPath) then
					sharedXMLWatcher = pathwatcher.new(xmlSharingPath, sharedXMLFileWatcher):start()
				else
					writeToConsole("The Shared XML Folder(s) could not be found, so disabling.")
					settings.set("fcpxHacks.xmlSharingPath", nil)
					settings.set("fcpxHacks.enableXMLSharing", false)
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Clipboard Watcher:
		--------------------------------------------------------------------------------
		local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false
		local enableSharedClipboard = settings.get("fcpxHacks.enableSharedClipboard") or false
		if enableClipboardHistory or enableSharedClipboard then clipboard.startWatching() end

		--------------------------------------------------------------------------------
		-- Notification Watcher:
		--------------------------------------------------------------------------------
		local notificationPlatform = settings.get("fcpxHacks.notificationPlatform")
		if next(notificationPlatform) ~= nil then notificationWatcher() end

	--------------------------------------------------------------------------------
	-- Bind Keyboard Shortcuts:
	--------------------------------------------------------------------------------
	mod.lastCommandSet = fcp:getActiveCommandSetPath()
	bindKeyboardShortcuts()

	--------------------------------------------------------------------------------
	-- Load Hacks HUD:
	--------------------------------------------------------------------------------
	if settings.get("fcpxHacks.enableHacksHUD") then
		hackshud.new()
	end

	--------------------------------------------------------------------------------
	-- Activate the correct modal state:
	--------------------------------------------------------------------------------
	if fcp:isFrontmost() then
		--------------------------------------------------------------------------------
		-- Used by Watchers to prevent double-ups:
		--------------------------------------------------------------------------------
		mod.isFinalCutProActive = true

		--------------------------------------------------------------------------------
		-- Enable Final Cut Pro Shortcut Keys:
		--------------------------------------------------------------------------------
		hotkeys:enter()

		--------------------------------------------------------------------------------
		-- Show Hacks HUD:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableHacksHUD") then
			hackshud.show()
		end

		--------------------------------------------------------------------------------
		-- Enable Voice Commands:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableVoiceCommands") then
			voicecommands.start()
		end

	else
		--------------------------------------------------------------------------------
		-- Used by Watchers to prevent double-ups:
		--------------------------------------------------------------------------------
		mod.isFinalCutProActive = false

		--------------------------------------------------------------------------------
		-- Disable Final Cut Pro Shortcut Keys:
		--------------------------------------------------------------------------------
		hotkeys:exit()
	end

	-------------------------------------------------------------------------------
	-- Set up Chooser:
	-------------------------------------------------------------------------------
	hacksconsole.new()

	--------------------------------------------------------------------------------
	-- All loaded!
	--------------------------------------------------------------------------------
	writeToConsole("Successfully loaded.")
	dialog.displayNotification(metadata.scriptName .. " (v" .. metadata.scriptVersion .. ") " .. i18n("hasLoaded"))

	--------------------------------------------------------------------------------
	-- Check for Script Updates:
	--------------------------------------------------------------------------------
	local checkForUpdatesInterval = settings.get("fcpxHacks.checkForUpdatesInterval")
	checkForUpdatesTimer = timer.doEvery(checkForUpdatesInterval, checkForUpdates)
	checkForUpdatesTimer:fire()

	mod.hacksLoaded = true

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   D E V E L O P M E N T      T O O L S                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- TESTING GROUND (CONTROL + OPTION + COMMAND + Q):
--------------------------------------------------------------------------------
function testingGround()

	--------------------------------------------------------------------------------
	-- Clear Console:
	--------------------------------------------------------------------------------
	--console.clearConsole()

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    K E Y B O A R D     S H O R T C U T S                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- DEFAULT SHORTCUT KEYS:
--------------------------------------------------------------------------------
function defaultShortcutKeys()

	local control					= {"ctrl"}
	local controlShift 				= {"ctrl", "shift"}
	local controlOptionCommand 		= {"ctrl", "option", "command"}
	local controlOptionCommandShift = {"ctrl", "option", "command", "shift"}

    local defaultShortcutKeys = {
        FCPXHackChangeBackupInterval                                = { characterString = shortcut.textToKeyCode("b"),            modifiers = controlOptionCommand,                   fn = function() changeBackupInterval() end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackToggleTimecodeOverlays                              = { characterString = shortcut.textToKeyCode("t"),            modifiers = controlOptionCommand,                   fn = function() toggleTimecodeOverlay() end,                        releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackToggleMovingMarkers                                 = { characterString = shortcut.textToKeyCode("y"),            modifiers = controlOptionCommand,                   fn = function() toggleMovingMarkers() end,                          releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackAllowTasksDuringPlayback                            = { characterString = shortcut.textToKeyCode("p"),            modifiers = controlOptionCommand,                   fn = function() togglePerformTasksDuringPlayback() end,             releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackSelectColorBoardPuckOne                             = { characterString = shortcut.textToKeyCode("m"),            modifiers = controlOptionCommand,                   fn = function() colorBoardSelectPuck("*", "global") end,            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectColorBoardPuckTwo                             = { characterString = shortcut.textToKeyCode(","),            modifiers = controlOptionCommand,                   fn = function() colorBoardSelectPuck("*", "shadows") end,           releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectColorBoardPuckThree                           = { characterString = shortcut.textToKeyCode("."),            modifiers = controlOptionCommand,                   fn = function() colorBoardSelectPuck("*", "midtones") end,          releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectColorBoardPuckFour                            = { characterString = shortcut.textToKeyCode("/"),            modifiers = controlOptionCommand,                   fn = function() colorBoardSelectPuck("*", "highlights") end,        releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackRestoreKeywordPresetOne                             = { characterString = shortcut.textToKeyCode("1"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(1) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetTwo                             = { characterString = shortcut.textToKeyCode("2"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(2) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetThree                           = { characterString = shortcut.textToKeyCode("3"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(3) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetFour                            = { characterString = shortcut.textToKeyCode("4"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(4) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetFive                            = { characterString = shortcut.textToKeyCode("5"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(5) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetSix                             = { characterString = shortcut.textToKeyCode("6"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(6) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetSeven                           = { characterString = shortcut.textToKeyCode("7"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(7) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetEight                           = { characterString = shortcut.textToKeyCode("8"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(8) end,                      releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackRestoreKeywordPresetNine                            = { characterString = shortcut.textToKeyCode("9"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(9) end,                      releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackHUD                                                 = { characterString = shortcut.textToKeyCode("a"),            modifiers = controlOptionCommand,                   fn = function() toggleEnableHacksHUD() end,                         releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackChangeTimelineClipHeightUp                          = { characterString = shortcut.textToKeyCode("+"),            modifiers = controlOptionCommand,                   fn = function() changeTimelineClipHeight("up") end,                 releasedFn = function() changeTimelineClipHeightRelease() end,          repeatFn = nil },
        FCPXHackChangeTimelineClipHeightDown                        = { characterString = shortcut.textToKeyCode("-"),            modifiers = controlOptionCommand,                   fn = function() changeTimelineClipHeight("down") end,               releasedFn = function() changeTimelineClipHeightRelease() end,          repeatFn = nil },

        FCPXHackSelectForward                                       = { characterString = shortcut.textToKeyCode("right"),        modifiers = controlOptionCommand,                   fn = function() selectAllTimelineClips(true) end,                   releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectBackwards                                     = { characterString = shortcut.textToKeyCode("left"),         modifiers = controlOptionCommand,                   fn = function() selectAllTimelineClips(false) end,                  releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackSaveKeywordPresetOne                                = { characterString = shortcut.textToKeyCode("1"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(1) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetTwo                                = { characterString = shortcut.textToKeyCode("2"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(2) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetThree                              = { characterString = shortcut.textToKeyCode("3"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(3) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetFour                               = { characterString = shortcut.textToKeyCode("4"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(4) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetFive                               = { characterString = shortcut.textToKeyCode("5"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(5) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetSix                                = { characterString = shortcut.textToKeyCode("6"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(6) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetSeven                              = { characterString = shortcut.textToKeyCode("7"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(7) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetEight                              = { characterString = shortcut.textToKeyCode("8"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(8) end,                         releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSaveKeywordPresetNine                               = { characterString = shortcut.textToKeyCode("9"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(9) end,                         releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackConsole                                             = { characterString = shortcut.textToKeyCode("space"),        modifiers = control,                                fn = function() hacksconsole.show() end,							releasedFn = nil,                                     					repeatFn = nil },

		FCPXCopyWithCustomLabel			 							= { characterString = "",                                   modifiers = {},                                     fn = function() copyWithCustomLabel() end,                         	releasedFn = nil,                                                       repeatFn = nil },
		FCPXCopyWithCustomLabelAndFolder		 					= { characterString = "",                                   modifiers = {},                                     fn = function() copyWithCustomLabelAndFolder() end,                	releasedFn = nil,                                                       repeatFn = nil },

        FCPXAddNoteToSelectedClip	 								= { characterString = "",                                   modifiers = {},                                     fn = function() addNoteToSelectedClip() end,                        releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackMoveToPlayhead                                      = { characterString = "",                                   modifiers = {},                                     fn = function() moveToPlayhead() end,                               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackToggleVoiceCommands                                 = { characterString = "",                                   modifiers = {},                                     fn = function() toggleEnableVoiceCommands() end,                    releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackColorPuckOne                                        = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global") end,                    releasedFn = nil,                                           repeatFn = nil },
        FCPXHackColorPuckTwo                                        = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "shadows") end,                   releasedFn = nil,                                           repeatFn = nil },
        FCPXHackColorPuckThree                                      = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "midtones") end,                  releasedFn = nil,                                           repeatFn = nil },
        FCPXHackColorPuckFour                                       = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "highlights") end,                releasedFn = nil,                                           repeatFn = nil },

        FCPXHackSaturationPuckOne                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "global") end,               releasedFn = nil,                                           repeatFn = nil },
        FCPXHackSaturationPuckTwo                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "shadows") end,              releasedFn = nil,                                           repeatFn = nil },
        FCPXHackSaturationPuckThree                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "midtones") end,             releasedFn = nil,                                           repeatFn = nil },
        FCPXHackSaturationPuckFour                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "highlights") end,           releasedFn = nil,                                           repeatFn = nil },

        FCPXHackExposurePuckOne                                     = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "global") end,                 releasedFn = nil,                                           repeatFn = nil },
        FCPXHackExposurePuckTwo                                     = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "shadows") end,                releasedFn = nil,                                           repeatFn = nil },
        FCPXHackExposurePuckThree                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "midtones") end,               releasedFn = nil,                                           repeatFn = nil },
        FCPXHackExposurePuckFour                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "highlights") end,             releasedFn = nil,                                           repeatFn = nil },

        FCPXHackColorPuckOneUp                                      = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "up") end,              releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckTwoUp                                      = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "shadows", "up") end,             releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckThreeUp                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "midtones", "up") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckFourUp                                     = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "highlights", "up") end,          releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackColorPuckOneDown                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "down") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckTwoDown                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "shadows", "down") end,           releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckThreeDown                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "midtones", "down") end,          releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckFourDown                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "highlights", "down") end,        releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackColorPuckOneLeft                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "left") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckTwoLeft                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "left") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckThreeLeft                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "left") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckFourLeft                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "left") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackColorPuckOneRight                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "right") end,           releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckTwoRight                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "shadows", "right") end,          releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckThreeRight                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "midtones", "right") end,         releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackColorPuckFourRight                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "highlights", "right") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackSaturationPuckOneUp                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "global", "up") end,         releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackSaturationPuckTwoUp                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "shadows", "up") end,        releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackSaturationPuckThreeUp                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "midtones", "up") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackSaturationPuckFourUp                                = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "highlights", "up") end,     releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackSaturationPuckOneDown                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "global", "down") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackSaturationPuckTwoDown                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "shadows", "down") end,      releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackSaturationPuckThreeDown                             = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "midtones", "down") end,     releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackSaturationPuckFourDown                              = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "highlights", "down") end,   releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackExposurePuckOneUp                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "global", "up") end,           releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackExposurePuckTwoUp                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "shadows", "up") end,          releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackExposurePuckThreeUp                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "midtones", "up") end,         releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackExposurePuckFourUp                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "highlights", "up") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackExposurePuckOneDown                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "global", "down") end,         releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackExposurePuckTwoDown                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "shadows", "down") end,        releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackExposurePuckThreeDown                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "midtones", "down") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        FCPXHackExposurePuckFourDown                                = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "highlights", "down") end,     releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        FCPXHackChangeSmartCollectionsLabel                         = { characterString = "",                                   modifiers = {},                                     fn = function() changeSmartCollectionsLabel() end,                  releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackSelectClipAtLaneOne                                 = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(1) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneTwo                                 = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(2) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneThree                               = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(3) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneFour                                = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(4) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneFive                                = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(5) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneSix                                 = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(6) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneSeven                               = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(7) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneEight                               = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(8) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneNine                                = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(9) end,                            releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackSelectClipAtLaneTen                                 = { characterString = "",                                   modifiers = {},                                     fn = function() selectClipAtLane(10) end,                           releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackPuckOneMouse                                        = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("*", "global") end,             releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackPuckTwoMouse                                        = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("*", "shadows") end,            releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackPuckThreeMouse                                      = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("*", "midtones") end,           releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackPuckFourMouse                                       = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("*", "highlights") end,         releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },

        FCPXHackColorPuckOneMouse                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("color", "global") end,         releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackColorPuckTwoMouse                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("color", "shadows") end,        releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackColorPuckThreeMouse                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("color", "midtones") end,       releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackColorPuckFourMouse                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("color", "highlights") end,     releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },

        FCPXHackSaturationPuckOneMouse                              = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("saturation", "global") end,    releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackSaturationPuckTwoMouse                              = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("saturation", "shadows") end,   releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackSaturationPuckThreeMouse                            = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("saturation", "midtones") end,  releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackSaturationPuckFourMouse                             = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("saturation", "highlights") end,releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },

        FCPXHackExposurePuckOneMouse                                = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("exposure", "global") end,      releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackExposurePuckTwoMouse                                = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("exposure", "shadows") end,     releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackExposurePuckThreeMouse                              = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("exposure", "midtones") end,    releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        FCPXHackExposurePuckFourMouse                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("exposure", "highlights") end,  releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },

        FCPXHackCutSwitchAngle01Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 1) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle02Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 2) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle03Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 3) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle04Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 4) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle05Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 5) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle06Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 6) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle07Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 7) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle08Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 8) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle09Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 9) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle10Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 10) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle11Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 11) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle12Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 12) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle13Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 13) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle14Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 14) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle15Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 15) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle16Video                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Video", 16) end,              releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackCutSwitchAngle01Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 1) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle02Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 2) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle03Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 3) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle04Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 4) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle05Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 5) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle06Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 6) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle07Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 7) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle08Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 8) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle09Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 9) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle10Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 10) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle11Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 11) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle12Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 12) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle13Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 13) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle14Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 14) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle15Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 15) end,              releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle16Audio                               = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Audio", 16) end,              releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackCutSwitchAngle01Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 1) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle02Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 2) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle03Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 3) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle04Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 4) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle05Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 5) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle06Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 6) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle07Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 7) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle08Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 8) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle09Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 9) end,                releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle10Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 10) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle11Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 11) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle12Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 12) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle13Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 13) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle14Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 14) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle15Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 15) end,               releasedFn = nil,                                                       repeatFn = nil },
        FCPXHackCutSwitchAngle16Both                                = { characterString = "",                                   modifiers = {},                                     fn = function() cutAndSwitchMulticam("Both", 16) end,               releasedFn = nil,                                                       repeatFn = nil },
    }
	return defaultShortcutKeys
end

--------------------------------------------------------------------------------
-- BIND KEYBOARD SHORTCUTS:
--------------------------------------------------------------------------------
function bindKeyboardShortcuts()

	--------------------------------------------------------------------------------
	-- Get Enable Hacks Shortcuts in Final Cut Pro from Settings:
	--------------------------------------------------------------------------------
	local enableHacksShortcutsInFinalCutPro = settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro")
	if enableHacksShortcutsInFinalCutPro == nil then enableHacksShortcutsInFinalCutPro = false end

	--------------------------------------------------------------------------------
	-- Hacks Shortcuts Enabled:
	--------------------------------------------------------------------------------
	if enableHacksShortcutsInFinalCutPro then

		--------------------------------------------------------------------------------
		-- Get Shortcut Keys from plist:
		--------------------------------------------------------------------------------
		mod.finalCutProShortcutKey = nil
		mod.finalCutProShortcutKey = {}
		mod.finalCutProShortcutKeyPlaceholders = nil
		mod.finalCutProShortcutKeyPlaceholders = defaultShortcutKeys()

		--------------------------------------------------------------------------------
		-- Remove the default shortcut keys:
		--------------------------------------------------------------------------------
		for k, v in pairs(mod.finalCutProShortcutKeyPlaceholders) do
			mod.finalCutProShortcutKeyPlaceholders[k]["characterString"] = ""
			mod.finalCutProShortcutKeyPlaceholders[k]["modifiers"] = {}
		end

		--------------------------------------------------------------------------------
		-- If something goes wrong:
		--------------------------------------------------------------------------------
		if getShortcutsFromActiveCommandSet() ~= true then
			dialog.displayErrorMessage(i18n("customKeyboardShortcutsFailed"))
			enableHacksShortcutsInFinalCutPro = false
		end

	end

	--------------------------------------------------------------------------------
	-- Hacks Shortcuts Disabled:
	--------------------------------------------------------------------------------
	if not enableHacksShortcutsInFinalCutPro then

		--------------------------------------------------------------------------------
		-- Update Active Command Set:
		--------------------------------------------------------------------------------
		fcp:getActiveCommandSet(true)

		--------------------------------------------------------------------------------
		-- Use Default Shortcuts Keys:
		--------------------------------------------------------------------------------
		mod.finalCutProShortcutKey = nil
		mod.finalCutProShortcutKey = defaultShortcutKeys()

	end

	--------------------------------------------------------------------------------
	-- Reset Modal Hotkey for Final Cut Pro Commands:
	--------------------------------------------------------------------------------
	hotkeys = nil

	--------------------------------------------------------------------------------
	-- Reset Global Hotkeys:
	--------------------------------------------------------------------------------
	local currentHotkeys = hotkey.getHotkeys()
	for _,hk in ipairs(currentHotkeys) do
		-- only delete hotkeys which are not created by `hs.commands.shortcut`
		if not hk.shortcut then
			result = hk:delete()
		end
	end

	--------------------------------------------------------------------------------
	-- Create a modal hotkey object with an absurd triggering hotkey:
	--------------------------------------------------------------------------------
	hotkeys = hotkey.modal.new({"command", "shift", "alt", "control"}, "F19")

	--------------------------------------------------------------------------------
	-- Enable Hotkeys Loop:
	--------------------------------------------------------------------------------
	for k, v in pairs(mod.finalCutProShortcutKey) do
		if v['characterString'] ~= "" and v['fn'] ~= nil then
			if v['global'] == true then
				--------------------------------------------------------------------------------
				-- Global Shortcut:
				--------------------------------------------------------------------------------
				hotkey.bind(v['modifiers'], v['characterString'], v['fn'], v['releasedFn'], v['repeatFn'])
			else
				--------------------------------------------------------------------------------
				-- Final Cut Pro Specific Shortcut:
				--------------------------------------------------------------------------------
				hotkeys:bind(v['modifiers'], v['characterString'], v['fn'], v['releasedFn'], v['repeatFn'])
			end
		end
	end

	--------------------------------------------------------------------------------
	-- Development Shortcut:
	--------------------------------------------------------------------------------
	if mod.debugMode then
		hotkey.bind({"ctrl", "option", "command"}, "q", function() testingGround() end)
	end

	--------------------------------------------------------------------------------
	-- Enable Hotkeys:
	--------------------------------------------------------------------------------
	hotkeys:enter()

	--------------------------------------------------------------------------------
	-- Let user know that keyboard shortcuts have loaded:
	--------------------------------------------------------------------------------
	dialog.displayNotification(i18n("keyboardShortcutsUpdated"))

end

--------------------------------------------------------------------------------
-- READ SHORTCUT KEYS FROM FINAL CUT PRO PLIST:
--------------------------------------------------------------------------------
function getShortcutsFromActiveCommandSet()

	local activeCommandSetTable = fcp:getActiveCommandSet(true)

	if activeCommandSetTable ~= nil then
		for k, v in pairs(mod.finalCutProShortcutKeyPlaceholders) do
			local shortcuts = fcp:getCommandShortcuts(k)
			if shortcuts and #shortcuts > 0 then
				for x, shortcut in ipairs(shortcuts) do

					local global = v.global or false
					local xValue = ""
					if x ~= 1 then xValue = tostring(x) end
			
					mod.finalCutProShortcutKey[k .. xValue] = {
						characterString 	= 		shortcut:getKeyCode(),
						modifiers 			= 		shortcut:getModifiers(),
						fn 					= 		mod.finalCutProShortcutKeyPlaceholders[k]['fn'],
						releasedFn 			= 		mod.finalCutProShortcutKeyPlaceholders[k]['releasedFn'],
						repeatFn 			= 		mod.finalCutProShortcutKeyPlaceholders[k]['repeatFn'],
						global 				= 		global,
					}
				end
			end
		end
		return true
	else
		return false
	end

end

--------------------------------------------------------------------------------
-- UPDATE KEYBOARD SHORTCUTS:
--------------------------------------------------------------------------------
function updateKeyboardShortcuts()

	--------------------------------------------------------------------------------
	-- Update Keyboard Settings:
	--------------------------------------------------------------------------------
	local result = enableHacksShortcuts()
	if type(result) == "string" then
		dialog.displayErrorMessage(result)
		settings.set("fcpxHacks.enableHacksShortcutsInFinalCutPro", false)
		return false
	elseif result == false then
		--------------------------------------------------------------------------------
		-- NOTE: When Cancel is pressed whilst entering the admin password, let's
		-- just leave the old Hacks Shortcut Plist files in place.
		--------------------------------------------------------------------------------
		return
	end

end

--------------------------------------------------------------------------------
-- ENABLE HACKS SHORTCUTS:
--------------------------------------------------------------------------------
function enableHacksShortcuts()

	local finalCutProPath = fcp:getPath() .. "/Contents/Resources/"
	local finalCutProLanguages = fcp:getSupportedLanguages()
	local executeCommand = "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/new/"

	local executeStrings = {
		executeCommand .. "NSProCommandGroups.plist '" .. finalCutProPath .. "NSProCommandGroups.plist'",
		executeCommand .. "NSProCommands.plist '" .. finalCutProPath .. "NSProCommands.plist'",
	}

	for _, whichLanguage in ipairs(finalCutProLanguages) do
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/Default.commandset '" .. finalCutProPath .. whichLanguage .. ".lproj/Default.commandset'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandNames.strings '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandNames.strings'")
	end

	local result = tools.executeWithAdministratorPrivileges(executeStrings)
	return result

end

--------------------------------------------------------------------------------
-- DISABLE HACKS SHORTCUTS:
--------------------------------------------------------------------------------
function disableHacksShortcuts()

	local finalCutProPath = fcp:getPath() .. "/Contents/Resources/"
	local finalCutProLanguages = fcp:getSupportedLanguages()
	local executeCommand = "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/old/"

	local executeStrings = {
		executeCommand .. "NSProCommandGroups.plist '" .. finalCutProPath .. "NSProCommandGroups.plist'",
		executeCommand .. "NSProCommands.plist '" .. finalCutProPath .. "NSProCommands.plist'",
	}

	for _, whichLanguage in ipairs(finalCutProLanguages) do
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/Default.commandset '" .. finalCutProPath .. whichLanguage .. ".lproj/Default.commandset'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandNames.strings '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandNames.strings'")
	end

	local result = tools.executeWithAdministratorPrivileges(executeStrings)
	return result

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     M E N U B A R    F E A T U R E S                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- MENUBAR:
--------------------------------------------------------------------------------

	function generateMenuBar(refreshPlistValues)
		--------------------------------------------------------------------------------
		-- Maximum Length of Menubar Strings:
		--------------------------------------------------------------------------------
		local maxTextLength = 25

		--------------------------------------------------------------------------------
		-- Assume FCPX is closed if not told otherwise:
		--------------------------------------------------------------------------------
		local fcpxActive = fcp:isFrontmost()
		local fcpxRunning = fcp:isRunning()

		--------------------------------------------------------------------------------
		-- Current Language:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()

		--------------------------------------------------------------------------------
		-- We only refresh plist values if necessary as this takes time:
		--------------------------------------------------------------------------------
		if refreshPlistValues == true then

			--------------------------------------------------------------------------------
			-- Read Final Cut Pro Preferences:
			--------------------------------------------------------------------------------
			local preferences = fcp:getPreferences()
			if preferences == nil then
				dialog.displayErrorMessage(i18n("failedToReadFCPPreferences"))
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Get plist values for Allow Moving Markers:
			--------------------------------------------------------------------------------
			mod.allowMovingMarkers = false
			local result = plist.fileToTable(fcp:getPath() .. "/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist")
			if result ~= nil then
				if result["TLKMarkerHandler"] ~= nil then
					if result["TLKMarkerHandler"]["Configuration"] ~= nil then
						if result["TLKMarkerHandler"]["Configuration"]["Allow Moving Markers"] ~= nil then
							mod.allowMovingMarkers = result["TLKMarkerHandler"]["Configuration"]["Allow Moving Markers"]
						end
					end
				end
			end

			--------------------------------------------------------------------------------
			-- Get plist values for FFPeriodicBackupInterval:
			--------------------------------------------------------------------------------
			if preferences["FFPeriodicBackupInterval"] == nil then
				mod.FFPeriodicBackupInterval = "15"
			else
				mod.FFPeriodicBackupInterval = preferences["FFPeriodicBackupInterval"]
			end

			--------------------------------------------------------------------------------
			-- Get plist values for FFSuspendBGOpsDuringPlay:
			--------------------------------------------------------------------------------
			if preferences["FFSuspendBGOpsDuringPlay"] == nil then
				mod.FFSuspendBGOpsDuringPlay = false
			else
				mod.FFSuspendBGOpsDuringPlay = preferences["FFSuspendBGOpsDuringPlay"]
			end

			--------------------------------------------------------------------------------
			-- Get plist values for FFEnableGuards:
			--------------------------------------------------------------------------------
			if preferences["FFEnableGuards"] == nil then
				mod.FFEnableGuards = false
			else
				mod.FFEnableGuards = preferences["FFEnableGuards"]
			end

			--------------------------------------------------------------------------------
			-- Get plist values for FFAutoRenderDelay:
			--------------------------------------------------------------------------------
			if preferences["FFAutoRenderDelay"] == nil then
				mod.FFAutoRenderDelay = "0.3"
			else
				mod.FFAutoRenderDelay = preferences["FFAutoRenderDelay"]
			end

		end

		--------------------------------------------------------------------------------
		-- Get Enable Hacks Shortcuts in Final Cut Pro from Settings:
		--------------------------------------------------------------------------------
		local enableHacksShortcutsInFinalCutPro = settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro") or false

		--------------------------------------------------------------------------------
		-- Notification Platform:
		--------------------------------------------------------------------------------
		local notificationPlatform = settings.get("fcpxHacks.notificationPlatform")

		--------------------------------------------------------------------------------
		-- Enable XML Sharing:
		--------------------------------------------------------------------------------
		local enableXMLSharing 		= settings.get("fcpxHacks.enableXMLSharing") or false

		--------------------------------------------------------------------------------
		-- Enable Clipboard History:
		--------------------------------------------------------------------------------
		local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false

		--------------------------------------------------------------------------------
		-- Enable Shared Clipboard:
		--------------------------------------------------------------------------------
		local enableSharedClipboard = settings.get("fcpxHacks.enableSharedClipboard") or false

		--------------------------------------------------------------------------------
		-- Enable Hacks HUD:
		--------------------------------------------------------------------------------
		local enableHacksHUD 		= settings.get("fcpxHacks.enableHacksHUD") or false

		local hudButtonOne 			= settings.get("fcpxHacks." .. currentLanguage .. ".hudButtonOne") 	or " (Unassigned)"
		local hudButtonTwo 			= settings.get("fcpxHacks." .. currentLanguage .. ".hudButtonTwo") 	or " (Unassigned)"
		local hudButtonThree 		= settings.get("fcpxHacks." .. currentLanguage .. ".hudButtonThree") 	or " (Unassigned)"
		local hudButtonFour 		= settings.get("fcpxHacks." .. currentLanguage .. ".hudButtonFour") 	or " (Unassigned)"

		if hudButtonOne ~= " (Unassigned)" then		hudButtonOne = " (" .. 		tools.stringMaxLength(tools.cleanupButtonText(hudButtonOne["text"]),maxTextLength,"...") 	.. ")" end
		if hudButtonTwo ~= " (Unassigned)" then 	hudButtonTwo = " (" .. 		tools.stringMaxLength(tools.cleanupButtonText(hudButtonTwo["text"]),maxTextLength,"...") 	.. ")" end
		if hudButtonThree ~= " (Unassigned)" then 	hudButtonThree = " (" .. 	tools.stringMaxLength(tools.cleanupButtonText(hudButtonThree["text"]),maxTextLength,"...") 	.. ")" end
		if hudButtonFour ~= " (Unassigned)" then 	hudButtonFour = " (" .. 	tools.stringMaxLength(tools.cleanupButtonText(hudButtonFour["text"]),maxTextLength,"...") 	.. ")" end

		--------------------------------------------------------------------------------
		-- Clipboard History Menu:
		--------------------------------------------------------------------------------
		local settingsClipboardHistoryTable = {}
		if enableClipboardHistory then
			local clipboardHistory = clipboard.getHistory()
			if clipboardHistory ~= nil then
				if #clipboardHistory ~= 0 then
					for i=#clipboardHistory, 1, -1 do
						table.insert(settingsClipboardHistoryTable, {title = clipboardHistory[i][2], fn = function() finalCutProPasteFromClipboardHistory(clipboardHistory[i][1]) end, disabled = not fcpxRunning})
					end
					table.insert(settingsClipboardHistoryTable, { title = "-" })
					table.insert(settingsClipboardHistoryTable, { title = "Clear Clipboard History", fn = clearClipboardHistory })
				else
					table.insert(settingsClipboardHistoryTable, { title = "Empty", disabled = true })
				end
			end
		else
			table.insert(settingsClipboardHistoryTable, { title = "Disabled in Settings", disabled = true })
		end

		--------------------------------------------------------------------------------
		-- Shared Clipboard Menu:
		--------------------------------------------------------------------------------
		local settingsSharedClipboardTable = {}

		if enableSharedClipboard then

			--------------------------------------------------------------------------------
			-- Get list of files:
			--------------------------------------------------------------------------------
			local emptySharedClipboard = true
			local sharedClipboardFiles = {}
			local sharedClipboardPath = settings.get("fcpxHacks.sharedClipboardPath")
			for file in fs.dir(sharedClipboardPath) do
				 if file:sub(-10) == ".fcpxhacks" then

					local pathToClipboardFile = sharedClipboardPath .. file
					local plistData = plist.xmlFileToTable(pathToClipboardFile)
					if plistData ~= nil then
						if plistData["SharedClipboardLabel1"] ~= nil then

							local editorName = string.sub(file, 1, -11)
							local submenu = {}
							for i=1, 5 do
								emptySharedClipboard = false
								local currentItem = plistData["SharedClipboardLabel"..tostring(i)]
								if currentItem ~= "" then table.insert(submenu, {title = currentItem, fn = function() pasteFromSharedClipboard(pathToClipboardFile, tostring(i)) end, disabled = not fcpxRunning}) end
							end

							table.insert(settingsSharedClipboardTable, {title = editorName, menu = submenu})
						end
					end


				 end
			end

			if emptySharedClipboard then
				--------------------------------------------------------------------------------
				-- Nothing in the Shared Clipboard:
				--------------------------------------------------------------------------------
				table.insert(settingsSharedClipboardTable, { title = "Empty", disabled = true })
			else
				table.insert(settingsSharedClipboardTable, { title = "-" })
				table.insert(settingsSharedClipboardTable, { title = "Clear Shared Clipboard History", fn = clearSharedClipboardHistory })
			end

		else
			--------------------------------------------------------------------------------
			-- Shared Clipboard Disabled:
			--------------------------------------------------------------------------------
			table.insert(settingsSharedClipboardTable, { title = "Disabled in Settings", disabled = true })
		end

		--------------------------------------------------------------------------------
		-- Shared XML Menu:
		--------------------------------------------------------------------------------
		local settingsSharedXMLTable = {}
		if enableXMLSharing then

			--------------------------------------------------------------------------------
			-- Get list of files:
			--------------------------------------------------------------------------------
			local sharedXMLFiles = {}

			local emptySharedXMLFiles = true
			local xmlSharingPath = settings.get("fcpxHacks.xmlSharingPath")

			for folder in fs.dir(xmlSharingPath) do

				if tools.doesDirectoryExist(xmlSharingPath .. "/" .. folder) then

					submenu = {}
					for file in fs.dir(xmlSharingPath .. "/" .. folder) do
						if file:sub(-7) == ".fcpxml" then
							emptySharedXMLFiles = false
							local xmlPath = xmlSharingPath .. folder .. "/" .. file
							table.insert(submenu, {title = file:sub(1, -8), fn = function() fcp:importXML(xmlPath) end, disabled = not fcpxRunning})
						end
					end

					if next(submenu) ~= nil then
						table.insert(settingsSharedXMLTable, {title = folder, menu = submenu})
					end

				end

			end

			if emptySharedXMLFiles then
				--------------------------------------------------------------------------------
				-- Nothing in the Shared Clipboard:
				--------------------------------------------------------------------------------
				table.insert(settingsSharedXMLTable, { title = "Empty", disabled = true })
			else
				--------------------------------------------------------------------------------
				-- Something in the Shared Clipboard:
				--------------------------------------------------------------------------------
				table.insert(settingsSharedXMLTable, { title = "-" })
				table.insert(settingsSharedXMLTable, { title = "Clear Shared XML Files", fn = clearSharedXMLFiles })
			end
		else
			--------------------------------------------------------------------------------
			-- Shared Clipboard Disabled:
			--------------------------------------------------------------------------------
			table.insert(settingsSharedXMLTable, { title = "Disabled in Settings", disabled = true })
		end

		--------------------------------------------------------------------------------
		-- Get Menubar Settings:
		--------------------------------------------------------------------------------
		local menubarToolsEnabled = 		settings.get("fcpxHacks.menubarToolsEnabled")
		local menubarHacksEnabled = 		settings.get("fcpxHacks.menubarHacksEnabled")

		local settingsHUDButtons = {
			{ title = i18n("button") .. " " .. i18n("one") .. hudButtonOne, 							fn = function() hackshud.assignButton(1) end },
			{ title = i18n("button") .. " " .. i18n("two") .. hudButtonTwo, 							fn = function() hackshud.assignButton(2) end },
			{ title = i18n("button") .. " " .. i18n("three") .. hudButtonThree, 						fn = function() hackshud.assignButton(3) end },
			{ title = i18n("button") .. " " .. i18n("four") .. hudButtonFour, 							fn = function() hackshud.assignButton(4) end },
		}
		-- The main menu
		local menuTable = {
		}

		local settingsNotificationPlatform = {
			{ title = i18n("prowl"), 																	fn = function() toggleNotificationPlatform("Prowl") end, 			checked = notificationPlatform["Prowl"] == true },
			{ title = i18n("iMessage"), 																fn = function() toggleNotificationPlatform("iMessage") end, 		checked = notificationPlatform["iMessage"] == true },
		}
		local toolsSettings = {
			{ title = i18n("enableClipboardHistory"),													fn = toggleEnableClipboardHistory, 									checked = enableClipboardHistory},
			{ title = i18n("enableSharedClipboard"), 													fn = toggleEnableSharedClipboard, 									checked = enableSharedClipboard},
			{ title = "-" },
			{ title = i18n("enableHacksHUD"), 															fn = toggleEnableHacksHUD, 											checked = enableHacksHUD},
			{ title = i18n("enableXMLSharing"),															fn = toggleEnableXMLSharing, 										checked = enableXMLSharing},
			{ title = "-" },
			{ title = i18n("enableVoiceCommands"),														fn = toggleEnableVoiceCommands, 									checked = settings.get("fcpxHacks.enableVoiceCommands") },
			{ title = "-" },
			{ title = i18n("enableMobileNotifications"),												menu = settingsNotificationPlatform },
		}
		local toolsTable = {
			{ title = "-" },
			{ title = string.upper(i18n("tools")) .. ":", 												disabled = true },
			{ title = i18n("importSharedXMLFile"),														menu = settingsSharedXMLTable },
			{ title = i18n("pasteFromClipboardHistory"),												menu = settingsClipboardHistoryTable },
			{ title = i18n("pasteFromSharedClipboard"), 												menu = settingsSharedClipboardTable },
			{ title = i18n("assignHUDButtons"), 														menu = settingsHUDButtons },
			{ title = i18n("options"),																	menu = toolsSettings },
		}
		local advancedTable = {
			{ title = "-" },
			{ title = i18n("enableHacksShortcuts"), 													fn = toggleEnableHacksShortcutsInFinalCutPro, 						checked = enableHacksShortcutsInFinalCutPro},
			{ title = i18n("enableTimecodeOverlay"), 													fn = toggleTimecodeOverlay, 										checked = mod.FFEnableGuards },
			{ title = i18n("enableMovingMarkers"), 														fn = toggleMovingMarkers, 											checked = mod.allowMovingMarkers },
			{ title = i18n("enableRenderingDuringPlayback"),											fn = togglePerformTasksDuringPlayback, 								checked = not mod.FFSuspendBGOpsDuringPlay },
			{ title = "-" },
			{ title = i18n("changeBackupInterval") .. " (" .. tostring(mod.FFPeriodicBackupInterval) .. " " .. i18n("mins") .. ")", fn = changeBackupInterval },
			{ title = i18n("changeSmartCollectionLabel"),												fn = changeSmartCollectionsLabel },
		}
		local hacksTable = {
			{ title = "-" },
			{ title = string.upper(i18n("hacks")) .. ":", 												disabled = true },
			{ title = i18n("advancedFeatures"),															menu = advancedTable },
		}

		--------------------------------------------------------------------------------
		-- Setup Menubar:
		--------------------------------------------------------------------------------
		if menubarToolsEnabled then 		menuTable = fnutils.concat(menuTable, toolsTable)		end
		if menubarHacksEnabled then 		menuTable = fnutils.concat(menuTable, hacksTable)		end

		--------------------------------------------------------------------------------
		-- Check for Updates:
		--------------------------------------------------------------------------------
		if latestScriptVersion ~= nil then
			if latestScriptVersion > metadata.scriptVersion then
				table.insert(menuTable, 1, { title = i18n("updateAvailable") .. " (" .. i18n("version") .. " " .. latestScriptVersion .. ")", fn = getScriptUpdate})
				table.insert(menuTable, 2, { title = "-" })
			end
		end

		return menuTable
	end

	function generatePreferencesMenuBar()

		--------------------------------------------------------------------------------
		-- Hammerspoon Settings:
		--------------------------------------------------------------------------------
		local startHammerspoonOnLaunch = hs.autoLaunch()
		local hammerspoonCheckForUpdates = hs.automaticallyCheckForUpdates()
		local hammerspoonDockIcon = hs.dockIcon()
		local hammerspoonMenuIcon = hs.menuIcon()

		--------------------------------------------------------------------------------
		-- HUD Preferences:
		--------------------------------------------------------------------------------
		local hudShowInspector 		= settings.get("fcpxHacks.hudShowInspector")
		local hudShowDropTargets 	= settings.get("fcpxHacks.hudShowDropTargets")
		local hudShowButtons 		= settings.get("fcpxHacks.hudShowButtons")

		--------------------------------------------------------------------------------
		-- Enable Check for Updates:
		--------------------------------------------------------------------------------
		local enableCheckForUpdates = settings.get("fcpxHacks.enableCheckForUpdates") or false

		--------------------------------------------------------------------------------
		-- Setup Menu:
		--------------------------------------------------------------------------------
		local settingsHammerspoonSettings = {
			{ title = i18n("console") .. "...", 														fn = openHammerspoonConsole },
			{ title = "-" },
			{ title = i18n("showDockIcon"),																fn = toggleHammerspoonDockIcon, 									checked = hammerspoonDockIcon		},
			{ title = i18n("showMenuIcon"), 															fn = toggleHammerspoonMenuIcon, 									checked = hammerspoonMenuIcon		},
			{ title = "-" },
			{ title = i18n("launchAtStartup"), 															fn = toggleLaunchHammerspoonOnStartup, 								checked = startHammerspoonOnLaunch		},
			{ title = i18n("checkForUpdates"), 															fn = toggleCheckforHammerspoonUpdates, 								checked = hammerspoonCheckForUpdates	},
		}
		local settingsHUD = {
			{ title = i18n("showInspector"), 															fn = function() toggleHUDOption("hudShowInspector") end, 			checked = hudShowInspector},
			{ title = i18n("showDropTargets"), 															fn = function() toggleHUDOption("hudShowDropTargets") end, 			checked = hudShowDropTargets},
			{ title = i18n("showButtons"), 																fn = function() toggleHUDOption("hudShowButtons") end, 				checked = hudShowButtons},
		}
		local settingsVoiceCommand = {
			{ title = i18n("enableAnnouncements"), 														fn = toggleVoiceCommandEnableAnnouncements, 						checked = settings.get("fcpxHacks.voiceCommandEnableAnnouncements") },
			{ title = i18n("enableVisualAlerts"), 														fn = toggleVoiceCommandEnableVisualAlerts, 							checked = settings.get("fcpxHacks.voiceCommandEnableVisualAlerts") },
			{ title = "-" },
			{ title = i18n("openDictationPreferences"), 												fn = function()
				osascript.applescript([[
					tell application "System Preferences"
						activate
						reveal anchor "Dictation" of pane "com.apple.preference.speech"
					end tell]]) end },
		}
		local settingsMenuTable = {
			{ title = i18n("hudOptions"), 																menu = settingsHUD},
			{ title = i18n("voiceCommandOptions"), 														menu = settingsVoiceCommand},
			{ title = "Hammerspoon " .. i18n("options"),												menu = settingsHammerspoonSettings},
			{ title = "-" },
			{ title = i18n("checkForUpdates"), 															fn = toggleCheckForUpdates, 										checked = enableCheckForUpdates},
			{ title = i18n("enableDebugMode"), 															fn = toggleDebugMode, 												checked = mod.debugMode},
			{ title = "-" },
			{ title = i18n("trashPreferences", {metadata.scriptName}), 									fn = resetSettings },
			{ title = "-" },
			{ title = i18n("provideFeedback"),															fn = emailBugReport },
			{ title = "-" },
			{ title = i18n("createdBy") .. " LateNite Films", 											fn = gotoLateNiteSite },
			{ title = i18n("scriptVersion") .. " " .. metadata.scriptVersion,							disabled = true },
		}

		return settingsMenuTable
	end

	function generateMenubarPrefsMenuBar()
		--------------------------------------------------------------------------------
		-- Get Menubar Settings:
		--------------------------------------------------------------------------------
		local menubarToolsEnabled = 		settings.get("fcpxHacks.menubarToolsEnabled")
		local menubarHacksEnabled = 		settings.get("fcpxHacks.menubarHacksEnabled")

		--------------------------------------------------------------------------------
		-- Get Enable Proxy Menu Item:
		--------------------------------------------------------------------------------
		local enableProxyMenuIcon = settings.get("fcpxHacks.enableProxyMenuIcon") or false

		--------------------------------------------------------------------------------
		-- Get Menubar Display Mode from Settings:
		--------------------------------------------------------------------------------
		local displayMenubarAsIcon = settings.get("fcpxHacks.displayMenubarAsIcon") or false

		local settingsMenubar = {
			{ title = i18n("showTools"), 																fn = function() toggleMenubarDisplay("Tools") end, 					checked = menubarToolsEnabled},
			{ title = i18n("showHacks"), 																fn = function() toggleMenubarDisplay("Hacks") end, 					checked = menubarHacksEnabled},
			{ title = "-" },
			{ title = i18n("displayProxyOriginalIcon"), 												fn = toggleEnableProxyMenuIcon, 									checked = enableProxyMenuIcon},
			{ title = i18n("displayThisMenuAsIcon"), 													fn = toggleMenubarDisplayMode, 										checked = displayMenubarAsIcon},
		}
		return settingsMenubar
	end

	--------------------------------------------------------------------------------
	-- UPDATE MENUBAR ICON:
	--------------------------------------------------------------------------------
	function updateMenubarIcon()
		menuManager():updateMenubarIcon()
	end

--------------------------------------------------------------------------------
-- CHANGE:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- FCPX CHANGE BACKUP INTERVAL:
	--------------------------------------------------------------------------------
	function changeBackupInterval()

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get existing value:
		--------------------------------------------------------------------------------
		if fcp:getPreference("FFPeriodicBackupInterval") == nil then
			mod.FFPeriodicBackupInterval = 15
		else
			mod.FFPeriodicBackupInterval = fcp:getPreference("FFPeriodicBackupInterval")
		end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(i18n("changeBackupIntervalMessage") .. "\n\n" .. i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Ask user what to set the backup interval to:
		--------------------------------------------------------------------------------
		local userSelectedBackupInterval = dialog.displaySmallNumberTextBoxMessage(i18n("changeBackupIntervalTextbox"), i18n("changeBackupIntervalError"), mod.FFPeriodicBackupInterval)
		if not userSelectedBackupInterval then
			return "Cancel"
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		local result = fcp:setPreference("FFPeriodicBackupInterval", tostring(userSelectedBackupInterval))
		if result == nil then
			dialog.displayErrorMessage(i18n("backupIntervalFail"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

	end

	--------------------------------------------------------------------------------
	-- CHANGE SMART COLLECTIONS LABEL:
	--------------------------------------------------------------------------------
	function changeSmartCollectionsLabel()

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get existing value:
		--------------------------------------------------------------------------------
		local executeResult,executeStatus = execute("/usr/libexec/PlistBuddy -c \"Print :FFOrganizerSmartCollections\" '" .. fcp:getPath() .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/en.lproj/FFLocalizable.strings'")
		if tools.trim(executeResult) ~= "" then FFOrganizerSmartCollections = executeResult end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(i18n("changeSmartCollectionsLabel") .. "\n\n" .. i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Ask user what to set the backup interval to:
		--------------------------------------------------------------------------------
		local userSelectedSmartCollectionsLabel = dialog.displayTextBoxMessage(i18n("smartCollectionsLabelTextbox"), i18n("smartCollectionsLabelError"), tools.trim(FFOrganizerSmartCollections))
		if not userSelectedSmartCollectionsLabel then
			return "Cancel"
		end

		--------------------------------------------------------------------------------
		-- Update plist for every Flexo language:
		--------------------------------------------------------------------------------
		local executeCommands = {}
		for k, v in pairs(fcp:getFlexoLanguages()) do
			local executeCommand = "/usr/libexec/PlistBuddy -c \"Set :FFOrganizerSmartCollections " .. tools.trim(userSelectedSmartCollectionsLabel) .. "\" '" .. fcp:getPath() .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/" .. fcp:getFlexoLanguages()[k] .. ".lproj/FFLocalizable.strings'"
			executeCommands[#executeCommands + 1] = executeCommand
		end
		local result = tools.executeWithAdministratorPrivileges(executeCommands)
		if type(result) == "string" then
			dialog.displayErrorMessage(result)
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

	end

--------------------------------------------------------------------------------
-- TOGGLE:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- TOGGLE NOTIFICATION PLATFORM:
	--------------------------------------------------------------------------------
	function toggleNotificationPlatform(value)

		local notificationPlatform 		= settings.get("fcpxHacks.notificationPlatform")
		local prowlAPIKey 				= settings.get("fcpxHacks.prowlAPIKey") or ""
		local iMessageTarget			= settings.get("fcpxHacks.iMessageTarget") or ""

		local returnToFinalCutPro 		= fcp:isFrontmost()

		if value == "Prowl" then
			if not notificationPlatform["Prowl"] then
				::retryProwlAPIKeyEntry::
				local result = dialog.displayTextBoxMessage(i18n("prowlTextbox"), i18n("prowlTextboxError") .. "\n\n" .. i18n("pleaseTryAgain"), prowlAPIKey)
				if result == false then return end
				local prowlAPIKeyValidResult, prowlAPIKeyValidError = prowlAPIKeyValid(result)
				if prowlAPIKeyValidResult then
					if returnToFinalCutPro then fcp:launch() end
					settings.set("fcpxHacks.prowlAPIKey", result)
				else
					dialog.displayMessage(i18n("prowlError") .. " " .. prowlAPIKeyValidError .. ".\n\n" .. i18n("pleaseTryAgain"))
					goto retryProwlAPIKeyEntry
				end
			end
		end

		if value == "iMessage" then
			if not notificationPlatform["iMessage"] then
				local result = dialog.displayTextBoxMessage(i18n("iMessageTextBox"), i18n("pleaseTryAgain"), iMessageTarget)
				if result == false then return end
				settings.set("fcpxHacks.iMessageTarget", result)
			end
		end

		notificationPlatform[value] = not notificationPlatform[value]
		settings.set("fcpxHacks.notificationPlatform", notificationPlatform)

		if next(notificationPlatform) == nil then
			if shareSuccessNotificationWatcher then shareSuccessNotificationWatcher:stop() end
			if shareFailedNotificationWatcher then shareFailedNotificationWatcher:stop() end
		else
			notificationWatcher()
		end

	end

	--------------------------------------------------------------------------------
	-- TOGGLE VOICE COMMAND ENABLE ANNOUNCEMENTS:
	--------------------------------------------------------------------------------
	function toggleVoiceCommandEnableAnnouncements()
		local voiceCommandEnableAnnouncements = settings.get("fcpxHacks.voiceCommandEnableAnnouncements")
		settings.set("fcpxHacks.voiceCommandEnableAnnouncements", not voiceCommandEnableAnnouncements)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE VOICE COMMAND ENABLE VISUAL ALERTS:
	--------------------------------------------------------------------------------
	function toggleVoiceCommandEnableVisualAlerts()
		local voiceCommandEnableVisualAlerts = settings.get("fcpxHacks.voiceCommandEnableVisualAlerts")
		settings.set("fcpxHacks.voiceCommandEnableVisualAlerts", not voiceCommandEnableVisualAlerts)
	end
	--------------------------------------------------------------------------------
	-- TOGGLE ENABLE HACKS HUD:
	--------------------------------------------------------------------------------
	function toggleEnableVoiceCommands()

		local enableVoiceCommands = settings.get("fcpxHacks.enableVoiceCommands")
		settings.set("fcpxHacks.enableVoiceCommands", not enableVoiceCommands)

		if enableVoiceCommands then
			voicecommands:stop()
		else
			local result = voicecommands:new()
			if result == false then
				dialog.displayErrorMessage(i18n("voiceCommandsError"))
				settings.set("fcpxHacks.enableVoiceCommands", enableVoiceCommands)
				return
			end
			if fcp:isFrontmost() then
				voicecommands:start()
			else
				voicecommands:stop()
			end
		end
	end

	--------------------------------------------------------------------------------
	-- TOGGLE ENABLE HACKS HUD:
	--------------------------------------------------------------------------------
	function toggleEnableHacksHUD()
		local enableHacksHUD = settings.get("fcpxHacks.enableHacksHUD")
		settings.set("fcpxHacks.enableHacksHUD", not enableHacksHUD)

		if enableHacksHUD then
			hackshud.hide()
		else
			if fcp:isFrontmost() then
				hackshud.show()
			end
		end
	end

	--------------------------------------------------------------------------------
	-- TOGGLE DEBUG MODE:
	--------------------------------------------------------------------------------
	function toggleDebugMode()
		settings.set("fcpxHacks.debugMode", not mod.debugMode)
		hs.reload()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE CHECK FOR UPDATES:
	--------------------------------------------------------------------------------
	function toggleCheckForUpdates()
		local enableCheckForUpdates = settings.get("fcpxHacks.enableCheckForUpdates")
		settings.set("fcpxHacks.enableCheckForUpdates", not enableCheckForUpdates)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE MENUBAR DISPLAY:
	--------------------------------------------------------------------------------
	function toggleMenubarDisplay(value)
		local menubarEnabled = settings.get("fcpxHacks.menubar" .. value .. "Enabled")
		settings.set("fcpxHacks.menubar" .. value .. "Enabled", not menubarEnabled)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HUD OPTION:
	--------------------------------------------------------------------------------
	function toggleHUDOption(value)
		local result = settings.get("fcpxHacks." .. value)
		settings.set("fcpxHacks." .. value, not result)
		hackshud.reload()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE CLIPBOARD HISTORY:
	--------------------------------------------------------------------------------
	function toggleEnableClipboardHistory()

		local enableSharedClipboard = settings.get("fcpxHacks.enableSharedClipboard") or false
		local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false

		if not enableClipboardHistory then
			if not enableSharedClipboard then
				clipboard.startWatching()
			end
		else
			if not enableSharedClipboard then
				clipboard.stopWatching()
			end
		end
		settings.set("fcpxHacks.enableClipboardHistory", not enableClipboardHistory)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE SHARED CLIPBOARD:
	--------------------------------------------------------------------------------
	function toggleEnableSharedClipboard()

		local enableSharedClipboard = settings.get("fcpxHacks.enableSharedClipboard") or false
		local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false

		if not enableSharedClipboard then

			result = dialog.displayChooseFolder("Which folder would you like to use for the Shared Clipboard?")

			if result ~= false then
				debugMessage("Enabled Shared Clipboard Path: " .. tostring(result))
				settings.set("fcpxHacks.sharedClipboardPath", result)

				--------------------------------------------------------------------------------
				-- Watch for Shared Clipboard Changes:
				--------------------------------------------------------------------------------
				sharedClipboardWatcher = pathwatcher.new(result, sharedClipboardFileWatcher):start()

				if not enableClipboardHistory then
					clipboard.startWatching()
				end

			else
				debugMessage("Enabled Shared Clipboard Choose Path Cancelled.")
				settings.set("fcpxHacks.sharedClipboardPath", nil)
				return "failed"
			end

		else

			--------------------------------------------------------------------------------
			-- Stop Watching for Shared Clipboard Changes:
			--------------------------------------------------------------------------------
			sharedClipboardWatcher:stop()

			if not enableClipboardHistory then
				clipboard.stopWatching()
			end

		end

		settings.set("fcpxHacks.enableSharedClipboard", not enableSharedClipboard)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE XML SHARING:
	--------------------------------------------------------------------------------
	function toggleEnableXMLSharing()

		local enableXMLSharing = settings.get("fcpxHacks.enableXMLSharing") or false

		if not enableXMLSharing then

			xmlSharingPath = dialog.displayChooseFolder("Which folder would you like to use for XML Sharing?")

			if xmlSharingPath ~= false then
				settings.set("fcpxHacks.xmlSharingPath", xmlSharingPath)
			else
				settings.set("fcpxHacks.xmlSharingPath", nil)
				return "Cancelled"
			end

			--------------------------------------------------------------------------------
			-- Watch for Shared XML Folder Changes:
			--------------------------------------------------------------------------------
			sharedXMLWatcher = pathwatcher.new(xmlSharingPath, sharedXMLFileWatcher):start()

		else
			--------------------------------------------------------------------------------
			-- Stop Watchers:
			--------------------------------------------------------------------------------
			sharedXMLWatcher:stop()

			--------------------------------------------------------------------------------
			-- Clear Settings:
			--------------------------------------------------------------------------------
			settings.set("fcpxHacks.xmlSharingPath", nil)
		end

		settings.set("fcpxHacks.enableXMLSharing", not enableXMLSharing)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HAMMERSPOON DOCK ICON:
	--------------------------------------------------------------------------------
	function toggleHammerspoonDockIcon()
		local originalValue = hs.dockIcon()
		hs.dockIcon(not originalValue)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HAMMERSPOON MENU ICON:
	--------------------------------------------------------------------------------
	function toggleHammerspoonMenuIcon()
		local originalValue = hs.menuIcon()
		hs.menuIcon(not originalValue)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE LAUNCH HAMMERSPOON ON START:
	--------------------------------------------------------------------------------
	function toggleLaunchHammerspoonOnStartup()
		local originalValue = hs.autoLaunch()
		hs.autoLaunch(not originalValue)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HAMMERSPOON CHECK FOR UPDATES:
	--------------------------------------------------------------------------------
	function toggleCheckforHammerspoonUpdates()
		local originalValue = hs.automaticallyCheckForUpdates()
		hs.automaticallyCheckForUpdates(not originalValue)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE ENABLE PROXY MENU ICON:
	--------------------------------------------------------------------------------
	function toggleEnableProxyMenuIcon()
		local enableProxyMenuIcon = settings.get("fcpxHacks.enableProxyMenuIcon")
		if enableProxyMenuIcon == nil then
			settings.set("fcpxHacks.enableProxyMenuIcon", true)
			enableProxyMenuIcon = true
		else
			settings.set("fcpxHacks.enableProxyMenuIcon", not enableProxyMenuIcon)
		end

		updateMenubarIcon()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HACKS SHORTCUTS IN FINAL CUT PRO:
	--------------------------------------------------------------------------------
	function toggleEnableHacksShortcutsInFinalCutPro()
		plugins("hs.fcpxhacks.plugins.hacks.shortcuts").toggleEditable()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE MOVING MARKERS:
	--------------------------------------------------------------------------------
	function toggleMovingMarkers()

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get existing value:
		--------------------------------------------------------------------------------
		mod.allowMovingMarkers = false
		local executeResult,executeStatus = execute("/usr/libexec/PlistBuddy -c \"Print :TLKMarkerHandler:Configuration:'Allow Moving Markers'\" '" .. fcp:getPath() .. "/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist'")
		if tools.trim(executeResult) == "true" then mod.allowMovingMarkers = true end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(i18n("togglingMovingMarkersRestart") .. "\n\n" .. i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		if mod.allowMovingMarkers then
			local result = tools.executeWithAdministratorPrivileges([[/usr/libexec/PlistBuddy -c \"Set :TLKMarkerHandler:Configuration:'Allow Moving Markers' false\" ']] .. fcp:getPath() .. [[/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist']])
			if type(result) == "string" then
				dialog.displayErrorMessage(result)
			end
		else
			local executeStatus = tools.executeWithAdministratorPrivileges([[/usr/libexec/PlistBuddy -c \"Set :TLKMarkerHandler:Configuration:'Allow Moving Markers' true\" ']] .. fcp:getPath() .. [[/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist']])
			if type(result) == "string" then
				dialog.displayErrorMessage(result)
			end
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end
	end

	--------------------------------------------------------------------------------
	-- TOGGLE PERFORM TASKS DURING PLAYBACK:
	--------------------------------------------------------------------------------
	function togglePerformTasksDuringPlayback()

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get existing value:
		--------------------------------------------------------------------------------
		if fcp:getPreference("FFSuspendBGOpsDuringPlay") == nil then
			mod.FFSuspendBGOpsDuringPlay = false
		else
			mod.FFSuspendBGOpsDuringPlay = fcp:getPreference("FFSuspendBGOpsDuringPlay")
		end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(i18n("togglingBackgroundTasksRestart") .. "\n\n" ..i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		local result = fcp:setPreference("FFSuspendBGOpsDuringPlay", not mod.FFSuspendBGOpsDuringPlay)
		if result == nil then
			dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end
	end

	--------------------------------------------------------------------------------
	-- TOGGLE TIMECODE OVERLAY:
	--------------------------------------------------------------------------------
	function toggleTimecodeOverlay()

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get existing value:
		--------------------------------------------------------------------------------
		if fcp:getPreference("FFEnableGuards") == nil then
			mod.FFEnableGuards = false
		else
			mod.FFEnableGuards = fcp:getPreference("FFEnableGuards")
		end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(i18n("togglingTimecodeOverlayRestart") .. "\n\n" .. i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		local result = fcp:setPreference("FFEnableGuards", not mod.FFEnableGuards)
		if result == nil then
			dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end
	end

	--------------------------------------------------------------------------------
	-- TOGGLE MENUBAR DISPLAY MODE:
	--------------------------------------------------------------------------------
	function toggleMenubarDisplayMode()

		local displayMenubarAsIcon = settings.get("fcpxHacks.displayMenubarAsIcon")


		if displayMenubarAsIcon == nil then
			 settings.set("fcpxHacks.displayMenubarAsIcon", true)
		else
			if displayMenubarAsIcon then
				settings.set("fcpxHacks.displayMenubarAsIcon", false)
			else
				settings.set("fcpxHacks.displayMenubarAsIcon", true)
			end
		end

		updateMenubarIcon()
	end

--------------------------------------------------------------------------------
-- PASTE:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- PASTE FROM CLIPBOARD HISTORY:
	--------------------------------------------------------------------------------
	function finalCutProPasteFromClipboardHistory(data)

		--------------------------------------------------------------------------------
		-- Write data back to Clipboard:
		--------------------------------------------------------------------------------
		clipboard.stopWatching()
		pasteboard.writeDataForUTI(fcp:getPasteboardUTI(), data)
		clipboard.startWatching()

		--------------------------------------------------------------------------------
		-- Paste in FCPX:
		--------------------------------------------------------------------------------
		fcp:launch()
		if not fcp:performShortcut("Paste") then
			dialog.displayErrorMessage("Failed to trigger the 'Paste' Shortcut.\n\nError occurred in finalCutProPasteFromClipboardHistory().")
			return "Failed"
		end

	end

	--------------------------------------------------------------------------------
	-- PASTE FROM SHARED CLIPBOARD:
	--------------------------------------------------------------------------------
	function pasteFromSharedClipboard(pathToClipboardFile, whichClipboard)

		if tools.doesFileExist(pathToClipboardFile) then
			local plistData = plist.xmlFileToTable(pathToClipboardFile)
			if plistData ~= nil then

				--------------------------------------------------------------------------------
				-- Decode Shared Clipboard Data from Plist:
				--------------------------------------------------------------------------------
				local currentClipboardData = base64.decode(plistData["SharedClipboardData" .. whichClipboard])

				--------------------------------------------------------------------------------
				-- Write data back to Clipboard:
				--------------------------------------------------------------------------------
				clipboard.stopWatching()
				pasteboard.writeDataForUTI(fcp:getPasteboardUTI(), currentClipboardData)
				clipboard.startWatching()

				--------------------------------------------------------------------------------
				-- Paste in FCPX:
				--------------------------------------------------------------------------------
				fcp:launch()
				if not fcp:performShortcut("Paste") then
					dialog.displayErrorMessage("Failed to trigger the 'Paste' Shortcut.\n\nError occurred in pasteFromSharedClipboard().")
					return "Failed"
				end

			else
				dialog.errorMessage(i18n("sharedClipboardNotRead"))
				return "Fail"
			end
		else
			dialog.displayMessage(i18n("sharedClipboardFileNotFound"))
			return "Fail"
		end

	end

--------------------------------------------------------------------------------
-- CLEAR:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- CLEAR CLIPBOARD HISTORY:
	--------------------------------------------------------------------------------
	function clearClipboardHistory()
		clipboard.clearHistory()
	end

	--------------------------------------------------------------------------------
	-- CLEAR SHARED CLIPBOARD HISTORY:
	--------------------------------------------------------------------------------
	function clearSharedClipboardHistory()
		local sharedClipboardPath = settings.get("fcpxHacks.sharedClipboardPath")
		for file in fs.dir(sharedClipboardPath) do
			 if file:sub(-10) == ".fcpxhacks" then
				os.remove(sharedClipboardPath .. file)
			 end
		end
	end

	--------------------------------------------------------------------------------
	-- CLEAR SHARED XML FILES:
	--------------------------------------------------------------------------------
	function clearSharedXMLFiles()

		local xmlSharingPath = settings.get("fcpxHacks.xmlSharingPath")
		for folder in fs.dir(xmlSharingPath) do
			if tools.doesDirectoryExist(xmlSharingPath .. "/" .. folder) then
				for file in fs.dir(xmlSharingPath .. "/" .. folder) do
					if file:sub(-7) == ".fcpxml" then
						os.remove(xmlSharingPath .. folder .. "/" .. file)
					end
				end
			end
		end
	end

--------------------------------------------------------------------------------
-- OTHER:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- OPEN HAMMERSPOON CONSOLE:
	--------------------------------------------------------------------------------
	function openHammerspoonConsole()
		hs.openConsole()
	end

	--------------------------------------------------------------------------------
	-- RESET SETTINGS:
	--------------------------------------------------------------------------------
	function resetSettings()

		local finalCutProRunning = fcp:isRunning()

		local resetMessage = i18n("trashFCPXHacksPreferences")
		if finalCutProRunning then
			resetMessage = resetMessage .. "\n\n" .. i18n("adminPasswordRequiredAndRestart")
		else
			resetMessage = resetMessage .. "\n\n" .. i18n("adminPasswordRequired")
		end

		if not dialog.displayYesNoQuestion(resetMessage) then
		 	return
		end

		--------------------------------------------------------------------------------
		-- Remove Hacks Shortcut in Final Cut Pro:
		--------------------------------------------------------------------------------
		local result = disableHacksShortcuts()
		if type(result) == "string" then
			dialog.displayErrorMessage(result)
		end

		--------------------------------------------------------------------------------
		-- Trash all Script Settings:
		--------------------------------------------------------------------------------
		for i, v in ipairs(settings.getKeys()) do
			if (v:sub(1,10)) == "fcpxHacks." then
				settings.set(v, nil)
			end
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro if running:
		--------------------------------------------------------------------------------
		if finalCutProRunning then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayMessage(i18n("restartFinalCutProFailed"))
			end
		end

		--------------------------------------------------------------------------------
		-- Reload Hammerspoon:
		--------------------------------------------------------------------------------
		hs.reload()

	end

	--------------------------------------------------------------------------------
	-- GET SCRIPT UPDATE:
	--------------------------------------------------------------------------------
	function getScriptUpdate()
		os.execute('open "' .. metadata.updateURL .. '"')
	end

	--------------------------------------------------------------------------------
	-- GO TO LATENITE FILMS SITE:
	--------------------------------------------------------------------------------
	function gotoLateNiteSite()
		os.execute('open "' .. metadata.developerURL .. '"')
	end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   S H O R T C U T   F E A T U R E S                        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- KEYWORDS:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- SAVE KEYWORDS:
	--------------------------------------------------------------------------------
	function saveKeywordSearches(whichButton)

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Check to see if the Keyword Editor is already open:
		--------------------------------------------------------------------------------
		local fcpx = fcp:application()
		local fcpxElements = ax.applicationElement(fcpx)
		local whichWindow = nil
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if fcpxElements[i]:attributeValue("AXRole") == "AXWindow" then
				if fcpxElements[i]:attributeValue("AXIdentifier") == "_NS:264" then
					whichWindow = i
				end
			end
		end
		if whichWindow == nil then
			dialog.displayMessage(i18n("keywordEditorAlreadyOpen"))
			return
		end
		fcpxElements = fcpxElements[whichWindow]

		--------------------------------------------------------------------------------
		-- Get Starting Textfield:
		--------------------------------------------------------------------------------
		local startTextField = nil
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if startTextField == nil then
				if fcpxElements[i]:attributeValue("AXIdentifier") == "_NS:102" then
					startTextField = i
					goto startTextFieldDone
				end
			end
		end
		::startTextFieldDone::
		if startTextField == nil then
			--------------------------------------------------------------------------------
			-- Keyword Shortcuts Buttons isn't down:
			--------------------------------------------------------------------------------
			fcpxElements = ax.applicationElement(fcpx)[1] -- Refresh
			for i=1, fcpxElements:attributeValueCount("AXChildren") do
				if fcpxElements[i]:attributeValue("AXIdentifier") == "_NS:276" then
					keywordDisclosureTriangle = i
					goto keywordDisclosureTriangleDone
				end
			end
			::keywordDisclosureTriangleDone::
			if fcpxElements[keywordDisclosureTriangle] == nil then
				dialog.displayMessage(i18n("keywordShortcutsVisibleError"))
				return "Failed"
			else
				local keywordDisclosureTriangleResult = fcpxElements[keywordDisclosureTriangle]:performAction("AXPress")
				if keywordDisclosureTriangleResult == nil then
					dialog.displayMessage(i18n("keywordShortcutsVisibleError"))
					return "Failed"
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Get Values from the Keyword Editor:
		--------------------------------------------------------------------------------
		local savedKeywordValues = {}
		local favoriteCount = 1
		local skipFirst = true
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if fcpxElements[i]:attributeValue("AXRole") == "AXTextField" then
				if skipFirst then
					skipFirst = false
				else
					savedKeywordValues[favoriteCount] = fcpxElements[i]:attributeValue("AXHelp")
					favoriteCount = favoriteCount + 1
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Save Values to Settings:
		--------------------------------------------------------------------------------
		local savedKeywords = settings.get("fcpxHacks.savedKeywords")
		if savedKeywords == nil then savedKeywords = {} end
		for i=1, 9 do
			if savedKeywords['Preset ' .. tostring(whichButton)] == nil then
				savedKeywords['Preset ' .. tostring(whichButton)] = {}
			end
			savedKeywords['Preset ' .. tostring(whichButton)]['Item ' .. tostring(i)] = savedKeywordValues[i]
		end
		settings.set("fcpxHacks.savedKeywords", savedKeywords)

		--------------------------------------------------------------------------------
		-- Saved:
		--------------------------------------------------------------------------------
		dialog.displayNotification(i18n("keywordPresetsSaved") .. " " .. tostring(whichButton))

	end

	--------------------------------------------------------------------------------
	-- RESTORE KEYWORDS:
	--------------------------------------------------------------------------------
	function restoreKeywordSearches(whichButton)

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get Values from Settings:
		--------------------------------------------------------------------------------
		local savedKeywords = settings.get("fcpxHacks.savedKeywords")
		local restoredKeywordValues = {}

		if savedKeywords == nil then
			dialog.displayMessage(i18n("noKeywordPresetsError"))
			return "Fail"
		end
		if savedKeywords['Preset ' .. tostring(whichButton)] == nil then
			dialog.displayMessage(i18n("noKeywordPresetError"))
			return "Fail"
		end
		for i=1, 9 do
			restoredKeywordValues[i] = savedKeywords['Preset ' .. tostring(whichButton)]['Item ' .. tostring(i)]
		end

		--------------------------------------------------------------------------------
		-- Check to see if the Keyword Editor is already open:
		--------------------------------------------------------------------------------
		local fcpx = fcp:application()
		local fcpxElements = ax.applicationElement(fcpx)
		local whichWindow = nil
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if fcpxElements[i]:attributeValue("AXRole") == "AXWindow" then
				if fcpxElements[i]:attributeValue("AXIdentifier") == "_NS:264" then
					whichWindow = i
				end
			end
		end
		if whichWindow == nil then
			dialog.displayMessage(i18n("keywordEditorAlreadyOpen"))
			return
		end
		fcpxElements = fcpxElements[whichWindow]

		--------------------------------------------------------------------------------
		-- Get Starting Textfield:
		--------------------------------------------------------------------------------
		local startTextField = nil
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if startTextField == nil then
				if fcpxElements[i]:attributeValue("AXIdentifier") == "_NS:102" then
					startTextField = i
					goto startTextFieldDone
				end
			end
		end
		::startTextFieldDone::
		if startTextField == nil then
			--------------------------------------------------------------------------------
			-- Keyword Shortcuts Buttons isn't down:
			--------------------------------------------------------------------------------
			local keywordDisclosureTriangle = nil
			for i=1, fcpxElements:attributeValueCount("AXChildren") do
				if fcpxElements[i]:attributeValue("AXIdentifier") == "_NS:276" then
					keywordDisclosureTriangle = i
					goto keywordDisclosureTriangleDone
				end
			end
			::keywordDisclosureTriangleDone::

			if fcpxElements[keywordDisclosureTriangle] ~= nil then
				local keywordDisclosureTriangleResult = fcpxElements[keywordDisclosureTriangle]:performAction("AXPress")
				if keywordDisclosureTriangleResult == nil then
					dialog.displayMessage(i18n("keywordShortcutsVisibleError"))
					return "Failed"
				end
			else
				dialog.displayErrorMessage("Could not find keyword disclosure triangle.\n\nError occurred in restoreKeywordSearches().")
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Restore Values to Keyword Editor:
		--------------------------------------------------------------------------------
		local favoriteCount = 1
		local skipFirst = true
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if fcpxElements[i]:attributeValue("AXRole") == "AXTextField" then
				if skipFirst then
					skipFirst = false
				else
					currentKeywordSelection = fcpxElements[i]

					setKeywordResult = currentKeywordSelection:setAttributeValue("AXValue", restoredKeywordValues[favoriteCount])
					keywordActionResult = currentKeywordSelection:setAttributeValue("AXFocused", true)
					eventtap.keyStroke({""}, "return")

					--------------------------------------------------------------------------------
					-- If at first you don't succeed, try, oh try, again!
					--------------------------------------------------------------------------------
					if fcpxElements[i][1]:attributeValue("AXValue") ~= restoredKeywordValues[favoriteCount] then
						setKeywordResult = currentKeywordSelection:setAttributeValue("AXValue", restoredKeywordValues[favoriteCount])
						keywordActionResult = currentKeywordSelection:setAttributeValue("AXFocused", true)
						eventtap.keyStroke({""}, "return")
					end

					favoriteCount = favoriteCount + 1
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Successfully Restored:
		--------------------------------------------------------------------------------
		dialog.displayNotification(i18n("keywordPresetsRestored") .. " " .. tostring(whichButton))

	end

--------------------------------------------------------------------------------
-- COLOR BOARD RELATED:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- COLOR BOARD - PUCK SELECTION:
	--------------------------------------------------------------------------------
	function colorBoardSelectPuck(aspect, property, whichDirection)

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Show the Color Board with the correct panel
		--------------------------------------------------------------------------------
		local colorBoard = fcp:colorBoard()

		--------------------------------------------------------------------------------
		-- Show the Color Board if it's hidden:
		--------------------------------------------------------------------------------
		if not colorBoard:isShowing() then colorBoard:show() end

		if not colorBoard:isActive() then
			dialog.displayNotification(i18n("pleaseSelectSingleClipInTimeline"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- If a Direction is specified:
		--------------------------------------------------------------------------------
		if whichDirection ~= nil then

			--------------------------------------------------------------------------------
			-- Get shortcut key from plist, press and hold if required:
			--------------------------------------------------------------------------------
			mod.releaseColorBoardDown = false
			timer.doUntil(function() return mod.releaseColorBoardDown end, function()
				if whichDirection == "up" then
					colorBoard:shiftPercentage(aspect, property, 1)
				elseif whichDirection == "down" then
					colorBoard:shiftPercentage(aspect, property, -1)
				elseif whichDirection == "left" then
					colorBoard:shiftAngle(aspect, property, -1)
				elseif whichDirection == "right" then
					colorBoard:shiftAngle(aspect, property, 1)
				end
			end, eventtap.keyRepeatInterval())
		else -- just select the puck
			colorBoard:selectPuck(aspect, property)
		end
	end

		--------------------------------------------------------------------------------
		-- COLOR BOARD - RELEASE KEYPRESS:
		--------------------------------------------------------------------------------
		function colorBoardSelectPuckRelease()
			mod.releaseColorBoardDown = true
		end

	--------------------------------------------------------------------------------
	-- COLOR BOARD - PUCK CONTROL VIA MOUSE:
	--------------------------------------------------------------------------------
	function colorBoardMousePuck(aspect, property)
		--------------------------------------------------------------------------------
		-- Stop Existing Color Pucker:
		--------------------------------------------------------------------------------
		if mod.colorPucker then
			mod.colorPucker:stop()
		end

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		colorBoard = fcp:colorBoard()

		--------------------------------------------------------------------------------
		-- Show the Color Board if it's hidden:
		--------------------------------------------------------------------------------
		if not colorBoard:isShowing() then colorBoard:show() end

		if not colorBoard:isActive() then
			dialog.displayNotification(i18n("pleaseSelectSingleClipInTimeline"))
			return "Failed"
		end

		mod.colorPucker = colorBoard:startPucker(aspect, property)
	end

		--------------------------------------------------------------------------------
		-- COLOR BOARD - RELEASE MOUSE KEYPRESS:
		--------------------------------------------------------------------------------
		function colorBoardMousePuckRelease()
			if mod.colorPucker then
				mod.colorPucker:stop()
				mod.colorPicker = nil
			end
		end

--------------------------------------------------------------------------------
-- CLIPBOARD RELATED:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- COPY WITH CUSTOM LABEL:
	--------------------------------------------------------------------------------
	function copyWithCustomLabel()
		local menuBar = fcp:menuBar()
		if menuBar:isEnabled("Edit", "Copy") then
			local result = dialog.displayTextBoxMessage("Please enter a label for the clipboard item:", "The value you entered is not valid.\n\nPlease try again.", "")
			if result == false then return end
			clipboard.setName(result)
			menuBar:selectMenu("Edit", "Copy")
		end
	end

	--------------------------------------------------------------------------------
	-- COPY WITH CUSTOM LABEL & FOLDER:
	--------------------------------------------------------------------------------
	function copyWithCustomLabelAndFolder()
		local menuBar = fcp:menuBar()
		if menuBar:isEnabled("Edit", "Copy") then
			local result = dialog.displayTextBoxMessage("Please enter a label for the clipboard item:", "The value you entered is not valid.\n\nPlease try again.", "")
			if result == false then return end
			clipboard.setName(result)
			local result = dialog.displayTextBoxMessage("Please enter a folder for the clipboard item:", "The value you entered is not valid.\n\nPlease try again.", "")
			if result == false then return end
			clipboard.setFolder(result)
			menuBar:selectMenu("Edit", "Copy")
		end
	end

--------------------------------------------------------------------------------
-- OTHER SHORTCUTS:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- ADD NOTE TO SELECTED CLIP:
	--------------------------------------------------------------------------------
	function addNoteToSelectedClip()

		local errorFunction = " Error occurred in addNoteToSelectedClip()."

		--------------------------------------------------------------------------------
		-- Make sure the Browser is visible:
		--------------------------------------------------------------------------------
		local libraries = fcp:browser():libraries()
		if not libraries:isShowing() then
			writeToConsole("Library Panel is closed." .. errorFunction)
			return
		end

		--------------------------------------------------------------------------------
		-- Get number of Selected Browser Clips:
		--------------------------------------------------------------------------------
		local clips = libraries:selectedClipsUI()
		if #clips ~= 1 then
			writeToConsole("Wrong number of clips selected." .. errorFunction)
			return
		end

		--------------------------------------------------------------------------------
		-- Check to see if the playhead is moving:
		--------------------------------------------------------------------------------
		local playhead = libraries:playhead()
		local playheadCheck1 = playhead:getPosition()
		timer.usleep(100000)
		local playheadCheck2 = playhead:getPosition()
		timer.usleep(100000)
		local playheadCheck3 = playhead:getPosition()
		timer.usleep(100000)
		local playheadCheck4 = playhead:getPosition()
		timer.usleep(100000)
		local wasPlaying = false
		if playheadCheck1 == playheadCheck2 and playheadCheck2 == playheadCheck3 and playheadCheck3 == playheadCheck4 then
			--debugMessage("Playhead is static.")
			wasPlaying = false
		else
			--debugMessage("Playhead is moving.")
			wasPlaying = true
		end

		--------------------------------------------------------------------------------
		-- Check to see if we're in Filmstrip or List View:
		--------------------------------------------------------------------------------
		local filmstripView = false
		if libraries:isFilmstripView() then
			filmstripView = true
			libraries:toggleViewMode():press()
			if wasPlaying then fcp:menuBar():selectMenu("View", "Playback", "Play") end
		end

		--------------------------------------------------------------------------------
		-- Get Selected Clip & Selected Clip's Parent:
		--------------------------------------------------------------------------------
		local selectedClip = libraries:selectedClipsUI()[1]
		local selectedClipParent = selectedClip:attributeValue("AXParent")

		--------------------------------------------------------------------------------
		-- Get the AXGroup:
		--------------------------------------------------------------------------------
		local axutils = require("hs.finalcutpro.axutils")
		local listHeadingGroup = axutils.childWithRole(selectedClipParent, "AXGroup")

		--------------------------------------------------------------------------------
		-- Find the 'Notes' column:
		--------------------------------------------------------------------------------
		local notesFieldID = nil
		for i=1, listHeadingGroup:attributeValueCount("AXChildren") do
			local title = listHeadingGroup[i]:attributeValue("AXTitle")
			--------------------------------------------------------------------------------
			-- English: 		Notes
			-- German:			Notizen
			-- Spanish:			Notas
			-- French:			Notes
			-- Japanese:		メモ
			-- Chinese:			注释
			--------------------------------------------------------------------------------
			if title == "Notes" or title == "Notizen" or title == "Notas" or title == "メモ" or title == "注释" then
				notesFieldID = i
			end
		end

		--------------------------------------------------------------------------------
		-- If the 'Notes' column is missing:
		--------------------------------------------------------------------------------
		local notesPressed = false
		if notesFieldID == nil then
			listHeadingGroup:performAction("AXShowMenu")
			local menu = axutils.childWithRole(listHeadingGroup, "AXMenu")
			for i=1, menu:attributeValueCount("AXChildren") do
				if not notesPressed then
					local title = menu[i]:attributeValue("AXTitle")
					if title == "Notes" or title == "Notizen" or title == "Notas" or title == "メモ" or title == "注释" then
						menu[i]:performAction("AXPress")
						notesPressed = true
						for i=1, listHeadingGroup:attributeValueCount("AXChildren") do
							local title = listHeadingGroup[i]:attributeValue("AXTitle")
							if title == "Notes" or title == "Notizen" or title == "Notas" or title == "メモ" or title == "注释" then
								notesFieldID = i
							end
						end
					end
				end
			end
		end

		--------------------------------------------------------------------------------
		-- If the 'Notes' column is missing then error:
		--------------------------------------------------------------------------------
		if notesFieldID == nil then
			errorMessage(metadata.scriptName .. " could not find the Notes Column." .. errorFunction)
			return
		end

		local selectedNotesField = selectedClip[notesFieldID][1]
		local existingValue = selectedNotesField:attributeValue("AXValue")

		--------------------------------------------------------------------------------
		-- Setup Chooser:
		--------------------------------------------------------------------------------
		noteChooser = chooser.new(function(result)
			--------------------------------------------------------------------------------
			-- When Chooser Item is Selected or Closed:
			--------------------------------------------------------------------------------
			noteChooser:hide()
			fcp:launch()

			if result ~= nil then
				selectedNotesField:setAttributeValue("AXFocused", true)
				selectedNotesField:setAttributeValue("AXValue", result["text"])
				selectedNotesField:setAttributeValue("AXFocused", false)
				if not filmstripView then
					eventtap.keyStroke({}, "return") -- List view requires an "return" key press
				end

				local selectedRow = noteChooser:selectedRow()

				local recentNotes = settings.get("fcpxHacks.recentNotes") or {}
				if selectedRow == 1 then
					table.insert(recentNotes, 1, result)
					settings.set("fcpxHacks.recentNotes", recentNotes)
				else
					table.remove(recentNotes, selectedRow)
					table.insert(recentNotes, 1, result)
					settings.set("fcpxHacks.recentNotes", recentNotes)
				end
			end

			if filmstripView then
				libraries:toggleViewMode():press()
			end

			if wasPlaying then fcp:menuBar():selectMenu("View", "Playback", "Play") end

		end):bgDark(true):query(existingValue):queryChangedCallback(function()
			--------------------------------------------------------------------------------
			-- Chooser Query Changed by User:
			--------------------------------------------------------------------------------
			local recentNotes = settings.get("fcpxHacks.recentNotes") or {}

			local currentQuery = noteChooser:query()

			local currentQueryTable = {
				{
					["text"] = currentQuery
				},
			}

			for i=1, #recentNotes do
				table.insert(currentQueryTable, recentNotes[i])
			end

			noteChooser:choices(currentQueryTable)
			return
		end)

		--------------------------------------------------------------------------------
		-- Allow for Reduce Transparency:
		--------------------------------------------------------------------------------
		if screen.accessibilitySettings()["ReduceTransparency"] then
			noteChooser:fgColor(nil)
					   :subTextColor(nil)
		else
			noteChooser:fgColor(drawing.color.x11.snow)
					   :subTextColor(drawing.color.x11.snow)
		end

		--------------------------------------------------------------------------------
		-- Show Chooser:
		--------------------------------------------------------------------------------
		noteChooser:show()

	end

	--------------------------------------------------------------------------------
	-- CHANGE TIMELINE CLIP HEIGHT:
	--------------------------------------------------------------------------------
	function changeTimelineClipHeight(direction)

		--------------------------------------------------------------------------------
		-- Prevent multiple keypresses:
		--------------------------------------------------------------------------------
		if mod.changeTimelineClipHeightAlreadyInProgress then return end
		mod.changeTimelineClipHeightAlreadyInProgress = true

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Change Value of Zoom Slider:
		--------------------------------------------------------------------------------
		shiftClipHeight(direction)

		--------------------------------------------------------------------------------
		-- Keep looping it until the key is released.
		--------------------------------------------------------------------------------
		timer.doUntil(function() return not mod.changeTimelineClipHeightAlreadyInProgress end, function()
			shiftClipHeight(direction)
		end, eventtap.keyRepeatInterval())
	end

		--------------------------------------------------------------------------------
		-- SHIFT CLIP HEIGHT:
		--------------------------------------------------------------------------------
		function shiftClipHeight(direction)
			--------------------------------------------------------------------------------
			-- Find the Timeline Appearance Button:
			--------------------------------------------------------------------------------
			local appearance = fcp:timeline():toolbar():appearance()
			appearance:show()
			if direction == "up" then
				appearance:clipHeight():increment()
			else
				appearance:clipHeight():decrement()
			end
		end

		--------------------------------------------------------------------------------
		-- CHANGE TIMELINE CLIP HEIGHT RELEASE:
		--------------------------------------------------------------------------------
		function changeTimelineClipHeightRelease()
			mod.changeTimelineClipHeightAlreadyInProgress = false
			fcp:timeline():toolbar():appearance():hide()
		end

	--------------------------------------------------------------------------------
	-- SELECT CLIP AT LANE:
	--------------------------------------------------------------------------------
	function selectClipAtLane(whichLane)
		local content = fcp:timeline():contents()
		local playheadX = content:playhead():getPosition()

		local clips = content:clipsUI(false, function(clip)
			local frame = clip:frame()
			return playheadX >= frame.x and playheadX < (frame.x + frame.w)
		end)

		if clips == nil then
			debugMessage("No clips detected in selectClipAtLane().")
			return false
		end

		if whichLane > #clips then
			return false
		end

		--------------------------------------------------------------------------------
		-- Sort the table:
		--------------------------------------------------------------------------------
		table.sort(clips, function(a, b) return a:position().y > b:position().y end)

		content:selectClip(clips[whichLane])

		return true
	end

	--------------------------------------------------------------------------------
	-- MENU ITEM SHORTCUT:
	--------------------------------------------------------------------------------
	function menuItemShortcut(i, x, y, z)

		local fcpxElements = ax.applicationElement(fcp:application())

		local whichMenuBar = nil
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if fcpxElements[i]:attributeValue("AXRole") == "AXMenuBar" then
				whichMenuBar = i
			end
		end

		if whichMenuBar == nil then
			displayErrorMessage("Failed to find menu bar.\n\nError occurred in menuItemShortcut().")
			return
		end

		if i ~= "" and x ~= "" and y == "" and z == "" then
			fcpxElements[whichMenuBar][i][1][x]:performAction("AXPress")
		elseif i ~= "" and x ~= "" and y ~= "" and z == "" then
			fcpxElements[whichMenuBar][i][1][x][1][y]:performAction("AXPress")
		elseif i ~= "" and x ~= "" and y ~= "" and z ~= "" then
			fcpxElements[whichMenuBar][i][1][x][1][y][1][z]:performAction("AXPress")
		end

	end

	--------------------------------------------------------------------------------
	-- CUT AND SWITCH MULTI-CAM:
	--------------------------------------------------------------------------------
	function cutAndSwitchMulticam(whichMode, whichAngle)

		if whichMode == "Audio" then
			if not fcp:performShortcut("MultiAngleEditStyleAudio") then
				dialog.displayErrorMessage("We were unable to trigger the 'Cut/Switch Multicam Audio Only' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
				return "Failed"
			end
		end

		if whichMode == "Video" then
			if not fcp:performShortcut("MultiAngleEditStyleVideo") then
				dialog.displayErrorMessage("We were unable to trigger the 'Cut/Switch Multicam Video Only' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
				return "Failed"
			end
		end

		if whichMode == "Both" then
			if not fcp:performShortcut("MultiAngleEditStyleAudioVideo") then
				dialog.displayErrorMessage("We were unable to trigger the 'Cut/Switch Multicam Audio and Video' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
				return "Failed"
			end
		end

		if not fcp:performShortcut("CutSwitchAngle" .. tostring(string.format("%02d", whichAngle))) then
			dialog.displayErrorMessage("We were unable to trigger the 'Cut and Switch to Viewer Angle " .. tostring(whichAngle) .. "' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
			return "Failed"
		end

	end

	--------------------------------------------------------------------------------
	-- MOVE TO PLAYHEAD:
	--------------------------------------------------------------------------------
	function moveToPlayhead()

		local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false

		if enableClipboardHistory then
			clipboard.stopWatching()
		end

		if not fcp:performShortcut("Cut") then
			dialog.displayErrorMessage("Failed to trigger the 'Cut' Shortcut.\n\nError occurred in moveToPlayhead().")
			goto moveToPlayheadEnd
		end

		if not fcp:performShortcut("Paste") then
			dialog.displayErrorMessage("Failed to trigger the 'Paste' Shortcut.\n\nError occurred in moveToPlayhead().")
			goto moveToPlayheadEnd
		end

		::moveToPlayheadEnd::
		if enableClipboardHistory then
			timer.doAfter(2, function() clipboard.startWatching() end)
		end

	end

	--------------------------------------------------------------------------------
	-- HIGHLIGHT FINAL CUT PRO BROWSER PLAYHEAD:
	--------------------------------------------------------------------------------
	function highlightFCPXBrowserPlayhead()
		plugins("hs.fcpxhacks.plugins.browser.playhead").highlight()
	end

	--------------------------------------------------------------------------------
	-- SELECT ALL TIMELINE CLIPS IN SPECIFIC DIRECTION:
	--------------------------------------------------------------------------------
	function selectAllTimelineClips(forwards)

		local content = fcp:timeline():contents()
		local playheadX = content:playhead():getPosition()

		local clips = content:clipsUI(false, function(clip)
			local frame = clip:frame()
			if forwards then
				return playheadX <= frame.x
			else
				return playheadX >= frame.x
			end
		end)

		if clips == nil then
			displayErrorMessage("No clips could be detected.\n\nError occurred in selectAllTimelineClips().")
			return false
		end

		content:selectClips(clips)

		return true

	end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     C O M M O N    F U N C T I O N S                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- GENERAL:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- EMAIL BUG REPORT:
	--------------------------------------------------------------------------------
	function emailBugReport()
		local mailer = sharing.newShare("com.apple.share.Mail.compose"):subject("[" .. metadata.scriptName .. " " .. metadata.scriptVersion .. "] Bug Report"):recipients({metadata.bugReportEmail})
																	   :shareItems({"Please enter any notes, comments or suggestions here.\n\n---",console.getConsole(true), screen.mainScreen():snapshot()})
	end

	--------------------------------------------------------------------------------
	-- PROWL API KEY VALID:
	--------------------------------------------------------------------------------
	function prowlAPIKeyValid(input)

		local result = false
		local errorMessage = nil

		prowlAction = "https://api.prowlapp.com/publicapi/verify?apikey=" .. input
		httpResponse, httpBody, httpHeader = http.get(prowlAction, nil)

		if string.match(httpBody, "success") then
			result = true
		else
			local xml = slaxdom:dom(tostring(httpBody))
			errorMessage = xml['root']['el'][1]['kids'][1]['value']
		end

		return result, errorMessage

	end

	--------------------------------------------------------------------------------
	-- DELETE ALL HIGHLIGHTS:
	--------------------------------------------------------------------------------
	function deleteAllHighlights()
		plugins("hs.fcpxhacks.plugins.browser.playhead").deleteAllHighlights()
	end

	--------------------------------------------------------------------------------
	-- CHECK FOR SCRIPT UPDATES:
	--------------------------------------------------------------------------------
	function checkForUpdates()

		local enableCheckForUpdates = settings.get("fcpxHacks.enableCheckForUpdates")
		if enableCheckForUpdates then
			debugMessage("Checking for updates.")
			latestScriptVersion = nil
			updateResponse, updateBody, updateHeader = http.get(metadata.checkUpdateURL, nil)
			if updateResponse == 200 then
				if updateBody:sub(1,8) == "LATEST: " then
					--------------------------------------------------------------------------------
					-- Update Script Version:
					--------------------------------------------------------------------------------
					latestScriptVersion = updateBody:sub(9)

					--------------------------------------------------------------------------------
					-- macOS Notification:
					--------------------------------------------------------------------------------
					if not mod.shownUpdateNotification then
						if latestScriptVersion > metadata.scriptVersion then
							updateNotification = notify.new(function() getScriptUpdate() end):setIdImage(image.imageFromPath(metadata.iconPath))
																:title(metadata.scriptName .. " Update Available")
																:subTitle("Version " .. latestScriptVersion)
																:informativeText("Do you wish to install?")
																:hasActionButton(true)
																:actionButtonTitle("Install")
																:otherButtonTitle("Not Yet")
																:send()
							mod.shownUpdateNotification = true
						end
					end
				end
			end
		end

	end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                             W A T C H E R S                                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AUTOMATICALLY DO THINGS WHEN FINAL CUT PRO IS ACTIVATED OR DEACTIVATED:
--------------------------------------------------------------------------------
function finalCutProWatcher(appName, eventType, appObject)
	if (appName == "Final Cut Pro") then
		if (eventType == application.watcher.activated) then
			finalCutProActive()
		elseif (eventType == application.watcher.deactivated) or (eventType == application.watcher.terminated) then
			finalCutProNotActive()
		end
	end
end

--------------------------------------------------------------------------------
-- AUTOMATICALLY DO THINGS WHEN FINAL CUT PRO WINDOWS ARE CHANGED:
--------------------------------------------------------------------------------
function finalCutProWindowWatcher()

	wasInFullscreenMode = false

	--------------------------------------------------------------------------------
	-- Final Cut Pro Fullscreen Playback Filter:
	--------------------------------------------------------------------------------
	fullscreenPlaybackWatcher = windowfilter.new(true)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Fullscreen Playback Window Created:
	--------------------------------------------------------------------------------
	fullscreenPlaybackWatcher:subscribe(windowfilter.windowCreated,(function(window, applicationName)
		if applicationName == "Final Cut Pro" then
			if window:title() == "" then
				local fcpx = fcp:application()
				if fcpx ~= nil then
					local fcpxElements = ax.applicationElement(fcpx)
					if fcpxElements ~= nil then
						if fcpxElements[1] ~= nil then
							if fcpxElements[1][1] ~= nil then
								if fcpxElements[1][1]:attributeValue("AXIdentifier") == "_NS:523" then
									-------------------------------------------------------------------------------
									-- Hide HUD:
									--------------------------------------------------------------------------------
									if settings.get("fcpxHacks.enableHacksHUD") then
											hackshud:hide()
											wasInFullscreenMode = true
									end
								end
							end
						end
					end
				end
			end
		end
	end), true)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Fullscreen Playback Window Destroyed:
	--------------------------------------------------------------------------------
	fullscreenPlaybackWatcher:subscribe(windowfilter.windowDestroyed,(function(window, applicationName)
		if applicationName == "Final Cut Pro" then
			if window:title() == "" then
				-------------------------------------------------------------------------------
				-- Show HUD:
				--------------------------------------------------------------------------------
				if wasInFullscreenMode then
					if settings.get("fcpxHacks.enableHacksHUD") then
							hackshud:show()
					end
				end
			end
		end
	end), true)

	-- Watch the command editor showing and hiding.
	fcp:commandEditor():watch({
		show = function(commandEditor)
			--------------------------------------------------------------------------------
			-- Disable Hotkeys:
			--------------------------------------------------------------------------------
			if hotkeys ~= nil then -- For the rare case when Command Editor is open on load.
				debugMessage("Disabling Hotkeys")
				hotkeys:exit()
			end

			--------------------------------------------------------------------------------
			-- Hide the HUD:
			--------------------------------------------------------------------------------
			hackshud.hide()
		end,
		hide = function(commandEditor)
			--------------------------------------------------------------------------------
			-- Refresh Keyboard Shortcuts:
			--------------------------------------------------------------------------------
			timer.doAfter(0.0000000000001, function() bindKeyboardShortcuts() end)
			--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Show the HUD:
			--------------------------------------------------------------------------------
			if settings.get("fcpxHacks.enableHacksHUD") then
				hackshud.show()
			end
		end
	})
end

	--------------------------------------------------------------------------------
	-- Final Cut Pro Active:
	--------------------------------------------------------------------------------
	function finalCutProActive()
		--------------------------------------------------------------------------------
		-- Only do once:
		--------------------------------------------------------------------------------
		if mod.isFinalCutProActive then return end
		mod.isFinalCutProActive = true

		--------------------------------------------------------------------------------
		-- Don't trigger until after the script has loaded:
		--------------------------------------------------------------------------------
		if not mod.hacksLoaded then
			timer.waitUntil(function() return mod.hacksLoaded end, function()
				if fcp:isFrontmost() then
					mod.isFinalCutProActive = false
					finalCutProActive()
				end
			end, 0.1)
			return
		end

		--------------------------------------------------------------------------------
		-- Enable Hotkeys:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			hotkeys:enter()
		end)

		--------------------------------------------------------------------------------
		-- Enable Hacks HUD:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			if settings.get("fcpxHacks.enableHacksHUD") then
				hackshud:show()
			end
		end)

		--------------------------------------------------------------------------------
		-- Enable Voice Commands:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			if settings.get("fcpxHacks.enableVoiceCommands") then
				voicecommands.start()
			end
		end)

		--------------------------------------------------------------------------------
		-- Update Current Language:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			fcp:getCurrentLanguage(true)
		end)

	end

	--------------------------------------------------------------------------------
	-- Final Cut Pro Not Active:
	--------------------------------------------------------------------------------
	function finalCutProNotActive()
		--------------------------------------------------------------------------------
		-- Only do once:
		--------------------------------------------------------------------------------
		if not mod.isFinalCutProActive then return end
		mod.isFinalCutProActive = false

		--------------------------------------------------------------------------------
		-- Don't trigger until after the script has loaded:
		--------------------------------------------------------------------------------
		if not mod.hacksLoaded then return end

		--------------------------------------------------------------------------------
		-- Disable Voice Commands:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableVoiceCommands") then
			voicecommands.stop()
		end

		--------------------------------------------------------------------------------
		-- Disable hotkeys:
		--------------------------------------------------------------------------------
		hotkeys:exit()

		--------------------------------------------------------------------------------
		-- Delete the Mouse Circle:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		-------------------------------------------------------------------------------
		-- If not focussed on Hammerspoon then hide HUD:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableHacksHUD") then
			if application.frontmostApplication():bundleID() ~= "org.hammerspoon.Hammerspoon" then
				hackshud:hide()
			end
		end
	end

--------------------------------------------------------------------------------
-- AUTOMATICALLY DO THINGS WHEN FCPX PLIST IS UPDATED:
--------------------------------------------------------------------------------
function finalCutProSettingsWatcher(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-24) == "com.apple.FinalCut.plist" then
            doReload = true
        end
    end
    if doReload then

		--------------------------------------------------------------------------------
		-- Refresh Keyboard Shortcuts if Command Set Changed & Command Editor Closed:
		--------------------------------------------------------------------------------
    	if mod.lastCommandSet ~= fcp:getActiveCommandSetPath() then
    		if not fcp:commandEditor():isShowing() then
	    		timer.doAfter(0.0000000000001, function() bindKeyboardShortcuts() end)
			end
		end

    	--------------------------------------------------------------------------------
    	-- Update Menubar Icon:
    	--------------------------------------------------------------------------------
    	timer.doAfter(0.0000000000001, function() updateMenubarIcon() end)

 		--------------------------------------------------------------------------------
		-- Reload Hacks HUD:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableHacksHUD") then
			timer.doAfter(0.0000000000001, function() hackshud:refresh() end)
		end

    end
end

--------------------------------------------------------------------------------
-- NOTIFICATION WATCHER:
--------------------------------------------------------------------------------
function notificationWatcher()

	--------------------------------------------------------------------------------
	-- USED FOR DEVELOPMENT:
	--------------------------------------------------------------------------------
	--foo = distributednotifications.new(function(name, object, userInfo) print(string.format("name: %s\nobject: %s\nuserInfo: %s\n", name, object, inspect(userInfo))) end)
	--foo:start()

	--------------------------------------------------------------------------------
	-- SHARE SUCCESSFUL NOTIFICATION WATCHER:
	--------------------------------------------------------------------------------
	-- NOTE: ProTranscoderDidCompleteNotification doesn't seem to trigger when exporting small clips.
	shareSuccessNotificationWatcher = distributednotifications.new(notificationWatcherAction, "uploadSuccess")
	shareSuccessNotificationWatcher:start()

	--------------------------------------------------------------------------------
	-- SHARE UNSUCCESSFUL NOTIFICATION WATCHER:
	--------------------------------------------------------------------------------
	shareFailedNotificationWatcher = distributednotifications.new(notificationWatcherAction, "ProTranscoderDidFailNotification")
	shareFailedNotificationWatcher:start()

end

	--------------------------------------------------------------------------------
	-- NOTIFICATION WATCHER ACTION:
	--------------------------------------------------------------------------------
	function notificationWatcherAction(name, object, userInfo)
		-- FOR DEBUGGING/DEVELOPMENT
		-- debugMessage(string.format("name: %s\nobject: %s\nuserInfo: %s\n", name, object, hs.inspect(userInfo)))

		local message = nil
		if name == "uploadSuccess" then
			local info = findNotificationInfo(object)
			message = i18n("shareSuccessful", {info = info})
		elseif name == "ProTranscoderDidFailNotification" then
			message = i18n("shareFailed")
		else -- unexpected result
			return
		end

		local notificationPlatform = settings.get("fcpxHacks.notificationPlatform")

		if notificationPlatform["Prowl"] then
			local prowlAPIKey = settings.get("fcpxHacks.prowlAPIKey") or nil
			if prowlAPIKey ~= nil then
				local prowlApplication = http.encodeForQuery("FINAL CUT PRO")
				local prowlEvent = http.encodeForQuery("")
				local prowlDescription = http.encodeForQuery(message)

				local prowlAction = "https://api.prowlapp.com/publicapi/add?apikey=" .. prowlAPIKey .. "&application=" .. prowlApplication .. "&event=" .. prowlEvent .. "&description=" .. prowlDescription
				httpResponse, httpBody, httpHeader = http.get(prowlAction, nil)

				if not string.match(httpBody, "success") then
					local xml = slaxdom:dom(tostring(httpBody))
					local errorMessage = xml['root']['el'][1]['kids'][1]['value'] or nil
					if errorMessage ~= nil then writeToConsole("PROWL ERROR: " .. tools.trim(tostring(errorMessage))) end
				end
			end
		end

		if notificationPlatform["iMessage"] then
			local iMessageTarget = settings.get("fcpxHacks.iMessageTarget") or ""
			if iMessageTarget ~= "" then
				messages.iMessage(iMessageTarget, message)
			end
		end
	end

	--------------------------------------------------------------------------------
	-- FIND NOTIFICATION INFO:
	--------------------------------------------------------------------------------
	function findNotificationInfo(path)
		local plistPath = path .. "/ShareStatus.plist"
		if fs.attributes(plistPath) then
			local shareStatus = plist.fileToTable(plistPath)
			if shareStatus then
				local latestType = nil
				local latestInfo = nil

				for type,results in pairs(shareStatus) do
					local info = results[#results]
					if latestInfo == nil or latestInfo.fullDate < info.fullDate then
						latestInfo = info
						latestType = type
					end
				end

				if latestInfo then
					-- put the first resultStr into a top-level value to make it easier for i18n
					if latestInfo.resultStr then
						latestInfo.result = latestInfo.resultStr[1]
					end
					local message = i18n("shareDetails_"..latestType, latestInfo)
					if not message then
						message = i18n("shareUnknown", {type = latestType})
					end
					return message
				end
			end
		end
		return i18n("shareUnknown", {type = "unknown"})
	end

--------------------------------------------------------------------------------
-- SHARED CLIPBOARD WATCHER:
--------------------------------------------------------------------------------
function sharedClipboardFileWatcher(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-10) == ".fcpxhacks" then
            doReload = true
        end
    end
    if doReload then
		debugMessage("Refreshing Shared Clipboard.")
    end
end

--------------------------------------------------------------------------------
-- SHARED XML FILE WATCHER:
--------------------------------------------------------------------------------
function sharedXMLFileWatcher(files)
	debugMessage("Refreshing Shared XML Folder.")

	for _,file in pairs(files) do
        if file:sub(-7) == ".fcpxml" then
			local testFile = io.open(file, "r")
			if testFile ~= nil then
				testFile:close()

				local editorName = string.reverse(string.sub(string.reverse(file), string.find(string.reverse(file), "/", 1) + 1, string.find(string.reverse(file), "/", string.find(string.reverse(file), "/", 1) + 1) - 1))

				if host.localizedName() ~= editorName then

					local xmlSharingPath = settings.get("fcpxHacks.xmlSharingPath")
					sharedXMLNotification = notify.new(function() fcp:importXML(file) end)
						:setIdImage(image.imageFromPath(metadata.iconPath))
						:title("New XML Recieved")
						:subTitle(file:sub(string.len(xmlSharingPath) + 1 + string.len(editorName) + 1, -8))
						:informativeText(metadata.scriptName .. " has recieved a new XML file.")
						:hasActionButton(true)
						:actionButtonTitle("Import XML")
						:send()

				end
			end
        end
    end
end

--------------------------------------------------------------------------------
-- AUTOMATICALLY RELOAD HAMMERSPOON WHEN CONFIG FILES ARE UPDATED:
--------------------------------------------------------------------------------
function hammerspoonConfigWatcher(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-4) == ".lua" then
            doReload = true
        end
    end
    if doReload then
        hs.reload()
    end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                L E T ' S     D O     T H I S     T H I N G !               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

loadScript()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
