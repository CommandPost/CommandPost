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
local touchbar 									= require("hs._asm.touchbar")

local fcp										= require("hs.finalcutpro")
local plist										= require("hs.plist")

--------------------------------------------------------------------------------
-- MODULES:
--------------------------------------------------------------------------------

local dialog									= require("hs.fcpxhacks.modules.dialog")
local slaxdom 									= require("hs.fcpxhacks.modules.slaxml.slaxdom")
local slaxml									= require("hs.fcpxhacks.modules.slaxml")
local tools										= require("hs.fcpxhacks.modules.tools")
local just										= require("hs.just")

--------------------------------------------------------------------------------
-- PLUGINS:
--------------------------------------------------------------------------------

local clipboard									= require("hs.fcpxhacks.plugins.clipboard")
local hacksconsole								= require("hs.fcpxhacks.plugins.hacksconsole")
local hackshud									= require("hs.fcpxhacks.plugins.hackshud")
local voicecommands 							= require("hs.fcpxhacks.plugins.voicecommands")

--------------------------------------------------------------------------------
-- DEFAULT SETTINGS:
--------------------------------------------------------------------------------

local defaultSettings = {						["enableShortcutsDuringFullscreenPlayback"] 	= false,
												["scrollingTimelineActive"] 					= false,
												["enableHacksShortcutsInFinalCutPro"] 			= false,
												["enableVoiceCommands"]							= false,
												["chooserRememberLast"]							= true,
												["chooserShowAutomation"] 						= true,
												["chooserShowShortcuts"] 						= true,
												["chooserShowHacks"] 							= true,
												["chooserShowVideoEffects"] 					= true,
												["chooserShowAudioEffects"] 					= true,
												["chooserShowTransitions"] 						= true,
												["chooserShowTitles"] 							= true,
												["chooserShowGenerators"] 						= true,
												["chooserShowMenuItems"]						= true,
												["menubarShortcutsEnabled"] 					= true,
												["menubarAutomationEnabled"] 					= true,
												["menubarToolsEnabled"] 						= true,
												["menubarHacksEnabled"] 						= true,
												["enableCheckForUpdates"]						= true,
												["hudShowInspector"]							= true,
												["hudShowDropTargets"]							= true,
												["hudShowButtons"]								= true,
												["checkForUpdatesInterval"]						= 600 }

--------------------------------------------------------------------------------
-- VARIABLES:
--------------------------------------------------------------------------------

local execute									= hs.execute									-- Execute!
local touchBarSupported					 		= touchbar.supported()							-- Touch Bar Supported?
local log										= logger.new("fcpx10-3")

mod.debugMode									= false											-- Debug Mode is off by default.
mod.scrollingTimelineSpacebarPressed			= false											-- Was spacebar pressed?
mod.scrollingTimelineWatcherWorking 			= false											-- Is Scrolling Timeline Spacebar Held Down?
mod.releaseColorBoardDown						= false											-- Color Board Shortcut Currently Being Pressed
mod.releaseMouseColorBoardDown 					= false											-- Color Board Mouse Shortcut Currently Being Pressed
mod.mouseInsideTouchbar							= false											-- Mouse Inside Touch Bar?
mod.shownUpdateNotification		 				= false											-- Shown Update Notification Already?

mod.touchBarWindow 								= nil			 								-- Touch Bar Window

mod.browserHighlight 							= nil											-- Used for Highlight Browser Playhead
mod.browserHighlightTimer 						= nil											-- Used for Highlight Browser Playhead
mod.browserHighlight							= nil											-- Scrolling Timeline Timer

mod.scrollingTimelineTimer						= nil											-- Scrolling Timeline Timer
mod.scrollingTimelineScrollbarTimer				= nil											-- Scrolling Timeline Scrollbar Timer

mod.finalCutProShortcutKey 						= nil											-- Table of all Final Cut Pro Shortcuts
mod.finalCutProShortcutKeyPlaceholders 			= nil											-- Table of all needed Final Cut Pro Shortcuts
mod.newDeviceMounted 							= nil											-- New Device Mounted Volume Watcher
mod.lastCommandSet								= nil											-- Last Keyboard Shortcut Command Set
mod.allowMovingMarkers							= nil											-- Used in refreshMenuBar
mod.FFPeriodicBackupInterval 					= nil											-- Used in refreshMenuBar
mod.FFSuspendBGOpsDuringPlay 					= nil											-- Used in refreshMenuBar
mod.FFEnableGuards								= nil											-- Used in refreshMenuBar
mod.FFAutoRenderDelay							= nil											-- Used in refreshMenuBar

mod.installedLanguages							= {}											-- Table of Installed Language Files

mod.hacksLoaded 								= false											-- Has FCPX Hacks Loaded Yet?

mod.isFinalCutProActive 						= false											-- Is Final Cut Pro Active? Used by Watchers.
mod.wasFinalCutProOpen							= false											-- Used by Assign Transitions/Effects/Titles/Generators Shortcut

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
	-- Need Accessibility Activated:
	--------------------------------------------------------------------------------
	hs.accessibilityState(true)

	--------------------------------------------------------------------------------
	-- Limit Error Messages for a clean console:
	--------------------------------------------------------------------------------
	console.titleVisibility("hidden")
	hotkey.setLogLevel("warning")
	windowfilter.setLogLevel(0) -- The wfilter errors are too annoying.
	windowfilter.ignoreAlways['System Events'] = true

	--------------------------------------------------------------------------------
	-- Setup i18n Languages:
	--------------------------------------------------------------------------------
	local languagePath = "hs/fcpxhacks/languages/"
	for file in fs.dir(languagePath) do
		if file:sub(-4) == ".lua" then
			local languageFile = io.open(hs.configdir .. "/" .. languagePath .. file, "r")
			if languageFile ~= nil then
				local languageFileData = languageFile:read("*all")
				if string.find(languageFileData, "-- LANGUAGE: ") ~= nil then
					local fileLanguage = string.sub(languageFileData, string.find(languageFileData, "-- LANGUAGE: ") + 13, string.find(languageFileData, "\n") - 1)
					local languageID = string.sub(file, 1, -5)
					mod.installedLanguages[#mod.installedLanguages + 1] = { id = languageID, language = fileLanguage }
				end
				languageFile:close()
			end
		end
	end
	table.sort(mod.installedLanguages, function(a, b) return a.language < b.language end)

	--------------------------------------------------------------------------------
	-- First time running 10.3? If so, let's trash the settings incase there's
	-- compatibility issues with an older version of FCPX Hacks:
	--------------------------------------------------------------------------------
	if settings.get("fcpxHacks.firstTimeRunning103") == nil then

		writeToConsole("First time running Final Cut Pro 10.3. Trashing settings.")

		--------------------------------------------------------------------------------
		-- Trash all FCPX Hacks Settings:
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
		settings.set("fcpxHacks.lastFinalCutProVersion", fcp.version())
	else
		if lastFinalCutProVersion ~= fcp.version() then
			settings.set("fcpxHacks.chooserMenuItems", nil) -- Reset Chooser Menu Items.
			settings.set("fcpxHacks.lastFinalCutProVersion", fcp.version())
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
	-- Check if we need to update the Final Cut Pro Shortcut Files:
	--------------------------------------------------------------------------------
	if settings.get("fcpxHacks.lastVersion") == nil then
		settings.set("fcpxHacks.lastVersion", fcpxhacks.scriptVersion)
		settings.set("fcpxHacks.enableHacksShortcutsInFinalCutPro", false)
	else
		if tonumber(settings.get("fcpxHacks.lastVersion")) < tonumber(fcpxhacks.scriptVersion) then
			if settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro") then
				local finalCutProRunning = fcp.running()
				if finalCutProRunning then
					dialog.displayMessage(i18n("newKeyboardShortcuts"))
					updateKeyboardShortcuts()
					if not fcp.restart() then
						--------------------------------------------------------------------------------
						-- Failed to restart Final Cut Pro:
						--------------------------------------------------------------------------------
						dialog.displayErrorMessage(i18n("restartFinalCutProFailed"))
						return "Failed"
					end
				else
					dialog.displayMessage(i18n("newKeyboardShortcuts"))
					updateKeyboardShortcuts()
				end
			end
		end
		settings.set("fcpxHacks.lastVersion", fcpxhacks.scriptVersion)
	end

	--------------------------------------------------------------------------------
	-- Setup Touch Bar:
	--------------------------------------------------------------------------------
	if touchBarSupported then

		--------------------------------------------------------------------------------
		-- New Touch Bar:
		--------------------------------------------------------------------------------
		mod.touchBarWindow = touchbar.new()

		--------------------------------------------------------------------------------
		-- Touch Bar Watcher:
		--------------------------------------------------------------------------------
		mod.touchBarWindow:setCallback(touchbarWatcher)

		--------------------------------------------------------------------------------
		-- Get last Touch Bar Location from Settings:
		--------------------------------------------------------------------------------
		local lastTouchBarLocation = settings.get("fcpxHacks.lastTouchBarLocation")
		if lastTouchBarLocation ~= nil then	mod.touchBarWindow:topLeft(lastTouchBarLocation) end

		--------------------------------------------------------------------------------
		-- Draggable Touch Bar:
		--------------------------------------------------------------------------------
		local events = eventtap.event.types
		touchbarKeyboardWatcher = eventtap.new({events.flagsChanged, events.keyDown, events.leftMouseDown}, function(ev)
			if mod.mouseInsideTouchbar then
				if ev:getType() == events.flagsChanged and ev:getRawEventData().CGEventData.flags == 524576 then
					mod.touchBarWindow:backgroundColor{ red = 1 }
								  	:movable(true)
								  	:acceptsMouseEvents(false)
				elseif ev:getType() ~= events.leftMouseDown then
					mod.touchBarWindow:backgroundColor{ white = 0 }
								  :movable(false)
								  :acceptsMouseEvents(true)
					settings.set("fcpxHacks.lastTouchBarLocation", mod.touchBarWindow:topLeft())
				end
			end
			return false
		end):start()

	end

	--------------------------------------------------------------------------------
	-- Setup Watches:
	--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Create and start the application event watcher:
		--------------------------------------------------------------------------------
		watcher = application.watcher.new(finalCutProWatcher):start()

		--------------------------------------------------------------------------------
		-- Watch For Hammerspoon Script Updates:
		--------------------------------------------------------------------------------
		hammerspoonWatcher = pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", hammerspoonConfigWatcher):start()

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
		-- Full Screen Keyboard Watcher:
		--------------------------------------------------------------------------------
		fullscreenKeyboardWatcher()

		--------------------------------------------------------------------------------
		-- Final Cut Pro Window Watcher:
		--------------------------------------------------------------------------------
		finalCutProWindowWatcher()

		--------------------------------------------------------------------------------
		-- Scrolling Timeline Watcher:
		--------------------------------------------------------------------------------
		scrollingTimelineWatcher()

		--------------------------------------------------------------------------------
		-- Clipboard Watcher:
		--------------------------------------------------------------------------------
		local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false
		if enableClipboardHistory then clipboard.startWatching() end

		--------------------------------------------------------------------------------
		-- Notification Watcher:
		--------------------------------------------------------------------------------
		local enableMobileNotifications = settings.get("fcpxHacks.enableMobileNotifications") or false
		if enableMobileNotifications then notificationWatcher() end

		--------------------------------------------------------------------------------
		-- Media Import Watcher:
		--------------------------------------------------------------------------------
		local enableMediaImportWatcher = settings.get("fcpxHacks.enableMediaImportWatcher") or false
		if enableMediaImportWatcher then mediaImportWatcher() end

	--------------------------------------------------------------------------------
	-- Bind Keyboard Shortcuts:
	--------------------------------------------------------------------------------
	mod.lastCommandSet = fcp.getActiveCommandSetPath()
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
	if fcp.frontmost() then

		--------------------------------------------------------------------------------
		-- Used by Watchers to prevent double-ups:
		--------------------------------------------------------------------------------
		mod.isFinalCutProActive = true

		--------------------------------------------------------------------------------
		-- Enable Final Cut Pro Shortcut Keys:
		--------------------------------------------------------------------------------
		hotkeys:enter()

		--------------------------------------------------------------------------------
		-- Enable Fullscreen Playback Shortcut Keys:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") then
			fullscreenKeyboardWatcherDown:start()
		end

		--------------------------------------------------------------------------------
		-- Enable Scrolling Timeline:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.scrollingTimelineActive") then
			mod.scrollingTimelineWatcherDown:start()
		end

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

		--------------------------------------------------------------------------------
		-- Disable Fullscreen Playback Shortcut Keys:
		--------------------------------------------------------------------------------
		if fullscreenKeyboardWatcherUp ~= nil then
			fullscreenKeyboardWatcherUp:stop()
			fullscreenKeyboardWatcherDown:stop()
		end

		--------------------------------------------------------------------------------
		-- Disable Scrolling Timeline:
		--------------------------------------------------------------------------------
		if mod.scrollingTimelineWatcherDown ~= nil then
			mod.scrollingTimelineWatcherDown:stop()
		end

	end

	-------------------------------------------------------------------------------
	-- Set up Menubar:
	--------------------------------------------------------------------------------
	fcpxMenubar = menubar.newWithPriority(1)

		--------------------------------------------------------------------------------
		-- Set Tool Tip:
		--------------------------------------------------------------------------------
		fcpxMenubar:setTooltip("FCPX Hacks " .. i18n("version") .. " " .. fcpxhacks.scriptVersion)

		--------------------------------------------------------------------------------
		-- Work out Menubar Display Mode:
		--------------------------------------------------------------------------------
		updateMenubarIcon()

		--------------------------------------------------------------------------------
		-- Populate the Menubar for the first time:
		--------------------------------------------------------------------------------
		refreshMenuBar(true)

	-------------------------------------------------------------------------------
	-- Set up Chooser:
	-------------------------------------------------------------------------------
	hacksconsole.new()

	--------------------------------------------------------------------------------
	-- All loaded!
	--------------------------------------------------------------------------------
	writeToConsole("Successfully loaded.")
	dialog.displayNotification("FCPX Hacks (v" .. fcpxhacks.scriptVersion .. ") " .. i18n("hasLoaded"))

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
	console.clearConsole()

	--------------------------------------------------------------------------------
	-- Get Multicam Angle From Selected Clip:
	--------------------------------------------------------------------------------
	local result = getMulticamAngleFromSelectedClip()

end

--------------------------------------------------------------------------------
-- GET MULTICAM ANGLE FROM SELECTED CLIP:
--------------------------------------------------------------------------------
function getMulticamAngleFromSelectedClip()

	--------------------------------------------------------------------------------
	-- Ninja Pasteboard Copy:
	--------------------------------------------------------------------------------
	local result, clipboardData = ninjaPasteboardCopy()
	if not result then
		dialog.displayErrorMessage("Ninja Pasteboard Copy Failed.")
		return false
	end

	--------------------------------------------------------------------------------
	-- Convert Binary Data to Table:
	--------------------------------------------------------------------------------
	local clipboardTable = plist.binaryToTable(clipboardData)
	if clipboardTable == nil then
		dialog.displayErrorMessage("Converting Binary Data to Table failed.")
		return false
	end

	--------------------------------------------------------------------------------
	-- Read ffpasteboardobject from Table:
	--------------------------------------------------------------------------------
	local fcpxData = clipboardTable["ffpasteboardobject"]
	if fcpxData == nil then
		dialog.displayErrorMessage("Reading 'ffpasteboardobject' from Table failed.")
		return false
	end

	--------------------------------------------------------------------------------
	-- Convert base64 Data to Table:
	--------------------------------------------------------------------------------
	local fcpxTable = plist.base64ToTable(fcpxData)
	if fcpxTable == nil then
		dialog.displayErrorMessage("Converting Binary Data to Table failed.")
		return false
	end

	--------------------------------------------------------------------------------
	-- DEBUG:
	--------------------------------------------------------------------------------
	--writeToConsole(inspect(fcpxTable, {indent="\t"}), true)
	tt = fcpxTable -- Global value for testing.

	--------------------------------------------------------------------------------
	-- Check the item isMultiAngle:
	--------------------------------------------------------------------------------
	local isMultiAngle = false
	for k, v in pairs(fcpxTable["$objects"]) do

		if type(fcpxTable["$objects"][k]) == "table" then
			if fcpxTable["$objects"][k]["isMultiAngle"] then
				isMultiAngle = true

				print(fcpxTable["$objects"][k])
			end
		end

	end
	if not isMultiAngle then
		dialog.displayErrorMessage("The selected item is not a multi-angle clip.")
		return false
	end

	--------------------------------------------------------------------------------
	-- Get FFAnchoredCollection ID:
	--------------------------------------------------------------------------------
	local FFAnchoredCollectionID = nil
	for k, v in pairs(fcpxTable["$objects"]) do
		if type(fcpxTable["$objects"][k]) == "table" then
			if fcpxTable["$objects"][k]["$classname"] ~= nil then
				if fcpxTable["$objects"][k]["$classname"] == "FFAnchoredCollection" then
					FFAnchoredCollectionID = k - 1
				end
			end
		end
	end

	--------------------------------------------------------------------------------
	-- Find all FFAnchoredCollection's:
	--------------------------------------------------------------------------------
	local FFAnchoredCollectionTable = {}
	for k, v in pairs(fcpxTable["$objects"]) do
		if type(fcpxTable["$objects"][k]) == "table" then
			for a, b in pairs(fcpxTable["$objects"][k]) do
				if fcpxTable["$objects"][k][a] == FFAnchoredCollectionID then
					FFAnchoredCollectionTable[#FFAnchoredCollectionTable + 1] = fcpxTable["$objects"][k]
				end
				if type(fcpxTable["$objects"][k][a]) == "table" then
					for c, d in pairs(fcpxTable["$objects"][k][a]) do
						if fcpxTable["$objects"][k][a][c] == FFAnchoredCollectionID then
							FFAnchoredCollectionTable[#FFAnchoredCollectionTable + 1] = fcpxTable["$objects"][k]
						end
						if type(fcpxTable["$objects"][k][a][c]) == "table" then
							for e, f in pairs(fcpxTable["$objects"][k][a][c]) do
								if fcpxTable["$objects"][k][a][c][e] == FFAnchoredCollectionID then
									FFAnchoredCollectionTable[#FFAnchoredCollectionTable + 1] = fcpxTable["$objects"][k]
								end
							end
						end
					end
				end
			end
		end
	end

	print("FFAnchoredCollectionTable:")
	writeToConsole(inspect(FFAnchoredCollectionTable), true)

	-- TO DO: Work out how the hell to detect which is the active multi-cam angle.

	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	do return end
	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------



	--------------------------------------------------------------------------------
	-- Get the videoAngle:
	--------------------------------------------------------------------------------
	local videoAngle = nil
	for k, v in pairs(fcpxTable["$objects"]) do

		if type(fcpxTable["$objects"][k]) == "table" then
			if fcpxTable["$objects"][k]["videoAngle"] then
				videoAngle = fcpxTable["$objects"][k]["videoAngle"]
			end
		end

	end
	if videoAngle == nil then
		dialog.displayErrorMessage("Could not get videoAngle.")
		return false
	end

	--------------------------------------------------------------------------------
	-- Get the videoAngle Reference:
	--------------------------------------------------------------------------------
	local videoAngleReference = fcpxTable["$objects"][videoAngle["CF$UID"] + 1]

	if videoAngleReference == nil then
		dialog.displayErrorMessage("Could not get videoAngleReference.")
		return false
	end
	print("videoAngleReference: " .. tostring(videoAngleReference))

end

--------------------------------------------------------------------------------
-- NINJA PASTEBOARD COPY:
--------------------------------------------------------------------------------
function ninjaPasteboardCopy()

	--------------------------------------------------------------------------------
	-- Variables:
	--------------------------------------------------------------------------------
	local ninjaPasteboardCopyError = false
	local finalCutProClipboardUTI = fcp.clipboardUTI()
	local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false

	--------------------------------------------------------------------------------
	-- Stop Watching Clipboard:
	--------------------------------------------------------------------------------
	if enableClipboardHistory then clipboard.stopWatching() end

	--------------------------------------------------------------------------------
	-- Save Current Clipboard Contents for later:
	--------------------------------------------------------------------------------
	local originalClipboard = pasteboard.readDataForUTI(finalCutProClipboardUTI)

	--------------------------------------------------------------------------------
	-- Trigger 'copy' from Menubar:
	--------------------------------------------------------------------------------
	local menuBar = fcp:app():menuBar()
	if menuBar:isEnabled("Edit", "Copy") then
		menuBar:selectMenu("Edit", "Copy")
	else
		debugMessage("ERROR: Failed to select Copy from Menubar.")
		if enableClipboardHistory then clipboard.startWatching() end
		return false
	end

	--------------------------------------------------------------------------------
	-- Wait until something new is actually on the Pasteboard:
	--------------------------------------------------------------------------------
	local newClipboard = nil
	just.doUntil(function()
		newClipboard = pasteboard.readDataForUTI(finalCutProClipboardUTI)
		if newClipboard ~= originalClipboard then
			return true
		end
	end, 10)
	if newClipboard == nil then
		debugMessage("ERROR: Failed to get new clipboard contents.")
		if enableClipboardHistory then clipboard.startWatching() end
		return false
	end

	--------------------------------------------------------------------------------
	-- Restore Original Clipboard Contents:
	--------------------------------------------------------------------------------
	if originalClipboard ~= nil then
		local result = pasteboard.writeDataForUTI(finalCutProClipboardUTI, originalClipboard)
		if not result then
			debugMessage("ERROR: Failed to restore original Clipboard item.")
			if enableClipboardHistory then clipboard.startWatching() end
			return false
		end
	end

	--------------------------------------------------------------------------------
	-- Start Watching Clipboard:
	--------------------------------------------------------------------------------
	if enableClipboardHistory then clipboard.startWatching() end

	--------------------------------------------------------------------------------
	-- Return New Clipboard:
	--------------------------------------------------------------------------------
	return true, newClipboard

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
	local defaultShortcutKeys = {
		FCPXHackLaunchFinalCutPro									= { characterString = fcp.keyCodeTranslator("l"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() fcp.launch() end, 				 					releasedFn = nil,														repeatFn = nil, 		global = true },
		FCPXHackShowListOfShortcutKeys 								= { characterString = fcp.keyCodeTranslator("f1"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() displayShortcutList() end, 							releasedFn = nil, 														repeatFn = nil, 		global = true },

		FCPXHackHighlightBrowserPlayhead 							= { characterString = fcp.keyCodeTranslator("h"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() highlightFCPXBrowserPlayhead() end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackRevealInBrowserAndHighlight 						= { characterString = fcp.keyCodeTranslator("f"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() matchFrameThenHighlightFCPXBrowserPlayhead() end, 	releasedFn = nil, 														repeatFn = nil },
		FCPXHackSingleMatchFrameAndHighlight 						= { characterString = fcp.keyCodeTranslator("s"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() singleMatchFrame() end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackRevealMulticamClipInBrowserAndHighlight 			= { characterString = fcp.keyCodeTranslator("d"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() multicamMatchFrame(true) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackRevealMulticamClipInAngleEditorAndHighlight 		= { characterString = fcp.keyCodeTranslator("g"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() multicamMatchFrame(false) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackBatchExportFromBrowser 								= { characterString = fcp.keyCodeTranslator("e"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() batchExport() end, 									releasedFn = nil,														repeatFn = nil },
		FCPXHackChangeBackupInterval 								= { characterString = fcp.keyCodeTranslator("b"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() changeBackupInterval() end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackToggleTimecodeOverlays 								= { characterString = fcp.keyCodeTranslator("t"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() toggleTimecodeOverlay() end,						releasedFn = nil, 														repeatFn = nil },
		FCPXHackToggleMovingMarkers 								= { characterString = fcp.keyCodeTranslator("y"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() toggleMovingMarkers() end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackAllowTasksDuringPlayback 							= { characterString = fcp.keyCodeTranslator("p"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() togglePerformTasksDuringPlayback() end, 			releasedFn = nil, 														repeatFn = nil },

		FCPXHackSelectColorBoardPuckOne 							= { characterString = fcp.keyCodeTranslator("m"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() colorBoardSelectPuck("*", "global") end, 			releasedFn = nil, 														repeatFn = nil },
		FCPXHackSelectColorBoardPuckTwo 							= { characterString = fcp.keyCodeTranslator(","), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() colorBoardSelectPuck("*", "shadows") end, 			releasedFn = nil, 														repeatFn = nil },
		FCPXHackSelectColorBoardPuckThree 							= { characterString = fcp.keyCodeTranslator("."), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() colorBoardSelectPuck("*", "midtones") end, 			releasedFn = nil, 														repeatFn = nil },
		FCPXHackSelectColorBoardPuckFour 							= { characterString = fcp.keyCodeTranslator("/"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() colorBoardSelectPuck("*", "highlights") end, 		releasedFn = nil, 														repeatFn = nil },

		FCPXHackRestoreKeywordPresetOne 							= { characterString = fcp.keyCodeTranslator("1"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() restoreKeywordSearches(1) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackRestoreKeywordPresetTwo 							= { characterString = fcp.keyCodeTranslator("2"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() restoreKeywordSearches(2) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackRestoreKeywordPresetThree 							= { characterString = fcp.keyCodeTranslator("3"),			modifiers = {"ctrl", "option", "command"}, 			fn = function() restoreKeywordSearches(3) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackRestoreKeywordPresetFour 							= { characterString = fcp.keyCodeTranslator("4"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() restoreKeywordSearches(4) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackRestoreKeywordPresetFive 							= { characterString = fcp.keyCodeTranslator("5"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() restoreKeywordSearches(5) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackRestoreKeywordPresetSix 							= { characterString = fcp.keyCodeTranslator("6"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() restoreKeywordSearches(6) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackRestoreKeywordPresetSeven 							= { characterString = fcp.keyCodeTranslator("7"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() restoreKeywordSearches(7) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackRestoreKeywordPresetEight 							= { characterString = fcp.keyCodeTranslator("8"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() restoreKeywordSearches(8) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackRestoreKeywordPresetNine 							= { characterString = fcp.keyCodeTranslator("9"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() restoreKeywordSearches(9) end, 						releasedFn = nil, 														repeatFn = nil },

		FCPXHackSaveKeywordPresetOne 								= { characterString = fcp.keyCodeTranslator("1"), 			modifiers = {"ctrl", "option", "command", "shift"}, fn = function() saveKeywordSearches(1) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackSaveKeywordPresetTwo 								= { characterString = fcp.keyCodeTranslator("2"), 			modifiers = {"ctrl", "option", "command", "shift"}, fn = function() saveKeywordSearches(2) end,							releasedFn = nil, 														repeatFn = nil },
		FCPXHackSaveKeywordPresetThree 								= { characterString = fcp.keyCodeTranslator("3"), 			modifiers = {"ctrl", "option", "command", "shift"}, fn = function() saveKeywordSearches(3) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackSaveKeywordPresetFour 								= { characterString = fcp.keyCodeTranslator("4"), 			modifiers = {"ctrl", "option", "command", "shift"}, fn = function() saveKeywordSearches(4) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackSaveKeywordPresetFive 								= { characterString = fcp.keyCodeTranslator("5"), 			modifiers = {"ctrl", "option", "command", "shift"}, fn = function() saveKeywordSearches(5) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackSaveKeywordPresetSix 								= { characterString = fcp.keyCodeTranslator("6"), 			modifiers = {"ctrl", "option", "command", "shift"}, fn = function() saveKeywordSearches(6) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackSaveKeywordPresetSeven 								= { characterString = fcp.keyCodeTranslator("7"), 			modifiers = {"ctrl", "option", "command", "shift"}, fn = function() saveKeywordSearches(7) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackSaveKeywordPresetEight 								= { characterString = fcp.keyCodeTranslator("8"), 			modifiers = {"ctrl", "option", "command", "shift"}, fn = function() saveKeywordSearches(8) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackSaveKeywordPresetNine 								= { characterString = fcp.keyCodeTranslator("9"), 			modifiers = {"ctrl", "option", "command", "shift"}, fn = function() saveKeywordSearches(9) end, 						releasedFn = nil, 														repeatFn = nil },

		FCPXHackEffectsOne			 								= { characterString = fcp.keyCodeTranslator("1"), 			modifiers = {"ctrl", "shift"}, 						fn = function() effectsShortcut(1) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackEffectsTwo			 								= { characterString = fcp.keyCodeTranslator("2"), 			modifiers = {"ctrl", "shift"}, 						fn = function() effectsShortcut(2) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackEffectsThree			 							= { characterString = fcp.keyCodeTranslator("3"), 			modifiers = {"ctrl", "shift"}, 						fn = function() effectsShortcut(3) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackEffectsFour			 								= { characterString = fcp.keyCodeTranslator("4"), 			modifiers = {"ctrl", "shift"}, 						fn = function() effectsShortcut(4) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackEffectsFive			 								= { characterString = fcp.keyCodeTranslator("5"), 			modifiers = {"ctrl", "shift"}, 						fn = function() effectsShortcut(5) end, 							releasedFn = nil, 														repeatFn = nil },

		FCPXHackTransitionsOne			 							= { characterString = "", 									modifiers = {}, 									fn = function() transitionsShortcut(1) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackTransitionsTwo			 							= { characterString = "", 									modifiers = {}, 									fn = function() transitionsShortcut(2) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackTransitionsThree			 						= { characterString = "", 									modifiers = {}, 									fn = function() transitionsShortcut(3) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackTransitionsFour			 							= { characterString = "", 									modifiers = {}, 									fn = function() transitionsShortcut(4) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackTransitionsFive			 							= { characterString = "", 									modifiers = {}, 									fn = function() transitionsShortcut(5) end, 						releasedFn = nil, 														repeatFn = nil },

		FCPXHackTitlesOne			 								= { characterString = "", 									modifiers = {}, 									fn = function() titlesShortcut(1) end, 								releasedFn = nil, 														repeatFn = nil },
		FCPXHackTitlesTwo			 								= { characterString = "", 									modifiers = {}, 									fn = function() titlesShortcut(2) end, 								releasedFn = nil, 														repeatFn = nil },
		FCPXHackTitlesThree			 								= { characterString = "", 									modifiers = {}, 									fn = function() titlesShortcut(3) end, 								releasedFn = nil, 														repeatFn = nil },
		FCPXHackTitlesFour			 								= { characterString = "", 									modifiers = {}, 									fn = function() titlesShortcut(4) end, 								releasedFn = nil, 														repeatFn = nil },
		FCPXHackTitlesFive			 								= { characterString = "", 									modifiers = {}, 									fn = function() titlesShortcut(5) end, 								releasedFn = nil, 														repeatFn = nil },

		FCPXHackGeneratorsOne			 							= { characterString = "", 									modifiers = {}, 									fn = function() generatorsShortcut(1) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackGeneratorsTwo			 							= { characterString = "", 									modifiers = {}, 									fn = function() generatorsShortcut(2) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackGeneratorsThree			 							= { characterString = "", 									modifiers = {}, 									fn = function() generatorsShortcut(3) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackGeneratorsFour			 							= { characterString = "", 									modifiers = {}, 									fn = function() generatorsShortcut(4) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackGeneratorsFive			 							= { characterString = "", 									modifiers = {}, 									fn = function() generatorsShortcut(5) end, 							releasedFn = nil, 														repeatFn = nil },

		FCPXHackScrollingTimeline	 								= { characterString = fcp.keyCodeTranslator("w"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() toggleScrollingTimeline() end, 						releasedFn = nil, 														repeatFn = nil },

		FCPXHackColorPuckOne			 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "global") end,					releasedFn = nil, 											repeatFn = nil },
		FCPXHackColorPuckTwo			 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "shadows") end,					releasedFn = nil, 											repeatFn = nil },
		FCPXHackColorPuckThree			 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "midtones") end,					releasedFn = nil, 											repeatFn = nil },
		FCPXHackColorPuckFour			 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "highlights") end,				releasedFn = nil, 											repeatFn = nil },

		FCPXHackSaturationPuckOne			 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("saturation", "global") end, 				releasedFn = nil, 											repeatFn = nil },
		FCPXHackSaturationPuckTwo			 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("saturation", "shadows") end, 				releasedFn = nil, 											repeatFn = nil },
		FCPXHackSaturationPuckThree			 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("saturation", "midtones") end, 			releasedFn = nil, 											repeatFn = nil },
		FCPXHackSaturationPuckFour			 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("saturation", "highlights") end, 			releasedFn = nil, 											repeatFn = nil },

		FCPXHackExposurePuckOne			 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("exposure", "global") end,					releasedFn = nil, 											repeatFn = nil },
		FCPXHackExposurePuckTwo			 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("exposure", "shadows") end,				releasedFn = nil, 											repeatFn = nil },
		FCPXHackExposurePuckThree			 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("exposure", "midtones") end,				releasedFn = nil, 											repeatFn = nil },
		FCPXHackExposurePuckFour			 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("exposure", "highlights") end,				releasedFn = nil, 											repeatFn = nil },

		FCPXHackColorPuckOneUp			 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "global", "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackColorPuckTwoUp			 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "shadows", "up") end,				releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackColorPuckThreeUp		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "midtones", "up") end,			releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackColorPuckFourUp		 								= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "highlights", "up") end,			releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },

		FCPXHackColorPuckOneDown		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "global", "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackColorPuckTwoDown		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "shadows", "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackColorPuckThreeDown		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "midtones", "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackColorPuckFourDown	 								= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "highlights", "down") end, 		releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },

		FCPXHackColorPuckOneLeft		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "global", "left") end, 			releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackColorPuckTwoLeft		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "global", "left") end, 			releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackColorPuckThreeLeft		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "global", "left") end, 			releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackColorPuckFourLeft	 								= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "global", "left") end, 			releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },

		FCPXHackColorPuckOneRight		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "global", "right") end, 			releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackColorPuckTwoRight		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "shadows", "right") end, 			releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackColorPuckThreeRight		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "midtones", "right") end, 		releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackColorPuckFourRight	 								= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("color", "highlights", "right") end, 		releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },

		FCPXHackSaturationPuckOneUp			 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("saturation", "global", "up") end, 		releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackSaturationPuckTwoUp			 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("saturation", "shadows", "up") end, 		releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackSaturationPuckThreeUp		 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("saturation", "midtones", "up") end, 		releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackSaturationPuckFourUp		 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("saturation", "highlights", "up") end, 	releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },

		FCPXHackSaturationPuckOneDown		 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("saturation", "global", "down") end, 		releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackSaturationPuckTwoDown		 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("saturation", "shadows", "down") end, 		releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackSaturationPuckThreeDown		 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("saturation", "midtones", "down") end, 	releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackSaturationPuckFourDown	 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("saturation", "highlights", "down") end, 	releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },

		FCPXHackExposurePuckOneUp			 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("exposure", "global", "up") end, 			releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackExposurePuckTwoUp			 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("exposure", "shadows", "up") end, 			releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackExposurePuckThreeUp		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("exposure", "midtones", "up") end, 		releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackExposurePuckFourUp		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("exposure", "highlights", "up") end, 		releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },

		FCPXHackExposurePuckOneDown		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("exposure", "global", "down") end, 		releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackExposurePuckTwoDown		 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("exposure", "shadows", "down") end, 		releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackExposurePuckThreeDown		 						= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("exposure", "midtones", "down") end, 		releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },
		FCPXHackExposurePuckFourDown	 							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardSelectPuck("exposure", "highlights", "down") end, 	releasedFn = function() colorBoardSelectPuckRelease() end,	repeatFn = nil },

		FCPXHackChangeTimelineClipHeightUp 							= { characterString = fcp.keyCodeTranslator("+"),		 	modifiers = {"ctrl", "option", "command"}, 			fn = function() changeTimelineClipHeight("up") end, 				releasedFn = function() changeTimelineClipHeightRelease() end, 			repeatFn = nil },
		FCPXHackChangeTimelineClipHeightDown						= { characterString = fcp.keyCodeTranslator("-"),			modifiers = {"ctrl", "option", "command"}, 			fn = function() changeTimelineClipHeight("down") end, 				releasedFn = function() changeTimelineClipHeightRelease() end, 			repeatFn = nil },

		FCPXHackCreateOptimizedMediaOn								= { characterString = "", 									modifiers = {}, 									fn = function() toggleCreateOptimizedMedia(true) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCreateOptimizedMediaOff								= { characterString = "", 									modifiers = {}, 									fn = function() toggleCreateOptimizedMedia(false) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCreateMulticamOptimizedMediaOn						= { characterString = "", 									modifiers = {}, 									fn = function() toggleCreateMulticamOptimizedMedia(true) end, 		releasedFn = nil, 														repeatFn = nil },
		FCPXHackCreateMulticamOptimizedMediaOff						= { characterString = "", 									modifiers = {}, 									fn = function() toggleCreateMulticamOptimizedMedia(false) end, 		releasedFn = nil, 														repeatFn = nil },
		FCPXHackCreateProxyMediaOn									= { characterString = "", 									modifiers = {}, 									fn = function() toggleCreateProxyMedia(true) end, 					releasedFn = nil, 														repeatFn = nil },
		FCPXHackCreateProxyMediaOff									= { characterString = "", 									modifiers = {}, 									fn = function() toggleCreateProxyMedia(false) end, 					releasedFn = nil, 														repeatFn = nil },
		FCPXHackLeaveInPlaceOn										= { characterString = "", 									modifiers = {}, 									fn = function() toggleLeaveInPlace(true) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackLeaveInPlaceOff										= { characterString = "", 									modifiers = {}, 									fn = function() toggleLeaveInPlace(false) end, 						releasedFn = nil, 														repeatFn = nil },
		FCPXHackBackgroundRenderOn									= { characterString = "", 									modifiers = {}, 									fn = function() toggleBackgroundRender(true) end, 					releasedFn = nil, 														repeatFn = nil },
		FCPXHackBackgroundRenderOff									= { characterString = "", 									modifiers = {}, 									fn = function() toggleBackgroundRender(false) end, 					releasedFn = nil, 														repeatFn = nil },

		FCPXHackChangeSmartCollectionsLabel							= { characterString = "", 									modifiers = {}, 									fn = function() changeSmartCollectionsLabel() end, 					releasedFn = nil, 														repeatFn = nil },

		FCPXHackSelectClipAtLaneOne									= { characterString = "", 									modifiers = {}, 									fn = function() selectClipAtLane(1) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackSelectClipAtLaneTwo									= { characterString = "", 									modifiers = {}, 									fn = function() selectClipAtLane(2) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackSelectClipAtLaneThree								= { characterString = "", 									modifiers = {}, 									fn = function() selectClipAtLane(3) end,							releasedFn = nil, 														repeatFn = nil },
		FCPXHackSelectClipAtLaneFour								= { characterString = "", 									modifiers = {}, 									fn = function() selectClipAtLane(4) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackSelectClipAtLaneFive								= { characterString = "", 									modifiers = {}, 									fn = function() selectClipAtLane(5) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackSelectClipAtLaneSix									= { characterString = "", 									modifiers = {}, 									fn = function() selectClipAtLane(6) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackSelectClipAtLaneSeven								= { characterString = "", 									modifiers = {}, 									fn = function() selectClipAtLane(7) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackSelectClipAtLaneEight								= { characterString = "", 									modifiers = {}, 									fn = function() selectClipAtLane(8) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackSelectClipAtLaneNine								= { characterString = "", 									modifiers = {}, 									fn = function() selectClipAtLane(9) end, 							releasedFn = nil, 														repeatFn = nil },
		FCPXHackSelectClipAtLaneTen									= { characterString = "", 									modifiers = {}, 									fn = function() selectClipAtLane(10) end, 							releasedFn = nil, 														repeatFn = nil },

		FCPXHackPuckOneMouse										= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("*", "global") end, 			releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },
		FCPXHackPuckTwoMouse										= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("*", "shadows") end, 			releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },
		FCPXHackPuckThreeMouse										= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("*", "midtones") end, 			releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },
		FCPXHackPuckFourMouse										= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("*", "highlights") end, 		releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },

		FCPXHackColorPuckOneMouse									= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("color", "global") end, 		releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },
		FCPXHackColorPuckTwoMouse									= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("color", "shadows") end, 		releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },
		FCPXHackColorPuckThreeMouse									= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("color", "midtones") end, 		releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },
		FCPXHackColorPuckFourMouse									= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("color", "highlights") end, 	releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },

		FCPXHackSaturationPuckOneMouse								= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("saturation", "global") end,	releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },
		FCPXHackSaturationPuckTwoMouse								= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("saturation", "shadows") end,	releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },
		FCPXHackSaturationPuckThreeMouse							= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("saturation", "midtones") end,	releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },
		FCPXHackSaturationPuckFourMouse								= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("saturation", "highlights") end,releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },

		FCPXHackExposurePuckOneMouse								= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("exposure", "global") end,		releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },
		FCPXHackExposurePuckTwoMouse								= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("exposure", "shadows") end,		releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },
		FCPXHackExposurePuckThreeMouse								= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("exposure", "midtones") end,	releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },
		FCPXHackExposurePuckFourMouse								= { characterString = "", 									modifiers = {}, 									fn = function() colorBoardMousePuck("exposure", "highlights") end,	releasedFn = function() colorBoardMousePuckRelease() end, 				repeatFn = nil },

		FCPXHackMoveToPlayhead										= { characterString = "", 									modifiers = {}, 									fn = function() moveToPlayhead() end, 								releasedFn = nil, 														repeatFn = nil },

		FCPXHackCutSwitchAngle01Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 1) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle02Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 2) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle03Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 3) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle04Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 4) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle05Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 5) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle06Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 6) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle07Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 7) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle08Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 8) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle09Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 9) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle10Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 10) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle11Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 11) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle12Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 12) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle13Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 13) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle14Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 14) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle15Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 15) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle16Video								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Video", 16) end, 				releasedFn = nil, 														repeatFn = nil },

		FCPXHackCutSwitchAngle01Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 1) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle02Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 2) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle03Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 3) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle04Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 4) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle05Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 5) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle06Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 6) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle07Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 7) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle08Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 8) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle09Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 9) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle10Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 10) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle11Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 11) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle12Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 12) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle13Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 13) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle14Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 14) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle15Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 15) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle16Audio								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Audio", 16) end, 				releasedFn = nil, 														repeatFn = nil },

		FCPXHackCutSwitchAngle01Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 1) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle02Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 2) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle03Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 3) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle04Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 4) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle05Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 5) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle06Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 6) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle07Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 7) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle08Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 8) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle09Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 9) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle10Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 10) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle11Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 11) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle12Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 12) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle13Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 13) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle14Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 14) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle15Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 15) end, 				releasedFn = nil, 														repeatFn = nil },
		FCPXHackCutSwitchAngle16Both								= { characterString = "", 									modifiers = {}, 									fn = function() cutAndSwitchMulticam("Both", 16) end, 				releasedFn = nil, 														repeatFn = nil },

		FCPXHackConsole				 								= { characterString = fcp.keyCodeTranslator("space"), 		modifiers = {"ctrl"}, 								fn = function() hacksconsole.show(); mod.scrollingTimelineWatcherWorking = false end, releasedFn = nil, 									repeatFn = nil },

		FCPXHackHUD					 								= { characterString = fcp.keyCodeTranslator("a"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() toggleEnableHacksHUD() end, 						releasedFn = nil, 														repeatFn = nil },

		FCPXHackToggleTouchBar				 						= { characterString = fcp.keyCodeTranslator("z"), 			modifiers = {"ctrl", "option", "command"}, 			fn = function() toggleTouchBar() end, 								releasedFn = nil, 														repeatFn = nil },

		FCPXHackLockPlayhead										= { characterString = "", 									modifiers = {}, 									fn = function() toggleLockPlayhead() end, 							releasedFn = nil, 														repeatFn = nil },

		FCPXHackSelectForward										= { characterString = "", 									modifiers = {}, 									fn = function() selectAllTimelineClips(true) end, 					releasedFn = nil, 														repeatFn = nil },
		FCPXHackSelectBackwards										= { characterString = "", 									modifiers = {}, 									fn = function() selectAllTimelineClips(false) end, 					releasedFn = nil, 														repeatFn = nil },

		FCPXHackToggleVoiceCommands				 					= { characterString = "", 									modifiers = {}, 									fn = function() toggleEnableVoiceCommands() end, 					releasedFn = nil, 														repeatFn = nil },
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
		-- Update Active Command Set for hs.finalcutpro.performShortcut():
		--------------------------------------------------------------------------------
		fcp.getActiveCommandSet(nil, true)

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
	for i=1, #currentHotkeys do
		result = currentHotkeys[i]:delete()
	end

	--------------------------------------------------------------------------------
	-- Create a modal hotkey object with an absurd triggering hotkey:
	--------------------------------------------------------------------------------
	hotkeys = hotkey.modal.new({"command", "shift", "alt", "control"}, "F19")

	--------------------------------------------------------------------------------
	-- Enable Hotkeys Loop:
	--------------------------------------------------------------------------------
	for k, v in pairs(mod.finalCutProShortcutKey) do
		if mod.finalCutProShortcutKey[k]['characterString'] ~= "" and mod.finalCutProShortcutKey[k]['fn'] ~= nil then
			if mod.finalCutProShortcutKey[k]['global'] == true then
				--------------------------------------------------------------------------------
				-- Global Shortcut:
				--------------------------------------------------------------------------------
				hotkey.bind(mod.finalCutProShortcutKey[k]['modifiers'], mod.finalCutProShortcutKey[k]['characterString'], mod.finalCutProShortcutKey[k]['fn'], mod.finalCutProShortcutKey[k]['releasedFn'], mod.finalCutProShortcutKey[k]['repeatFn'])
			else
				--------------------------------------------------------------------------------
				-- Final Cut Pro Specific Shortcut:
				--------------------------------------------------------------------------------
				hotkeys:bind(mod.finalCutProShortcutKey[k]['modifiers'], mod.finalCutProShortcutKey[k]['characterString'], mod.finalCutProShortcutKey[k]['fn'], mod.finalCutProShortcutKey[k]['releasedFn'], mod.finalCutProShortcutKey[k]['repeatFn'])
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

	local activeCommandSetTable = fcp.getActiveCommandSet(nil, true)

	if activeCommandSetTable ~= nil then
		for k, v in pairs(mod.finalCutProShortcutKeyPlaceholders) do

			if activeCommandSetTable[k] ~= nil then

				--------------------------------------------------------------------------------
				-- Multiple keyboard shortcuts for single function:
				--------------------------------------------------------------------------------
				if type(activeCommandSetTable[k][1]) == "table" then
					for x=1, #activeCommandSetTable[k] do

						local tempModifiers = nil
						local tempCharacterString = nil
						local keypadModifier = false

						if activeCommandSetTable[k][x]["modifiers"] ~= nil then
							if string.find(activeCommandSetTable[k][x]["modifiers"], "keypad") then keypadModifier = true end
							tempModifiers = fcp.translateKeyboardModifiers(activeCommandSetTable[k][x]["modifiers"])
						end

						if activeCommandSetTable[k][x]["modifierMask"] ~= nil then
							tempModifiers = fcp.translateModifierMask(activeCommandSetTable[k][x]["modifierMask"])
						end

						if activeCommandSetTable[k][x]["characterString"] ~= nil then
							tempCharacterString = fcp.translateKeyboardCharacters(activeCommandSetTable[k][x]["characterString"])
						end

						if activeCommandSetTable[k][x]["character"] ~= nil then
							if keypadModifier then
								tempCharacterString = fcp.translateKeyboardKeypadCharacters(activeCommandSetTable[k][x]["character"])
							else
								tempCharacterString = fcp.translateKeyboardCharacters(activeCommandSetTable[k][x]["character"])
							end
						end

						local tempGlobalShortcut = mod.finalCutProShortcutKeyPlaceholders[k]['global'] or false

						local xValue = ""
						if x ~= 1 then xValue = tostring(x) end

						mod.finalCutProShortcutKey[k .. xValue] = {
							characterString 	= 		tempCharacterString,
							modifiers 			= 		tempModifiers,
							fn 					= 		mod.finalCutProShortcutKeyPlaceholders[k]['fn'],
							releasedFn 			= 		mod.finalCutProShortcutKeyPlaceholders[k]['releasedFn'],
							repeatFn 			= 		mod.finalCutProShortcutKeyPlaceholders[k]['repeatFn'],
							global 				= 		tempGlobalShortcut,
						}

					end
				--------------------------------------------------------------------------------
				-- Single keyboard shortcut for a single function:
				--------------------------------------------------------------------------------
				else

					local tempModifiers = nil
					local tempCharacterString = nil
					local keypadModifier = false

					if activeCommandSetTable[k]["modifiers"] ~= nil then
						tempModifiers = fcp.translateKeyboardModifiers(activeCommandSetTable[k]["modifiers"])
					end

					if activeCommandSetTable[k]["modifierMask"] ~= nil then
						tempModifiers = fcp.translateModifierMask(activeCommandSetTable[k]["modifierMask"])
					end

					if activeCommandSetTable[k]["characterString"] ~= nil then
						tempCharacterString = fcp.translateKeyboardCharacters(activeCommandSetTable[k]["characterString"])
					end

					if activeCommandSetTable[k]["character"] ~= nil then
						if keypadModifier then
							tempCharacterString = fcp.translateKeyboardKeypadCharacters(activeCommandSetTable[k]["character"])
						else
							tempCharacterString = fcp.translateKeyboardCharacters(activeCommandSetTable[k]["character"])
						end
					end

					local tempGlobalShortcut = mod.finalCutProShortcutKeyPlaceholders[k]['global'] or false

					mod.finalCutProShortcutKey[k] = {
						characterString 	= 		tempCharacterString,
						modifiers 			= 		tempModifiers,
						fn 					= 		mod.finalCutProShortcutKeyPlaceholders[k]['fn'],
						releasedFn 			= 		mod.finalCutProShortcutKeyPlaceholders[k]['releasedFn'],
						repeatFn 			= 		mod.finalCutProShortcutKeyPlaceholders[k]['repeatFn'],
						global 				= 		tempGlobalShortcut,
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
	if result ~= "Done" then
		dialog.displayErrorMessage(i18n("failedToWriteToFile") .. "\n\n" .. result)
		return false
	end

	--------------------------------------------------------------------------------
	-- Revert back to default keyboard layout:
	--------------------------------------------------------------------------------
	local result = fcp.setPreference("Active Command Set", fcp.path() .. "/Contents/Resources/" .. fcp.currentLanguage() .. ".lproj/Default.commandset")
	if not result then
		dialog.displayErrorMessage(i18n("activeCommandSetResetError"))
		return false
	end

end

--------------------------------------------------------------------------------
-- ENABLE HACKS SHORTCUTS:
--------------------------------------------------------------------------------
function enableHacksShortcuts()
	local appleScript = [[
		set finalCutProPath to "]] .. fcp.path() .. [["
		set finalCutProLanguages to ]] .. inspect(fcp.languages()) .. [[

		--------------------------------------------------------------------------------
		-- Replace Files:
		--------------------------------------------------------------------------------
		try
			do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/new/NSProCommandGroups.plist '" & finalCutProPath & "/Contents/Resources/NSProCommandGroups.plist'" with administrator privileges
			on error
				return "NSProCommandGroups.plist"
		end try
		try
			do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/new/NSProCommands.plist '" & finalCutProPath & "/Contents/Resources/NSProCommands.plist'" with administrator privileges
			on error
				return "NSProCommands.plist"
		end try
		repeat with whichLanguage in finalCutProLanguages
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/new/" & whichLanguage & ".lproj/Default.commandset '" & finalCutProPath & "/Contents/Resources/" & whichLanguage & ".lproj/Default.commandset'" with administrator privileges
				on error
					return whichLanguage & ".lproj/Default.commandset"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/new/" & whichLanguage & ".lproj/NSProCommandDescriptions.strings '" & finalCutProPath & "/Contents/Resources/" & whichLanguage & ".lproj/NSProCommandDescriptions.strings'" with administrator privileges
				on error
					return whichLanguage & ".lproj/NSProCommandDescriptions.strings"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/new/" & whichLanguage & ".lproj/NSProCommandNames.strings '" & finalCutProPath & "/Contents/Resources/" & whichLanguage & ".lproj/NSProCommandNames.strings'" with administrator privileges
				on error
					return whichLanguage & ".lproj/NSProCommandNames.strings"
			end try
		end repeat
		return "Done"
	]]
	ok,result = osascript.applescript(appleScript)
	return result
end

--------------------------------------------------------------------------------
-- DISABLE HACKS SHORTCUTS:
--------------------------------------------------------------------------------
function disableHacksShortcuts()
	local appleScript = [[
		set finalCutProPath to "]] .. fcp.path() .. [["
		set finalCutProLanguages to ]] .. inspect(fcp.languages()) .. [[

		try
			do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/old/NSProCommandGroups.plist '" & finalCutProPath & "/Contents/Resources/NSProCommandGroups.plist'" with administrator privileges
			on error
				return "NSProCommandGroups.plist"
		end try
		try
			do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/old/NSProCommands.plist '" & finalCutProPath & "/Contents/Resources/NSProCommands.plist'" with administrator privileges
			on error
				return "NSProCommands.plist"
		end try
		repeat with whichLanguage in finalCutProLanguages
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/old/" & whichLanguage & ".lproj/Default.commandset '" & finalCutProPath & "/Contents/Resources/" & whichLanguage & ".lproj/Default.commandset'" with administrator privileges
				on error
					return whichLanguage & ".lproj/Default.commandset"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/old/" & whichLanguage & ".lproj/NSProCommandDescriptions.strings '" & finalCutProPath & "/Contents/Resources/" & whichLanguage & ".lproj/NSProCommandDescriptions.strings'" with administrator privileges
				on error
					return whichLanguage & ".lproj/NSProCommandDescriptions.strings"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpxhacks/plist/10-3/old/" & whichLanguage & ".lproj/NSProCommandNames.strings '" & finalCutProPath & "/Contents/Resources/" & whichLanguage & ".lproj/NSProCommandNames.strings'" with administrator privileges
				on error
					return whichLanguage & ".lproj/NSProCommandNames.strings"
			end try
		end repeat
		return "Done"
	]]
	ok,result = osascript.applescript(appleScript)
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

	--------------------------------------------------------------------------------
	-- REFRESH MENUBAR:
	--------------------------------------------------------------------------------
	function refreshMenuBar(refreshPlistValues)

		--------------------------------------------------------------------------------
		-- Maximum Length of Menubar Strings:
		--------------------------------------------------------------------------------
		local maxTextLength = 25

		--------------------------------------------------------------------------------
		-- Assume FCPX is closed if not told otherwise:
		--------------------------------------------------------------------------------
		local fcpxActive = fcp.frontmost()
		local fcpxRunning = fcp.running()

		--------------------------------------------------------------------------------
		-- We only refresh plist values if necessary as this takes time:
		--------------------------------------------------------------------------------
		if refreshPlistValues == true then

			--------------------------------------------------------------------------------
			-- Used for debugging:
			--------------------------------------------------------------------------------
			debugMessage("Menubar refreshed with latest plist values.")

			--------------------------------------------------------------------------------
			-- Read Final Cut Pro Preferences:
			--------------------------------------------------------------------------------
			local preferences = fcp.getPreferences()
			if preferences == nil then
				dialog.displayErrorMessage(i18n("failedToReadFCPPreferences"))
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Get plist values for Allow Moving Markers:
			--------------------------------------------------------------------------------
			mod.allowMovingMarkers = false

			local result = plist.fileToTable(fcp.path() .. "/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist")
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
		-- Get Menubar Display Mode from Settings:
		--------------------------------------------------------------------------------
		local displayMenubarAsIcon = settings.get("fcpxHacks.displayMenubarAsIcon") or false

		--------------------------------------------------------------------------------
		-- Get Sizing Preferences:
		--------------------------------------------------------------------------------
		local displayHighlightShape = nil
		displayHighlightShape = settings.get("fcpxHacks.displayHighlightShape")
		local displayHighlightShapeRectangle = false
		local displayHighlightShapeCircle = false
		local displayHighlightShapeDiamond = false
		if displayHighlightShape == nil then 			displayHighlightShapeRectangle = true		end
		if displayHighlightShape == "Rectangle" then 	displayHighlightShapeRectangle = true		end
		if displayHighlightShape == "Circle" then 		displayHighlightShapeCircle = true			end
		if displayHighlightShape == "Diamond" then 		displayHighlightShapeDiamond = true			end

		--------------------------------------------------------------------------------
		-- Get Highlight Colour Preferences:
		--------------------------------------------------------------------------------
		local displayHighlightColour = nil
		displayHighlightColour = settings.get("fcpxHacks.displayHighlightColour")

		--------------------------------------------------------------------------------
		-- Get Enable Shortcuts During Fullscreen Playback from Settings:
		--------------------------------------------------------------------------------
		local enableShortcutsDuringFullscreenPlayback = settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") or false

		--------------------------------------------------------------------------------
		-- Get Enable Hacks Shortcuts in Final Cut Pro from Settings:
		--------------------------------------------------------------------------------
		local enableHacksShortcutsInFinalCutPro = settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro") or false

		--------------------------------------------------------------------------------
		-- Get Enable Proxy Menu Item:
		--------------------------------------------------------------------------------
		local enableProxyMenuIcon = settings.get("fcpxHacks.enableProxyMenuIcon") or false

		--------------------------------------------------------------------------------
		-- Hammerspoon Settings:
		--------------------------------------------------------------------------------
		local startHammerspoonOnLaunch = hs.autoLaunch()
		local hammerspoonCheckForUpdates = hs.automaticallyCheckForUpdates()
		local hammerspoonDockIcon = hs.dockIcon()
		local hammerspoonMenuIcon = hs.menuIcon()

		--------------------------------------------------------------------------------
		-- Scrolling Timeline:
		--------------------------------------------------------------------------------
		scrollingTimelineActive = settings.get("fcpxHacks.scrollingTimelineActive") or false

		--------------------------------------------------------------------------------
		-- Enable Mobile Notifications:
		--------------------------------------------------------------------------------
		enableMobileNotifications = settings.get("fcpxHacks.enableMobileNotifications") or false

		--------------------------------------------------------------------------------
		-- Enable Media Import Watcher:
		--------------------------------------------------------------------------------
		enableMediaImportWatcher = settings.get("fcpxHacks.enableMediaImportWatcher") or false

		--------------------------------------------------------------------------------
		-- Touch Bar Location:
		--------------------------------------------------------------------------------
		local displayTouchBarLocation = settings.get("fcpxHacks.displayTouchBarLocation") or "Mouse"
		local displayTouchBarLocationMouse = false
		if displayTouchBarLocation == "Mouse" then displayTouchBarLocationMouse = true end
		local displayTouchBarLocationTimelineTopCentre = false
		if displayTouchBarLocation == "TimelineTopCentre" then displayTouchBarLocationTimelineTopCentre = true end

		--------------------------------------------------------------------------------
		-- Display Touch Bar:
		--------------------------------------------------------------------------------
		local displayTouchBar = settings.get("fcpxHacks.displayTouchBar") or false

		--------------------------------------------------------------------------------
		-- Enable Check for Updates:
		--------------------------------------------------------------------------------
		local enableCheckForUpdates = settings.get("fcpxHacks.enableCheckForUpdates") or false

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

		local hudShowInspector 		= settings.get("fcpxHacks.hudShowInspector")
		local hudShowDropTargets 	= settings.get("fcpxHacks.hudShowDropTargets")
		local hudShowButtons 		= settings.get("fcpxHacks.hudShowButtons")

		local hudButtonOne 			= settings.get("fcpxHacks.hudButtonOne") 	or " (Unassigned)"
		local hudButtonTwo 			= settings.get("fcpxHacks.hudButtonTwo") 	or " (Unassigned)"
		local hudButtonThree 		= settings.get("fcpxHacks.hudButtonThree") 	or " (Unassigned)"
		local hudButtonFour 		= settings.get("fcpxHacks.hudButtonFour") 	or " (Unassigned)"

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

		if enableSharedClipboard and enableClipboardHistory then

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
							table.insert(submenu, {title = file:sub(1, -8), fn = function() fcp.importXML(xmlPath) end, disabled = not fcpxRunning})
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
		-- Lock Timeline Playhead:
		--------------------------------------------------------------------------------
		local lockTimelinePlayhead = settings.get("fcpxHacks.lockTimelinePlayhead") or false

		--------------------------------------------------------------------------------
		-- Current Language:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp.currentLanguage()

		--------------------------------------------------------------------------------
		-- Effects Shortcuts:
		--------------------------------------------------------------------------------
		local effectsListUpdated 	= settings.get("fcpxHacks.effectsListUpdated") or false
		local effectsShortcutOne 	= settings.get("fcpxHacks.effectsShortcutOne")
		local effectsShortcutTwo 	= settings.get("fcpxHacks.effectsShortcutTwo")
		local effectsShortcutThree 	= settings.get("fcpxHacks.effectsShortcutThree")
		local effectsShortcutFour 	= settings.get("fcpxHacks.effectsShortcutFour")
		local effectsShortcutFive 	= settings.get("fcpxHacks.effectsShortcutFive")
		if effectsShortcutOne == nil then 		effectsShortcutOne = " (Unassigned)" 		else effectsShortcutOne = " (" .. tools.stringMaxLength(effectsShortcutOne,maxTextLength,"...") .. ")" end
		if effectsShortcutTwo == nil then 		effectsShortcutTwo = " (Unassigned)" 		else effectsShortcutTwo = " (" .. tools.stringMaxLength(effectsShortcutTwo,maxTextLength,"...") .. ")" end
		if effectsShortcutThree == nil then 	effectsShortcutThree = " (Unassigned)" 		else effectsShortcutThree = " (" .. tools.stringMaxLength(effectsShortcutThree,maxTextLength,"...") .. ")" end
		if effectsShortcutFour == nil then 		effectsShortcutFour = " (Unassigned)" 		else effectsShortcutFour = " (" .. tools.stringMaxLength(effectsShortcutFour,maxTextLength,"...") .. ")" end
		if effectsShortcutFive == nil then 		effectsShortcutFive = " (Unassigned)" 		else effectsShortcutFive = " (" .. tools.stringMaxLength(effectsShortcutFive,maxTextLength,"...") .. ")" end

		--------------------------------------------------------------------------------
		-- Transition Shortcuts:
		--------------------------------------------------------------------------------
		local transitionsListUpdated 	= settings.get("fcpxHacks.transitionsListUpdated") or false
		local transitionsShortcutOne 	= settings.get("fcpxHacks.transitionsShortcutOne")
		local transitionsShortcutTwo 	= settings.get("fcpxHacks.transitionsShortcutTwo")
		local transitionsShortcutThree 	= settings.get("fcpxHacks.transitionsShortcutThree")
		local transitionsShortcutFour 	= settings.get("fcpxHacks.transitionsShortcutFour")
		local transitionsShortcutFive 	= settings.get("fcpxHacks.transitionsShortcutFive")
		if transitionsShortcutOne == nil then 		transitionsShortcutOne = " (Unassigned)" 		else transitionsShortcutOne 	= " (" .. tools.stringMaxLength(transitionsShortcutOne,maxTextLength,"...") .. ")" 	end
		if transitionsShortcutTwo == nil then 		transitionsShortcutTwo = " (Unassigned)" 		else transitionsShortcutTwo 	= " (" .. tools.stringMaxLength(transitionsShortcutTwo,maxTextLength,"...") .. ")" 	end
		if transitionsShortcutThree == nil then 	transitionsShortcutThree = " (Unassigned)" 		else transitionsShortcutThree 	= " (" .. tools.stringMaxLength(transitionsShortcutThree,maxTextLength,"...") .. ")"	end
		if transitionsShortcutFour == nil then 		transitionsShortcutFour = " (Unassigned)" 		else transitionsShortcutFour 	= " (" .. tools.stringMaxLength(transitionsShortcutFour,maxTextLength,"...") .. ")" 	end
		if transitionsShortcutFive == nil then 		transitionsShortcutFive = " (Unassigned)" 		else transitionsShortcutFive 	= " (" .. tools.stringMaxLength(transitionsShortcutFive,maxTextLength,"...") .. ")" 	end

		--------------------------------------------------------------------------------
		-- Titles Shortcuts:
		--------------------------------------------------------------------------------
		local titlesListUpdated 	= settings.get("fcpxHacks.titlesListUpdated") or false
		local titlesShortcutOne 	= settings.get("fcpxHacks.titlesShortcutOne")
		local titlesShortcutTwo 	= settings.get("fcpxHacks.titlesShortcutTwo")
		local titlesShortcutThree 	= settings.get("fcpxHacks.titlesShortcutThree")
		local titlesShortcutFour 	= settings.get("fcpxHacks.titlesShortcutFour")
		local titlesShortcutFive 	= settings.get("fcpxHacks.titlesShortcutFive")
		if titlesShortcutOne == nil then 		titlesShortcutOne = " (Unassigned)" 		else titlesShortcutOne 	= " (" .. tools.stringMaxLength(titlesShortcutOne,maxTextLength,"...") .. ")" 	end
		if titlesShortcutTwo == nil then 		titlesShortcutTwo = " (Unassigned)" 		else titlesShortcutTwo 	= " (" .. tools.stringMaxLength(titlesShortcutTwo,maxTextLength,"...") .. ")" 	end
		if titlesShortcutThree == nil then 		titlesShortcutThree = " (Unassigned)" 		else titlesShortcutThree 	= " (" .. tools.stringMaxLength(titlesShortcutThree,maxTextLength,"...") .. ")"	end
		if titlesShortcutFour == nil then 		titlesShortcutFour = " (Unassigned)" 		else titlesShortcutFour 	= " (" .. tools.stringMaxLength(titlesShortcutFour,maxTextLength,"...") .. ")" 	end
		if titlesShortcutFive == nil then 		titlesShortcutFive = " (Unassigned)" 		else titlesShortcutFive 	= " (" .. tools.stringMaxLength(titlesShortcutFive,maxTextLength,"...") .. ")" 	end

		--------------------------------------------------------------------------------
		-- Generators Shortcuts:
		--------------------------------------------------------------------------------
		local generatorsListUpdated 	= settings.get("fcpxHacks.generatorsListUpdated") or false
		local generatorsShortcutOne 	= settings.get("fcpxHacks.generatorsShortcutOne")
		local generatorsShortcutTwo 	= settings.get("fcpxHacks.generatorsShortcutTwo")
		local generatorsShortcutThree 	= settings.get("fcpxHacks.generatorsShortcutThree")
		local generatorsShortcutFour 	= settings.get("fcpxHacks.generatorsShortcutFour")
		local generatorsShortcutFive 	= settings.get("fcpxHacks.generatorsShortcutFive")
		if generatorsShortcutOne == nil then 		generatorsShortcutOne = " (Unassigned)" 		else generatorsShortcutOne 	= " (" .. tools.stringMaxLength(generatorsShortcutOne,maxTextLength,"...") .. ")" 	end
		if generatorsShortcutTwo == nil then 		generatorsShortcutTwo = " (Unassigned)" 		else generatorsShortcutTwo 	= " (" .. tools.stringMaxLength(generatorsShortcutTwo,maxTextLength,"...") .. ")" 	end
		if generatorsShortcutThree == nil then 		generatorsShortcutThree = " (Unassigned)" 		else generatorsShortcutThree 	= " (" .. tools.stringMaxLength(generatorsShortcutThree,maxTextLength,"...") .. ")"	end
		if generatorsShortcutFour == nil then 		generatorsShortcutFour = " (Unassigned)" 		else generatorsShortcutFour 	= " (" .. tools.stringMaxLength(generatorsShortcutFour,maxTextLength,"...") .. ")" 	end
		if generatorsShortcutFive == nil then 		generatorsShortcutFive = " (Unassigned)" 		else generatorsShortcutFive 	= " (" .. tools.stringMaxLength(generatorsShortcutFive,maxTextLength,"...") .. ")" 	end

		--------------------------------------------------------------------------------
		-- Get Menubar Settings:
		--------------------------------------------------------------------------------
		local menubarShortcutsEnabled = 	settings.get("fcpxHacks.menubarShortcutsEnabled")
		local menubarAutomationEnabled = 	settings.get("fcpxHacks.menubarAutomationEnabled")
		local menubarToolsEnabled = 		settings.get("fcpxHacks.menubarToolsEnabled")
		local menubarHacksEnabled = 		settings.get("fcpxHacks.menubarHacksEnabled")

		--------------------------------------------------------------------------------
		-- Are Hacks Shortcuts Enabled or Not:
		--------------------------------------------------------------------------------
		local displayShortcutText = i18n("displayKeyboardShortcuts")
		if enableHacksShortcutsInFinalCutPro then displayShortcutText = i18n("openCommandEditor") end

		--------------------------------------------------------------------------------
		-- FCPX Hacks Languages:
		--------------------------------------------------------------------------------
		local settingsLanguage = {}

		local userLocale = nil
		if settings.get("fcpxHacks.language") == nil then
			userLocale = tools.userLocale()
		else
			userLocale = settings.get("fcpxHacks.language")
		end

		local basicUserLocale = nil
		if string.find(userLocale, "_") ~= nil then
			basicUserLocale = string.sub(userLocale, 1, string.find(userLocale, "_") - 1)
		else
			basicUserLocale = userLocale
		end

		for i=1, #mod.installedLanguages do
			settingsLanguage[#settingsLanguage + 1] = { title = mod.installedLanguages[i]["language"], fn = function()
				settings.set("fcpxHacks.language", mod.installedLanguages[i]["id"])
				i18n.setLocale(mod.installedLanguages[i]["id"])
				refreshMenuBar()
			end, checked = (userLocale == mod.installedLanguages[i]["id"] or basicUserLocale == mod.installedLanguages[i]["id"]), }
		end

		--------------------------------------------------------------------------------
		-- Setup Menu:
		--------------------------------------------------------------------------------
		local settingsShapeMenuTable = {
			{ title = i18n("rectangle"), 																fn = function() changeHighlightShape("Rectangle") end,				checked = displayHighlightShapeRectangle	},
			{ title = i18n("circle"), 																	fn = function() changeHighlightShape("Circle") end, 				checked = displayHighlightShapeCircle		},
			{ title = i18n("diamond"),																	fn = function() changeHighlightShape("Diamond") end, 				checked = displayHighlightShapeDiamond		},
		}
		local settingsColourMenuTable = {
			{ title = i18n("red"), 																		fn = function() changeHighlightColour("Red") end, 					checked = displayHighlightColour == "Red" },
			{ title = i18n("blue"), 																	fn = function() changeHighlightColour("Blue") end, 					checked = displayHighlightColour == "Blue" },
			{ title = i18n("green"), 																	fn = function() changeHighlightColour("Green") end, 				checked = displayHighlightColour == "Green"	},
			{ title = i18n("yellow"), 																	fn = function() changeHighlightColour("Yellow") end, 				checked = displayHighlightColour == "Yellow" },
			{ title = "-" },
			{ title = i18n("custom"), 																	fn = function() changeHighlightColour("Custom") end, 				checked = displayHighlightColour == "Custom" },
		}
		local settingsHammerspoonSettings = {
			{ title = i18n("console") .. "...", 														fn = openHammerspoonConsole },
			{ title = "-" },
			{ title = i18n("showDockIcon"),																fn = toggleHammerspoonDockIcon, 									checked = hammerspoonDockIcon		},
			{ title = i18n("showMenuIcon"), 															fn = toggleHammerspoonMenuIcon, 									checked = hammerspoonMenuIcon		},
			{ title = "-" },
			{ title = i18n("launchAtStartup"), 															fn = toggleLaunchHammerspoonOnStartup, 								checked = startHammerspoonOnLaunch		},
			{ title = i18n("checkForUpdates"), 															fn = toggleCheckforHammerspoonUpdates, 								checked = hammerspoonCheckForUpdates	},
		}
		local settingsTouchBarLocation = {
			{ title = i18n("mouseLocation"), 															fn = function() changeTouchBarLocation("Mouse") end,				checked = displayTouchBarLocationMouse, disabled = not touchBarSupported },
			{ title = i18n("topCentreOfTimeline"), 														fn = function() changeTouchBarLocation("TimelineTopCentre") end,	checked = displayTouchBarLocationTimelineTopCentre, disabled = not touchBarSupported },
			{ title = "-" },
			{ title = i18n("touchBarTipOne"), 															disabled = true },
			{ title = i18n("touchBarTipTwo"), 															disabled = true },
		}
		local settingsMenubar = {
			{ title = i18n("showShortcuts"), 															fn = function() toggleMenubarDisplay("Shortcuts") end, 				checked = menubarShortcutsEnabled},
			{ title = i18n("showAutomation"), 															fn = function() toggleMenubarDisplay("Automation") end, 			checked = menubarAutomationEnabled},
			{ title = i18n("showTools"), 																fn = function() toggleMenubarDisplay("Tools") end, 					checked = menubarToolsEnabled},
			{ title = i18n("showHacks"), 																fn = function() toggleMenubarDisplay("Hacks") end, 					checked = menubarHacksEnabled},
			{ title = "-" },
			{ title = i18n("displayProxyOriginalIcon"), 												fn = toggleEnableProxyMenuIcon, 									checked = enableProxyMenuIcon},
			{ title = i18n("displayThisMenuAsIcon"), 													fn = toggleMenubarDisplayMode, 										checked = displayMenubarAsIcon},
		}
		local settingsHUD = {
			{ title = i18n("showInspector"), 															fn = function() toggleHUDOption("hudShowInspector") end, 			checked = hudShowInspector},
			{ title = i18n("showDropTargets"), 															fn = function() toggleHUDOption("hudShowDropTargets") end, 			checked = hudShowDropTargets},
			{ title = i18n("showButtons"), 																fn = function() toggleHUDOption("hudShowButtons") end, 				checked = hudShowButtons},
		}
		local menuLanguage = {
			{ title = i18n("german"), 																	fn = function() changeFinalCutProLanguage("de") end, 				checked = currentLanguage == "de"},
			{ title = i18n("english"), 																	fn = function() changeFinalCutProLanguage("en") end, 				checked = currentLanguage == "en"},
			{ title = i18n("spanish"), 																	fn = function() changeFinalCutProLanguage("es") end, 				checked = currentLanguage == "es"},
			{ title = i18n("french"), 																	fn = function() changeFinalCutProLanguage("fr") end, 				checked = currentLanguage == "fr"},
			{ title = i18n("japanese"), 																fn = function() changeFinalCutProLanguage("ja") end, 				checked = currentLanguage == "ja"},
			{ title = i18n("chineseChina"), 															fn = function() changeFinalCutProLanguage("zh_CN") end, 			checked = currentLanguage == "zh_CN"},
		}
		local settingsBatchExportOptions = {
			{ title = i18n("setDestinationPreset"), 													fn = changeBatchExportDestinationPreset, 							disabled = not fcpxRunning },
			{ title = i18n("setDestinationFolder"), 													fn = changeBatchExportDestinationFolder },
			{ title = "-" },
			{ title = i18n("replaceExistingFiles"), 													fn = toggleBatchExportReplaceExistingFiles, 						checked = settings.get("fcpxHacks.batchExportReplaceExistingFiles") },
		}
		local settingsMenuTable = {
			{ title = i18n("finalCutProLanguage"), 														menu = menuLanguage },
			{ title = "FCPX Hacks " .. i18n("language"), 												menu = settingsLanguage},
			{ title = "-" },
			{ title = i18n("batchExportOptions"), 														menu = settingsBatchExportOptions},
			{ title = "-" },
			{ title = i18n("menubarOptions"), 															menu = settingsMenubar},
			{ title = i18n("hudOptions"), 																menu = settingsHUD},
			{ title = "Hammerspoon " .. i18n("options"),												menu = settingsHammerspoonSettings},
			{ title = "-" },
			{ title = i18n("touchBarLocation"), 														menu = settingsTouchBarLocation},
			{ title = "-" },
			{ title = i18n("highlightPlayheadColour"), 													menu = settingsColourMenuTable},
			{ title = i18n("highlightPlayheadShape"), 													menu = settingsShapeMenuTable},
			{ title = "-" },
			{ title = i18n("checkForUpdates"), 															fn = toggleCheckForUpdates, 										checked = enableCheckForUpdates},
			{ title = i18n("enableDebugMode"), 															fn = toggleDebugMode, 												checked = mod.debugMode},
			{ title = "-" },
			{ title = i18n("trachFCPXHacksPreferences"), 												fn = resetSettings },
			{ title = "-" },
			{ title = i18n("provideFeedback"),															fn = emailBugReport },
			{ title = "-" },
			{ title = i18n("createdBy") .. " LateNite Films", 											fn = gotoLateNiteSite },
			{ title = i18n("scriptVersion") .. " " .. fcpxhacks.scriptVersion,							disabled = true },
		}
		local settingsEffectsShortcutsTable = {
			{ title = i18n("updateEffectsList"),														fn = updateEffectsList, 																										disabled = not fcpxRunning },
			{ title = "-" },
			{ title = i18n("effectShortcut") .. " " .. i18n("one") .. effectsShortcutOne, 				fn = function() assignEffectsShortcut(1) end, 																					disabled = not effectsListUpdated },
			{ title = i18n("effectShortcut") .. " " .. i18n("two") .. effectsShortcutTwo, 				fn = function() assignEffectsShortcut(2) end, 																					disabled = not effectsListUpdated },
			{ title = i18n("effectShortcut") .. " " .. i18n("three") .. effectsShortcutThree, 			fn = function() assignEffectsShortcut(3) end, 																					disabled = not effectsListUpdated },
			{ title = i18n("effectShortcut") .. " " .. i18n("four") .. effectsShortcutFour, 			fn = function() assignEffectsShortcut(4) end, 																					disabled = not effectsListUpdated },
			{ title = i18n("effectShortcut") .. " " .. i18n("five") .. effectsShortcutFive, 			fn = function() assignEffectsShortcut(5) end, 																					disabled = not effectsListUpdated },
		}
		local settingsTransitionsShortcutsTable = {
			{ title = i18n("updateTransitionsList"), 													fn = updateTransitionsList, 																									disabled = not fcpxRunning },
			{ title = "-" },
			{ title = i18n("transitionShortcut") .. " " .. i18n("one") .. transitionsShortcutOne, 		fn = function() assignTransitionsShortcut(1) end,																				disabled = not transitionsListUpdated },
			{ title = i18n("transitionShortcut") .. " " .. i18n("two") .. transitionsShortcutTwo, 		fn = function() assignTransitionsShortcut(2) end, 																				disabled = not transitionsListUpdated },
			{ title = i18n("transitionShortcut") .. " " .. i18n("three") .. transitionsShortcutThree, 	fn = function() assignTransitionsShortcut(3) end, 																				disabled = not transitionsListUpdated },
			{ title = i18n("transitionShortcut") .. " " .. i18n("four") ..transitionsShortcutFour, 		fn = function() assignTransitionsShortcut(4) end, 																				disabled = not transitionsListUpdated },
			{ title = i18n("transitionShortcut") .. " " .. i18n("five") .. transitionsShortcutFive, 	fn = function() assignTransitionsShortcut(5) end, 																				disabled = not transitionsListUpdated },
		}
		local settingsTitlesShortcutsTable = {
			{ title = i18n("updateTitlesList"), 														fn = updateTitlesList, 																											disabled = not fcpxRunning },
			{ title = "-" },
			{ title = i18n("titleShortcut") .. " " .. i18n("one") .. titlesShortcutOne, 				fn = function() assignTitlesShortcut(1) end,																					disabled = not titlesListUpdated },
			{ title = i18n("titleShortcut") .. " " .. i18n("two") .. titlesShortcutTwo, 				fn = function() assignTitlesShortcut(2) end, 																					disabled = not titlesListUpdated },
			{ title = i18n("titleShortcut") .. " " .. i18n("three") .. titlesShortcutThree, 			fn = function() assignTitlesShortcut(3) end, 																					disabled = not titlesListUpdated },
			{ title = i18n("titleShortcut") .. " " .. i18n("four") .. titlesShortcutFour, 				fn = function() assignTitlesShortcut(4) end, 																					disabled = not titlesListUpdated },
			{ title = i18n("titleShortcut") .. " " .. i18n("five") .. titlesShortcutFive, 				fn = function() assignTitlesShortcut(5) end, 																					disabled = not titlesListUpdated },
		}
		local settingsGeneratorsShortcutsTable = {
			{ title = i18n("updateGeneratorsList"), 													fn = updateGeneratorsList, 																										disabled = not fcpxRunning },
			{ title = "-" },
			{ title = i18n("generatorShortcut") .. " " .. i18n("one") .. generatorsShortcutOne, 		fn = function() assignGeneratorsShortcut(1) end,																				disabled = not generatorsListUpdated },
			{ title = i18n("generatorShortcut") .. " " .. i18n("two") .. generatorsShortcutTwo, 		fn = function() assignGeneratorsShortcut(2) end, 																				disabled = not generatorsListUpdated },
			{ title = i18n("generatorShortcut") .. " " .. i18n("three") .. generatorsShortcutThree, 	fn = function() assignGeneratorsShortcut(3) end, 																				disabled = not generatorsListUpdated },
			{ title = i18n("generatorShortcut") .. " " .. i18n("four") .. generatorsShortcutFour, 		fn = function() assignGeneratorsShortcut(4) end, 																				disabled = not generatorsListUpdated },
			{ title = i18n("generatorShortcut") .. " " .. i18n("five") .. generatorsShortcutFive, 		fn = function() assignGeneratorsShortcut(5) end, 																				disabled = not generatorsListUpdated },
		}
		local settingsHUDButtons = {
			{ title = i18n("button") .. " " .. i18n("one") .. hudButtonOne, 							fn = function() hackshud.assignButton(1) end },
			{ title = i18n("button") .. " " .. i18n("two") .. hudButtonTwo, 							fn = function() hackshud.assignButton(2) end },
			{ title = i18n("button") .. " " .. i18n("three") .. hudButtonThree, 						fn = function() hackshud.assignButton(3) end },
			{ title = i18n("button") .. " " .. i18n("four") .. hudButtonFour, 							fn = function() hackshud.assignButton(4) end },
		}
		local menuTable = {
			{ title = i18n("open") .. " Final Cut Pro", 												fn = fcp.launch },
			{ title = displayShortcutText, 																fn = displayShortcutList, disabled = not fcpxRunning },
			{ title = "-" },
		}
		local shortcutsTable = {
			{ title = string.upper(i18n("shortcuts")) .. ":", 											disabled = true },
			{ title = i18n("createOptimizedMedia"), 													fn = function() toggleCreateOptimizedMedia() end, 					checked = fcp.getPreference("FFImportCreateOptimizeMedia", false),				disabled = not fcpxRunning },
			{ title = i18n("createMulticamOptimizedMedia"),												fn = function() toggleCreateMulticamOptimizedMedia() end, 			checked = fcp.getPreference("FFCreateOptimizedMediaForMulticamClips", true), 	disabled = not fcpxRunning },
			{ title = i18n("createProxyMedia"), 														fn = function() toggleCreateProxyMedia() end, 						checked = fcp.getPreference("FFImportCreateProxyMedia", false),					disabled = not fcpxRunning },
			{ title = i18n("leaveFilesInPlaceOnImport"), 												fn = function() toggleLeaveInPlace() end, 							checked = not fcp.getPreference("FFImportCopyToMediaFolder", true),				disabled = not fcpxRunning },
			{ title = i18n("enableBackgroundRender").." ("..mod.FFAutoRenderDelay.." "..i18n("secs")..")", fn = function() toggleBackgroundRender() end, 						checked = fcp.getPreference("FFAutoStartBGRender", true),						disabled = not fcpxRunning },
			{ title = "-" },
		}
		local automationOptions = {
			{ title = i18n("enableScrollingTimeline"), 													fn = toggleScrollingTimeline, 										checked = scrollingTimelineActive },
			{ title = i18n("enableTimelinePlayheadLock"),												fn = toggleLockPlayhead, 											checked = lockTimelinePlayhead},
			{ title = i18n("enableShortcutsDuringFullscreen"), 											fn = toggleEnableShortcutsDuringFullscreenPlayback, 				checked = enableShortcutsDuringFullscreenPlayback },
			{ title = "-" },
			{ title = i18n("closeMediaImport"), 														fn = toggleMediaImportWatcher, 										checked = enableMediaImportWatcher },
		}
		local automationTable = {
			{ title = string.upper(i18n("automation")) .. ":", 											disabled = true },
			{ title = i18n("assignEffectsShortcuts"), 													menu = settingsEffectsShortcutsTable },
			{ title = i18n("assignTransitionsShortcuts"), 												menu = settingsTransitionsShortcutsTable },
			{ title = i18n("assignTitlesShortcuts"),													menu = settingsTitlesShortcutsTable },
			{ title = i18n("assignGeneratorsShortcuts"), 												menu = settingsGeneratorsShortcutsTable },
			{ title = i18n("options"),																	menu = automationOptions },
			{ title = "-" },
		}
		local toolsSettings = {
			{ title = i18n("enableTouchBar"), 															fn = toggleTouchBar, 												checked = displayTouchBar, 									disabled = not touchBarSupported},
			{ title = i18n("enableHacksHUD"), 															fn = toggleEnableHacksHUD, 											checked = enableHacksHUD},
			{ title = i18n("enableMobileNotifications"),												fn = toggleEnableMobileNotifications, 								checked = enableMobileNotifications},
			{ title = i18n("enableClipboardHistory"),													fn = toggleEnableClipboardHistory, 									checked = enableClipboardHistory},
			{ title = i18n("enableSharedClipboard"), 													fn = toggleEnableSharedClipboard, 									checked = enableSharedClipboard,							disabled = not enableClipboardHistory},
			{ title = i18n("enableXMLSharing"),															fn = toggleEnableXMLSharing, 										checked = enableXMLSharing},
			{ title = i18n("enableVoiceCommands"),														fn = toggleEnableVoiceCommands, 									checked = settings.get("fcpxHacks.enableVoiceCommands") },

		}
		local toolsTable = {
			{ title = string.upper(i18n("tools")) .. ":", 												disabled = true },
			{ title = i18n("importSharedXMLFile"),														menu = settingsSharedXMLTable },
			{ title = i18n("pasteFromClipboardHistory"),												menu = settingsClipboardHistoryTable },
			{ title = i18n("pasteFromSharedClipboard"), 												menu = settingsSharedClipboardTable },
			{ title = i18n("assignHUDButtons"), 														menu = settingsHUDButtons },
			{ title = i18n("options"),																	menu = toolsSettings },
			{ title = "-" },
		}
		local advancedTable = {
			{ title = i18n("enableHacksShortcuts"), 													fn = toggleEnableHacksShortcutsInFinalCutPro, 						checked = enableHacksShortcutsInFinalCutPro},
			{ title = i18n("enableTimecodeOverlay"), 													fn = toggleTimecodeOverlay, 										checked = mod.FFEnableGuards },
			{ title = i18n("enableMovingMarkers"), 														fn = toggleMovingMarkers, 											checked = mod.allowMovingMarkers },
			{ title = i18n("enableRenderingDuringPlayback"),											fn = togglePerformTasksDuringPlayback, 								checked = not mod.FFSuspendBGOpsDuringPlay },
			{ title = "-" },
			{ title = i18n("changeBackupInterval") .. " (" .. tostring(mod.FFPeriodicBackupInterval) .. " " .. i18n("mins") .. ")", fn = changeBackupInterval },
			{ title = i18n("changeSmartCollectionLabel"),												fn = changeSmartCollectionsLabel },
		}
		local hacksTable = {
			{ title = string.upper(i18n("hacks")) .. ":", 												disabled = true },
			{ title = i18n("advancedFeatures"),															menu = advancedTable },
			{ title = "-" },
		}
		local settingsTable = {
			{ title = i18n("preferences") .. "...", 													menu = settingsMenuTable },
			{ title = "-" },
			{ title = i18n("quit") .. " FCPX Hacks", 													fn = quitFCPXHacks},
		}

		--------------------------------------------------------------------------------
		-- Setup Menubar:
		--------------------------------------------------------------------------------
		if menubarShortcutsEnabled then 	menuTable = fnutils.concat(menuTable, shortcutsTable) 	end
		if menubarAutomationEnabled then	menuTable = fnutils.concat(menuTable, automationTable)	end
		if menubarToolsEnabled then 		menuTable = fnutils.concat(menuTable, toolsTable)		end
		if menubarHacksEnabled then 		menuTable = fnutils.concat(menuTable, hacksTable)		end

		menuTable = fnutils.concat(menuTable, settingsTable)

		--------------------------------------------------------------------------------
		-- Check for Updates:
		--------------------------------------------------------------------------------
		if latestScriptVersion ~= nil then
			if latestScriptVersion > fcpxhacks.scriptVersion then
				table.insert(menuTable, 1, { title = i18n("updateAvailable") .. " (" .. i18n("version") .. " " .. latestScriptVersion .. ")", fn = getScriptUpdate})
				table.insert(menuTable, 2, { title = "-" })
			end
		end

		--------------------------------------------------------------------------------
		-- Set the Menu:
		--------------------------------------------------------------------------------
		fcpxMenubar:setMenu(menuTable)

	end

	--------------------------------------------------------------------------------
	-- UPDATE MENUBAR ICON:
	--------------------------------------------------------------------------------
	function updateMenubarIcon()

		local fcpxHacksIcon = image.imageFromPath("~/.hammerspoon/hs/fcpxhacks/assets/fcpxhacks.png")
		local fcpxHacksIconSmall = fcpxHacksIcon:setSize({w=18,h=18})
		local displayMenubarAsIcon = settings.get("fcpxHacks.displayMenubarAsIcon")
		local enableProxyMenuIcon = settings.get("fcpxHacks.enableProxyMenuIcon")
		local proxyMenuIcon = ""

		local proxyStatusIcon = nil
		local FFPlayerQuality = fcp.getPreference("FFPlayerQuality")
		if FFPlayerQuality == 4 then
			proxyStatusIcon = "🔴" 		-- Proxy (4)
		else
			proxyStatusIcon = "🔵" 		-- Original (5)
		end

		fcpxMenubar:setIcon(nil)

		if enableProxyMenuIcon ~= nil then
			if enableProxyMenuIcon == true then
				if proxyStatusIcon ~= nil then
					proxyMenuIcon = " " .. proxyStatusIcon
				else
					proxyMenuIcon = ""
				end
			end
		end

		if displayMenubarAsIcon == nil then
			fcpxMenubar:setTitle("FCPX Hacks" .. proxyMenuIcon)
		else
			if displayMenubarAsIcon then
				fcpxMenubar:setIcon(fcpxHacksIconSmall)
				if proxyStatusIcon ~= nil then
					if proxyStatusIcon ~= "" then
						if enableProxyMenuIcon then
							proxyMenuIcon = proxyMenuIcon .. "  "
						end
					end
				 end
				fcpxMenubar:setTitle(proxyMenuIcon)
			else
				fcpxMenubar:setTitle("FCPX Hacks" .. proxyMenuIcon)
			end
		end

	end

--------------------------------------------------------------------------------
-- HELP:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- DISPLAY A LIST OF ALL SHORTCUTS:
	--------------------------------------------------------------------------------
	function displayShortcutList()

		local enableHacksShortcutsInFinalCutPro = settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro")
		if enableHacksShortcutsInFinalCutPro == nil then enableHacksShortcutsInFinalCutPro = false end

		if enableHacksShortcutsInFinalCutPro then
			if fcp.running() then
				fcp.launch()
				fcp:app():commandEditor():show()
			end
		else
			local whatMessage = [[The default FCPX Hacks Shortcut Keys are:

	---------------------------------
	CONTROL+OPTION+COMMAND:
	---------------------------------
	L = Launch Final Cut Pro (System Wide)

	A = Toggle HUD
	Z = Toggle Touch Bar

	W = Toggle Scrolling Timeline

	H = Highlight Browser Playhead
	F = Reveal in Browser & Highlight
	S = Single Match Frame & Highlight

	D = Reveal Multicam in Browser & Highlight
	G = Reveal Multicam in Angle Editor & Highlight

	E = Batch Export from Browser

	B = Change Backup Interval

	T = Toggle Timecode Overlays
	Y = Toggle Moving Markers
	P = Toggle Rendering During Playback

	M = Select Color Board Puck 1
	, = Select Color Board Puck 2
	. = Select Color Board Puck 3
	/ = Select Color Board Puck 4

	1-9 = Restore Keyword Preset

	+ = Increase Timeline Clip Height
	- = Decrease Timeline Clip Height

	-----------------------------------------
	CONTROL+OPTION+COMMAND+SHIFT:
	-----------------------------------------
	1-9 = Save Keyword Preset

	-----------------------------------------
	CONTROL+SHIFT:
	-----------------------------------------
	1-5 = Apply Effect]]

			dialog.displayMessage(whatMessage)
		end
	end

--------------------------------------------------------------------------------
-- UPDATE EFFECTS/TRANSITIONS/TITLES/GENERATORS LISTS:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- GET LIST OF EFFECTS:
	--------------------------------------------------------------------------------
	function updateEffectsList()

		--------------------------------------------------------------------------------
		-- Make sure Final Cut Pro is active:
		--------------------------------------------------------------------------------
		fcp.launch()

		--------------------------------------------------------------------------------
		-- Hide the Touch Bar:
		--------------------------------------------------------------------------------
		hideTouchbar()

		--------------------------------------------------------------------------------
		-- Warning message:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateEffectsListWarning"))

		--------------------------------------------------------------------------------
		-- Save the layout of the Transitions panel in case we switch away...
		--------------------------------------------------------------------------------
		local transitions = fcp.app():transitions()
		local transitionsLayout = transitions:saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure Effects panel is open:
		--------------------------------------------------------------------------------
		local effects = fcp.app():effects()
		local effectsShowing = effects:isShowing()
		if not effects:show():isShowing() then
			dialog.displayErrorMessage("Unable to activate the Effects panel.\n\nError occurred in updateEffectsList().")
			showTouchbar()
			return "Fail"
		end

		local effectsLayout = effects:saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure "Installed Effects" is selected:
		--------------------------------------------------------------------------------
		effects:group():selectItem(1)

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		effects:search():clear()

		local sidebar = effects:sidebar()

		--------------------------------------------------------------------------------
		-- Ensure the sidebar is visible
		--------------------------------------------------------------------------------
		effects:showSidebar()

		--------------------------------------------------------------------------------
		-- If it's still invisible, we have a problem.
		--------------------------------------------------------------------------------
		if not sidebar:isShowing() then
			dialog.displayErrorMessage("Unable to activate the Effects sidebar.\n\nError occurred in updateEffectsList().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Find the two 'All' rows (Video/Audio)
		--------------------------------------------------------------------------------
		local allRows = sidebar:rowsUI(function(row)
			local label = row[1][1]
			local value = label and label:attributeValue("AXValue")
			--------------------------------------------------------------------------------
			-- ENGLISH:		All
			-- GERMAN: 		Alle
			-- SPANISH: 	Todo
			-- FRENCH: 		Tous
			-- JAPANESE:	すべて
			-- CHINESE:		全部
			--------------------------------------------------------------------------------
			-- TODO: Use i18n to get the appropriate value for the current language
			return (value == "All") or (value == "Alle") or (value == "Todo") or (value == "Tous") or (value == "すべて") or (value == "全部")
		end)

		if not allRows or #allRows ~= 2 then
			dialog.displayErrorMessage("Was expecting two 'All' categories.\n\nError occurred in updateEffectsList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Click 'All Video':
		--------------------------------------------------------------------------------
		sidebar:selectRow(allRows[1])

		--------------------------------------------------------------------------------
		-- Get list of All Video Effects:
		--------------------------------------------------------------------------------
		local effectsList = effects:contents():childrenUI()
		local allVideoEffects = {}
		if effectsList ~= nil then
			for i=1, #effectsList do
				allVideoEffects[i] = effectsList[i]:attributeValue("AXTitle")
			end
		else
			dialog.displayErrorMessage("Unable to get list of all effects.\n\nError occurred in updateEffectsList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get list of All Audio Effects:
		--------------------------------------------------------------------------------
		sidebar:selectRow(allRows[2])

		effectsList = effects:contents():childrenUI()
		local allAudioEffects = {}
		if effectsList ~= nil then
			for i=1, #effectsList do
				allAudioEffects[i] = effectsList[i]:attributeValue("AXTitle")
			end
		else
			dialog.displayErrorMessage("Unable to get list of all effects.\n\nError occurred in updateEffectsList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Restore Effects and Transitions Panels:
		--------------------------------------------------------------------------------
		effects:loadLayout(effectsLayout)
		transitions:loadLayout(transitionsLayout)
		if not effectsShowing then effects:hide() end

		showTouchbar()

		--------------------------------------------------------------------------------
		-- All done!
		--------------------------------------------------------------------------------
		if #allVideoEffects == 0 or #allAudioEffects == 0 then
			dialog.displayMessage(i18n("updateEffectsListFailed") .. "\n\n" .. i18n("pleaseTryAgain"))
			return "Fail"
		else
			--------------------------------------------------------------------------------
			-- Save Results to Settings:
			--------------------------------------------------------------------------------
			settings.set("fcpxHacks.allVideoEffects", allVideoEffects)
			settings.set("fcpxHacks.allAudioEffects", allAudioEffects)
			settings.set("fcpxHacks.effectsListUpdated", true)

			--------------------------------------------------------------------------------
			-- Update Chooser:
			--------------------------------------------------------------------------------
			hacksconsole.refresh()

			--------------------------------------------------------------------------------
			-- Refresh Menubar:
			--------------------------------------------------------------------------------
			refreshMenuBar()

			--------------------------------------------------------------------------------
			-- Let the user know everything's good:
			--------------------------------------------------------------------------------
			dialog.displayMessage(i18n("updateEffectsListDone"))
		end

	end

	--------------------------------------------------------------------------------
	-- GET LIST OF TRANSITIONS:
	--------------------------------------------------------------------------------
	function updateTransitionsList()

		--------------------------------------------------------------------------------
		-- Make sure Final Cut Pro is active:
		--------------------------------------------------------------------------------
		fcp.launch()

		--------------------------------------------------------------------------------
		-- Hide the Touch Bar:
		--------------------------------------------------------------------------------
		hideTouchbar()

		--------------------------------------------------------------------------------
		-- Warning message:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateTransitionsListWarning"))

		--------------------------------------------------------------------------------
		-- Save the layout of the Effects panel, in case we switch away...
		--------------------------------------------------------------------------------
		local effects = fcp.app():effects()
		local effectsLayout = effects:saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure Transitions panel is open:
		--------------------------------------------------------------------------------
		local transitions = fcp.app():transitions()
		local transitionsShowing = transitions:isShowing()
		if not transitions:show():isShowing() then
			dialog.displayErrorMessage("Unable to activate the Transitions panel.\n\nError occurred in updateEffectsList().")
			showTouchbar()
			return "Fail"
		end

		local transitionsLayout = transitions:saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure "Installed Transitions" is selected:
		--------------------------------------------------------------------------------
		transitions:group():selectItem(1)

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		transitions:search():clear()

		--------------------------------------------------------------------------------
		-- Make sure the sidebar is visible:
		--------------------------------------------------------------------------------
		local sidebar = transitions:sidebar()

		transitions:showSidebar()

		if not sidebar:isShowing() then
			dialog.displayErrorMessage("Unable to activate the Transitions sidebar.\n\nError occurred in updateTransitionsList().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Click 'All':
		--------------------------------------------------------------------------------
		sidebar:selectRowAt(1)

		--------------------------------------------------------------------------------
		-- Get list of All Transitions:
		--------------------------------------------------------------------------------
		local effectsList = transitions:contents():childrenUI()
		local allTransitions = {}
		if effectsList ~= nil then
			for i=1, #effectsList do
				allTransitions[i] = effectsList[i]:attributeValue("AXTitle")
			end
		else
			dialog.displayErrorMessage("Unable to get list of all transitions.\n\nError occurred in updateTransitionsList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Restore Effects and Transitions Panels:
		--------------------------------------------------------------------------------
		transitions:loadLayout(transitionsLayout)
		effects:loadLayout(effectsLayout)
		if not transitionsShowing then transitions:hide() end

		showTouchbar()

		--------------------------------------------------------------------------------
		-- Save Results to Settings:
		--------------------------------------------------------------------------------
		settings.set("fcpxHacks.allTransitions", allTransitions)
		settings.set("fcpxHacks.transitionsListUpdated", true)

		--------------------------------------------------------------------------------
		-- Update Chooser:
		--------------------------------------------------------------------------------
		hacksconsole.refresh()

		--------------------------------------------------------------------------------
		-- Refresh Menubar:
		--------------------------------------------------------------------------------
		refreshMenuBar()

		--------------------------------------------------------------------------------
		-- Let the user know everything's good:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateTransitionsListDone"))

		--------------------------------------------------------------------------------
		-- Show the Touch Bar:
		--------------------------------------------------------------------------------
		showTouchbar()

	end

	--------------------------------------------------------------------------------
	-- GET LIST OF TITLES:
	--------------------------------------------------------------------------------
	function updateTitlesList()

		--------------------------------------------------------------------------------
		-- Make sure Final Cut Pro is active:
		--------------------------------------------------------------------------------
		fcp.launch()

		--------------------------------------------------------------------------------
		-- Hide the Touch Bar:
		--------------------------------------------------------------------------------
		hideTouchbar()

		--------------------------------------------------------------------------------
		-- Warning message:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateTitlesListWarning"))

		local app = fcp.app()
		local generators = app:generators()

		local browserLayout = app:browser():saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure Titles and Generators panel is open:
		--------------------------------------------------------------------------------
		if not generators:show():isShowing() then
			dialog.displayErrorMessage("Unable to activate the Titles and Generators panel.\n\nError occurred in updateEffectsList().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		generators:search():clear()

		--------------------------------------------------------------------------------
		-- Click 'Titles':
		--------------------------------------------------------------------------------
		generators:showAllTitles()

		--------------------------------------------------------------------------------
		-- Make sure "Installed Titles" is selected:
		--------------------------------------------------------------------------------
		generators:group():selectItem(1)

		--------------------------------------------------------------------------------
		-- Get list of All Transitions:
		--------------------------------------------------------------------------------
		local effectsList = generators:contents():childrenUI()
		local allTitles = {}
		if effectsList ~= nil then
			for i=1, #effectsList do
				allTitles[i] = effectsList[i]:attributeValue("AXTitle")
			end
		else
			dialog.displayErrorMessage("Unable to get list of all titles.\n\nError occurred in updateTitlesList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Restore Effects or Transitions Panel:
		--------------------------------------------------------------------------------
		app:browser():loadLayout(browserLayout)

		showTouchbar()

		--------------------------------------------------------------------------------
		-- Save Results to Settings:
		--------------------------------------------------------------------------------
		settings.set("fcpxHacks.allTitles", allTitles)
		settings.set("fcpxHacks.titlesListUpdated", true)

		--------------------------------------------------------------------------------
		-- Update Chooser:
		--------------------------------------------------------------------------------
		hacksconsole.refresh()

		--------------------------------------------------------------------------------
		-- Refresh Menubar:
		--------------------------------------------------------------------------------
		refreshMenuBar()

		--------------------------------------------------------------------------------
		-- Let the user know everything's good:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateTitlesListDone"))

	end

	--------------------------------------------------------------------------------
	-- GET LIST OF GENERATORS:
	--------------------------------------------------------------------------------
	function updateGeneratorsList()

		--------------------------------------------------------------------------------
		-- Make sure Final Cut Pro is active:
		--------------------------------------------------------------------------------
		fcp.launch()

		--------------------------------------------------------------------------------
		-- Hide the Touch Bar:
		--------------------------------------------------------------------------------
		hideTouchbar()

		--------------------------------------------------------------------------------
		-- Warning message:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateGeneratorsListWarning"))

		local app = fcp.app()
		local generators = app:generators()

		local browserLayout = app:browser():saveLayout()

		--------------------------------------------------------------------------------
		-- Make sure Titles and Generators panel is open:
		--------------------------------------------------------------------------------
		if not generators:show():isShowing() then
			dialog.displayErrorMessage("Unable to activate the Titles and Generators panel.\n\nError occurred in updateEffectsList().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		generators:search():clear()

		--------------------------------------------------------------------------------
		-- Click 'Generators':
		--------------------------------------------------------------------------------
		generators:showAllGenerators()

		--------------------------------------------------------------------------------
		-- Make sure "Installed Titles" is selected:
		--------------------------------------------------------------------------------
		generators:group():selectItem(1)

		--------------------------------------------------------------------------------
		-- Get list of All Transitions:
		--------------------------------------------------------------------------------
		local effectsList = generators:contents():childrenUI()
		local allGenerators = {}
		if effectsList ~= nil then
			for i=1, #effectsList do
				allGenerators[i] = effectsList[i]:attributeValue("AXTitle")
			end
		else
			dialog.displayErrorMessage("Unable to get list of all Generators.\n\nError occurred in updateGeneratorsList().")
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Restore Effects or Transitions Panel:
		--------------------------------------------------------------------------------
		app:browser():loadLayout(browserLayout)

		--------------------------------------------------------------------------------
		-- Save Results to Settings:
		--------------------------------------------------------------------------------
		settings.set("fcpxHacks.allGenerators", allGenerators)
		settings.set("fcpxHacks.generatorsListUpdated", true)

		--------------------------------------------------------------------------------
		-- Update Chooser:
		--------------------------------------------------------------------------------
		hacksconsole.refresh()

		--------------------------------------------------------------------------------
		-- Refresh Menubar:
		--------------------------------------------------------------------------------
		refreshMenuBar()

		--------------------------------------------------------------------------------
		-- Let the user know everything's good:
		--------------------------------------------------------------------------------
		dialog.displayMessage(i18n("updateGeneratorsListDone"))

	end

--------------------------------------------------------------------------------
-- ASSIGN EFFECTS/TRANSITIONS/TITLES/GENERATORS SHORTCUTS:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- ASSIGN EFFECTS SHORTCUT:
	--------------------------------------------------------------------------------
	function assignEffectsShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Was Final Cut Pro Open?
		--------------------------------------------------------------------------------
		mod.wasFinalCutProOpen = fcp.frontmost()

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local effectsListUpdated 	= settings.get("fcpxHacks.effectsListUpdated")
		local allVideoEffects 		= settings.get("fcpxHacks.allVideoEffects")
		local allAudioEffects 		= settings.get("fcpxHacks.allAudioEffects")

		--------------------------------------------------------------------------------
		-- Error Checking:
		--------------------------------------------------------------------------------
		if not effectsListUpdated then
			dialog.displayMessage(i18n("assignEffectsShortcutError"))
			return "Failed"
		end
		if allVideoEffects == nil or allAudioEffects == nil then
			dialog.displayMessage(i18n("assignEffectsShortcutError"))
			return "Failed"
		end
		if next(allVideoEffects) == nil or next(allAudioEffects) == nil then
			dialog.displayMessage(i18n("assignEffectsShortcutError"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Video Effects List:
		--------------------------------------------------------------------------------
		local effectChooserChoices = {}
		if allVideoEffects ~= nil and next(allVideoEffects) ~= nil then
			for i=1, #allVideoEffects do
				individualEffect = {
					["text"] = allVideoEffects[i],
					["subText"] = "Video Effect",
					["function"] = "effectsShortcut",
					["function1"] = allVideoEffects[i],
					["function2"] = "",
					["function3"] = "",
					["whichShortcut"] = whichShortcut,
				}
				table.insert(effectChooserChoices, 1, individualEffect)
			end
		end

		--------------------------------------------------------------------------------
		-- Audio Effects List:
		--------------------------------------------------------------------------------
		if allAudioEffects ~= nil and next(allAudioEffects) ~= nil then
			for i=1, #allAudioEffects do
				individualEffect = {
					["text"] = allAudioEffects[i],
					["subText"] = "Audio Effect",
					["function"] = "effectsShortcut",
					["function1"] = allAudioEffects[i],
					["function2"] = "",
					["function3"] = "",
					["whichShortcut"] = whichShortcut,
				}
				table.insert(effectChooserChoices, 1, individualEffect)
			end
		end

		--------------------------------------------------------------------------------
		-- Sort everything:
		--------------------------------------------------------------------------------
		table.sort(effectChooserChoices, function(a, b) return a.text < b.text end)

		--------------------------------------------------------------------------------
		-- Setup Chooser:
		--------------------------------------------------------------------------------
		effectChooser = chooser.new(effectChooserAction):bgDark(true)
														:choices(effectChooserChoices)

		--------------------------------------------------------------------------------
		-- Allow for Reduce Transparency:
		--------------------------------------------------------------------------------
		if screen.accessibilitySettings()["ReduceTransparency"] then
			effectChooser:fgColor(nil)
						 :subTextColor(nil)
		else
			effectChooser:fgColor(drawing.color.x11.snow)
		 				 :subTextColor(drawing.color.x11.snow)
		end

		--------------------------------------------------------------------------------
		-- Show Chooser:
		--------------------------------------------------------------------------------
		effectChooser:show()

	end

		--------------------------------------------------------------------------------
		-- ASSIGN EFFECTS SHORTCUT CHOOSER ACTION:
		--------------------------------------------------------------------------------
		function effectChooserAction(result)

			--------------------------------------------------------------------------------
			-- Hide Chooser:
			--------------------------------------------------------------------------------
			effectChooser:hide()

			--------------------------------------------------------------------------------
			-- Perform Specific Function:
			--------------------------------------------------------------------------------
			if result ~= nil then
				--------------------------------------------------------------------------------
				-- Save the selection:
				--------------------------------------------------------------------------------
				whichShortcut = result["whichShortcut"]
				if whichShortcut == 1 then settings.set("fcpxHacks.effectsShortcutOne", 		result["text"]) end
				if whichShortcut == 2 then settings.set("fcpxHacks.effectsShortcutTwo", 		result["text"]) end
				if whichShortcut == 3 then settings.set("fcpxHacks.effectsShortcutThree", 	result["text"]) end
				if whichShortcut == 4 then settings.set("fcpxHacks.effectsShortcutFour", 	result["text"]) end
				if whichShortcut == 5 then settings.set("fcpxHacks.effectsShortcutFive", 	result["text"]) end
			end

			--------------------------------------------------------------------------------
			-- Put focus back in Final Cut Pro:
			--------------------------------------------------------------------------------
			if mod.wasFinalCutProOpen then fcp.launch() end

			--------------------------------------------------------------------------------
			-- Refresh Menubar:
			--------------------------------------------------------------------------------
			refreshMenuBar()

		end

	--------------------------------------------------------------------------------
	-- ASSIGN TRANSITIONS SHORTCUT:
	--------------------------------------------------------------------------------
	function assignTransitionsShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Was Final Cut Pro Open?
		--------------------------------------------------------------------------------
		mod.wasFinalCutProOpen = fcp.frontmost()

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local transitionsListUpdated = settings.get("fcpxHacks.transitionsListUpdated")
		local allTransitions = settings.get("fcpxHacks.allTransitions")

		--------------------------------------------------------------------------------
		-- Error Checking:
		--------------------------------------------------------------------------------
		if not transitionsListUpdated then
			dialog.displayMessage(i18n("assignTransitionsShortcutError"))
			return "Failed"
		end
		if allTransitions == nil then
			dialog.displayMessage(i18n("assignTransitionsShortcutError"))
			return "Failed"
		end
		if next(allTransitions) == nil then
			dialog.displayMessage(i18n("assignTransitionsShortcutError"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Video Effects List:
		--------------------------------------------------------------------------------
		local transitionChooserChoices = {}
		if allTransitions ~= nil and next(allTransitions) ~= nil then
			for i=1, #allTransitions do
				individualEffect = {
					["text"] = allTransitions[i],
					["subText"] = "Transition",
					["function"] = "transitionsShortcut",
					["function1"] = allTransitions[i],
					["function2"] = "",
					["function3"] = "",
					["whichShortcut"] = whichShortcut,
				}
				table.insert(transitionChooserChoices, 1, individualEffect)
			end
		end

		--------------------------------------------------------------------------------
		-- Sort everything:
		--------------------------------------------------------------------------------
		table.sort(transitionChooserChoices, function(a, b) return a.text < b.text end)

		--------------------------------------------------------------------------------
		-- Setup Chooser:
		--------------------------------------------------------------------------------
		transitionChooser = chooser.new(transitionsChooserAction):bgDark(true)
																 :choices(transitionChooserChoices)

		--------------------------------------------------------------------------------
		-- Allow for Reduce Transparency:
		--------------------------------------------------------------------------------
		if screen.accessibilitySettings()["ReduceTransparency"] then
			transitionChooser:fgColor(nil)
							 :subTextColor(nil)
		else
			transitionChooser:fgColor(drawing.color.x11.snow)
							 :subTextColor(drawing.color.x11.snow)
		end

		--------------------------------------------------------------------------------
		-- Show Chooser:
		--------------------------------------------------------------------------------
		transitionChooser:show()

	end

		--------------------------------------------------------------------------------
		-- ASSIGN EFFECTS SHORTCUT CHOOSER ACTION:
		--------------------------------------------------------------------------------
		function transitionsChooserAction(result)

			--------------------------------------------------------------------------------
			-- Hide Chooser:
			--------------------------------------------------------------------------------
			transitionChooser:hide()

			--------------------------------------------------------------------------------
			-- Perform Specific Function:
			--------------------------------------------------------------------------------
			if result ~= nil then
				--------------------------------------------------------------------------------
				-- Save the selection:
				--------------------------------------------------------------------------------
				whichShortcut = result["whichShortcut"]
				if whichShortcut == 1 then settings.set("fcpxHacks.transitionsShortcutOne", 	result["text"]) end
				if whichShortcut == 2 then settings.set("fcpxHacks.transitionsShortcutTwo", 	result["text"]) end
				if whichShortcut == 3 then settings.set("fcpxHacks.transitionsShortcutThree", 	result["text"]) end
				if whichShortcut == 4 then settings.set("fcpxHacks.transitionsShortcutFour", 	result["text"]) end
				if whichShortcut == 5 then settings.set("fcpxHacks.transitionsShortcutFive", 	result["text"]) end
			end

			--------------------------------------------------------------------------------
			-- Put focus back in Final Cut Pro:
			--------------------------------------------------------------------------------
			if mod.wasFinalCutProOpen then fcp.launch() end

			--------------------------------------------------------------------------------
			-- Refresh Menubar:
			--------------------------------------------------------------------------------
			refreshMenuBar()

		end

	--------------------------------------------------------------------------------
	-- ASSIGN TITLES SHORTCUT:
	--------------------------------------------------------------------------------
	function assignTitlesShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Was Final Cut Pro Open?
		--------------------------------------------------------------------------------
		mod.wasFinalCutProOpen = fcp.frontmost()

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local titlesListUpdated = settings.get("fcpxHacks.titlesListUpdated")
		local allTitles = settings.get("fcpxHacks.allTitles")

		--------------------------------------------------------------------------------
		-- Error Checking:
		--------------------------------------------------------------------------------
		if not titlesListUpdated then
			dialog.displayMessage(i18n("assignTitlesShortcutError"))
			return "Failed"
		end
		if allTitles == nil then
			dialog.displayMessage(i18n("assignTitlesShortcutError"))
			return "Failed"
		end
		if next(allTitles) == nil then
			dialog.displayMessage(i18n("assignTitlesShortcutError"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Titles List:
		--------------------------------------------------------------------------------
		local titlesChooserChoices = {}
		if allTitles ~= nil and next(allTitles) ~= nil then
			for i=1, #allTitles do
				individualEffect = {
					["text"] = allTitles[i],
					["subText"] = "Title",
					["function"] = "transitionsShortcut",
					["function1"] = allTitles[i],
					["function2"] = "",
					["function3"] = "",
					["whichShortcut"] = whichShortcut,
				}
				table.insert(titlesChooserChoices, 1, individualEffect)
			end
		end

		--------------------------------------------------------------------------------
		-- Sort everything:
		--------------------------------------------------------------------------------
		table.sort(titlesChooserChoices, function(a, b) return a.text < b.text end)

		--------------------------------------------------------------------------------
		-- Setup Chooser:
		--------------------------------------------------------------------------------
		titlesChooser = chooser.new(titlesChooserAction):bgDark(true)
														:choices(titlesChooserChoices)

		--------------------------------------------------------------------------------
		-- Allow for Reduce Transparency:
		--------------------------------------------------------------------------------
		if screen.accessibilitySettings()["ReduceTransparency"] then
			titlesChooser:fgColor(nil)
						 :subTextColor(nil)
		else
			titlesChooser:fgColor(drawing.color.x11.snow)
						 :subTextColor(drawing.color.x11.snow)
		end

		--------------------------------------------------------------------------------
		-- Show Chooser:
		--------------------------------------------------------------------------------
		titlesChooser:show()

	end

		--------------------------------------------------------------------------------
		-- ASSIGN TITLES SHORTCUT CHOOSER ACTION:
		--------------------------------------------------------------------------------
		function titlesChooserAction(result)

			--------------------------------------------------------------------------------
			-- Hide Chooser:
			--------------------------------------------------------------------------------
			titlesChooser:hide()

			--------------------------------------------------------------------------------
			-- Perform Specific Function:
			--------------------------------------------------------------------------------
			if result ~= nil then
				--------------------------------------------------------------------------------
				-- Save the selection:
				--------------------------------------------------------------------------------
				whichShortcut = result["whichShortcut"]
				if whichShortcut == 1 then settings.set("fcpxHacks.titlesShortcutOne", 		result["text"]) end
				if whichShortcut == 2 then settings.set("fcpxHacks.titlesShortcutTwo", 		result["text"]) end
				if whichShortcut == 3 then settings.set("fcpxHacks.titlesShortcutThree", 	result["text"]) end
				if whichShortcut == 4 then settings.set("fcpxHacks.titlesShortcutFour", 		result["text"]) end
				if whichShortcut == 5 then settings.set("fcpxHacks.titlesShortcutFive", 		result["text"]) end
			end

			--------------------------------------------------------------------------------
			-- Put focus back in Final Cut Pro:
			--------------------------------------------------------------------------------
			if mod.wasFinalCutProOpen then fcp.launch() end

			--------------------------------------------------------------------------------
			-- Refresh Menubar:
			--------------------------------------------------------------------------------
			refreshMenuBar()

		end

	--------------------------------------------------------------------------------
	-- ASSIGN GENERATORS SHORTCUT:
	--------------------------------------------------------------------------------
	function assignGeneratorsShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Was Final Cut Pro Open?
		--------------------------------------------------------------------------------
		mod.wasFinalCutProOpen = fcp.frontmost()

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local generatorsListUpdated = settings.get("fcpxHacks.generatorsListUpdated")
		local allGenerators = settings.get("fcpxHacks.allGenerators")

		--------------------------------------------------------------------------------
		-- Error Checking:
		--------------------------------------------------------------------------------
		if not generatorsListUpdated then
			dialog.displayMessage(i18n("assignGeneratorsShortcutError"))
			return "Failed"
		end
		if allGenerators == nil then
			dialog.displayMessage(i18n("assignGeneratorsShortcutError"))
			return "Failed"
		end
		if next(allGenerators) == nil then
			dialog.displayMessage(i18n("assignGeneratorsShortcutError"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Generators List:
		--------------------------------------------------------------------------------
		local generatorsChooserChoices = {}
		if allGenerators ~= nil and next(allGenerators) ~= nil then
			for i=1, #allGenerators do
				individualEffect = {
					["text"] = allGenerators[i],
					["subText"] = "Generator",
					["function"] = "transitionsShortcut",
					["function1"] = allGenerators[i],
					["function2"] = "",
					["function3"] = "",
					["whichShortcut"] = whichShortcut,
				}
				table.insert(generatorsChooserChoices, 1, individualEffect)
			end
		end

		--------------------------------------------------------------------------------
		-- Sort everything:
		--------------------------------------------------------------------------------
		table.sort(generatorsChooserChoices, function(a, b) return a.text < b.text end)

		--------------------------------------------------------------------------------
		-- Setup Chooser:
		--------------------------------------------------------------------------------
		generatorsChooser = chooser.new(generatorsChooserAction):bgDark(true)
																:choices(generatorsChooserChoices)

		--------------------------------------------------------------------------------
		-- Allow for Reduce Transparency:
		--------------------------------------------------------------------------------
		if screen.accessibilitySettings()["ReduceTransparency"] then
			generatorsChooser:fgColor(nil)
							 :subTextColor(nil)
		else
			generatorsChooser:fgColor(drawing.color.x11.snow)
							 :subTextColor(drawing.color.x11.snow)
		end

		--------------------------------------------------------------------------------
		-- Show Chooser:
		--------------------------------------------------------------------------------
		generatorsChooser:show()

	end

		--------------------------------------------------------------------------------
		-- ASSIGN GENERATORS SHORTCUT CHOOSER ACTION:
		--------------------------------------------------------------------------------
		function generatorsChooserAction(result)

			--------------------------------------------------------------------------------
			-- Hide Chooser:
			--------------------------------------------------------------------------------
			generatorsChooser:hide()

			--------------------------------------------------------------------------------
			-- Perform Specific Function:
			--------------------------------------------------------------------------------
			if result ~= nil then
				--------------------------------------------------------------------------------
				-- Save the selection:
				--------------------------------------------------------------------------------
				whichShortcut = result["whichShortcut"]
				if whichShortcut == 1 then settings.set("fcpxHacks.generatorsShortcutOne", 		result["text"]) end
				if whichShortcut == 2 then settings.set("fcpxHacks.generatorsShortcutTwo", 		result["text"]) end
				if whichShortcut == 3 then settings.set("fcpxHacks.generatorsShortcutThree", 	result["text"]) end
				if whichShortcut == 4 then settings.set("fcpxHacks.generatorsShortcutFour", 		result["text"]) end
				if whichShortcut == 5 then settings.set("fcpxHacks.generatorsShortcutFive", 		result["text"]) end
			end

			--------------------------------------------------------------------------------
			-- Put focus back in Final Cut Pro:
			--------------------------------------------------------------------------------
			if mod.wasFinalCutProOpen then fcp.launch() end

			--------------------------------------------------------------------------------
			-- Refresh Menubar:
			--------------------------------------------------------------------------------
			refreshMenuBar()

		end

--------------------------------------------------------------------------------
-- CHANGE:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- CHANGE BATCH EXPORT DESTINATION PRESET:
	--------------------------------------------------------------------------------
	function changeBatchExportDestinationPreset()
		local shareMenuItems = fcp.app():menuBar():findMenuItemsUI("File", "Share")
		if not shareMenuItems then
			dialog.displayErrorMessage(i18n("batchExportDestinationsNotFound"))
			return
		end

		local destinations = {}

		for i = 1, #shareMenuItems-2 do
			local item = shareMenuItems[i]
			local title = item:attributeValue("AXTitle")
			if title ~= nil then
				local value = string.sub(title, 1, -4)
				if item:attributeValue("AXMenuItemCmdChar") then -- it's the default
					-- Remove (default) text:
					local firstBracket = string.find(value, " %(", 1)
					if firstBracket == nil then
						firstBracket = string.find(value, "（", 1)
					end
					value = string.sub(value, 1, firstBracket - 1)
				end
				destinations[#destinations + 1] = value
			end
		end

		local batchExportDestinationPreset = settings.get("fcpxHacks.batchExportDestinationPreset")
		local defaultItems = {}
		if batchExportDestinationPreset ~= nil then defaultItems[1] = batchExportDestinationPreset end

		local result = dialog.displayChooseFromList(i18n("selectDestinationPreset"), destinations, defaultItems)
		if result and #result > 0 then
			settings.set("fcpxHacks.batchExportDestinationPreset", result[1])
		end
	end

	--------------------------------------------------------------------------------
	-- CHANGE BATCH EXPORT DESTINATION FOLDER:
	--------------------------------------------------------------------------------
	function changeBatchExportDestinationFolder()
		local result = dialog.displayChooseFolder(i18n("selectDestinationFolder"))
		if result == false then return end

		settings.set("fcpxHacks.batchExportDestinationFolder", result)
	end

	--------------------------------------------------------------------------------
	-- CHANGE FINAL CUT PRO LANGUAGE:
	--------------------------------------------------------------------------------
	function changeFinalCutProLanguage(language)

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp.running() then
			if dialog.displayYesNoQuestion(i18n("changeFinalCutProLanguage") .. "\n\n" .. i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Update Final Cut Pro's settings::
		--------------------------------------------------------------------------------
		local result = fcp.setPreference("AppleLanguages", {language})
		if not result then
			dialog.displayErrorMessage(i18n("failedToChangeLanguage"))
		end

		--------------------------------------------------------------------------------
		-- Change FCPX Hacks Language:
		--------------------------------------------------------------------------------
		fcp.currentLanguage(true, language)

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp.restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

	end

	--------------------------------------------------------------------------------
	-- CHANGE TOUCH BAR LOCATION:
	--------------------------------------------------------------------------------
	function changeTouchBarLocation(value)
		settings.set("fcpxHacks.displayTouchBarLocation", value)

		if touchBarSupported then
			local displayTouchBar = settings.get("fcpxHacks.displayTouchBar") or false
			if displayTouchBar then setTouchBarLocation() end
		end

		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- CHANGE HIGHLIGHT SHAPE:
	--------------------------------------------------------------------------------
	function changeHighlightShape(value)
		settings.set("fcpxHacks.displayHighlightShape", value)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- CHANGE HIGHLIGHT COLOUR:
	--------------------------------------------------------------------------------
	function changeHighlightColour(value)
		if value=="Custom" then
			local displayHighlightCustomColour = settings.get("fcpxHacks.displayHighlightCustomColour") or nil
			local result = dialog.displayColorPicker(displayHighlightCustomColour)
			if result == nil then return nil end
			settings.set("fcpxHacks.displayHighlightCustomColour", result)
		end
		settings.set("fcpxHacks.displayHighlightColour", value)
		refreshMenuBar()
	end

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
		if fcp.getPreference("FFPeriodicBackupInterval") == nil then
			mod.FFPeriodicBackupInterval = 15
		else
			mod.FFPeriodicBackupInterval = fcp.getPreference("FFPeriodicBackupInterval")
		end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp.running() then
			if dialog.displayYesNoQuestion(i18n("changeBackupInterval") .. "\n\n" .. doYouWantToContinue) then
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
		local result = fcp.setPreference("FFPeriodicBackupInterval", tostring(userSelectedBackupInterval))
		if result == nil then
			dialog.displayErrorMessage(i18n("backupIntervalFail"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Refresh Menubar:
		--------------------------------------------------------------------------------
		refreshMenuBar(true)

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp.restart() then
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
		local executeResult,executeStatus = execute("/usr/libexec/PlistBuddy -c \"Print :FFOrganizerSmartCollections\" '" .. fcp.path() .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/en.lproj/FFLocalizable.strings'")
		if tools.trim(executeResult) ~= "" then FFOrganizerSmartCollections = executeResult end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp.running() then
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
		for k, v in pairs(fcp.flexoLanguages()) do
			local executeCommand = "/usr/libexec/PlistBuddy -c \"Set :FFOrganizerSmartCollections " .. tools.trim(userSelectedSmartCollectionsLabel) .. "\" '" .. fcp.path() .. "/Contents/Frameworks/Flexo.framework/Versions/A/Resources/" .. fcp.flexoLanguages()[k] .. ".lproj/FFLocalizable.strings'"
			executeCommands[#executeCommands + 1] = executeCommand
		end
		local result = tools.executeWithAdministratorPrivileges(executeCommands)
		if not result then
			dialog.displayErrorMessage("Failed to change Smart Collection Label.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp.restart() then
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
	-- TOGGLE SCROLLING TIMELINE:
	--------------------------------------------------------------------------------
	function toggleScrollingTimeline()

		--------------------------------------------------------------------------------
		-- Toggle Scrolling Timeline:
		--------------------------------------------------------------------------------
		local scrollingTimelineActivated = settings.get("fcpxHacks.scrollingTimelineActive") or false
		if scrollingTimelineActivated then
			--------------------------------------------------------------------------------
			-- Update Settings:
			--------------------------------------------------------------------------------
			settings.set("fcpxHacks.scrollingTimelineActive", false)

			--------------------------------------------------------------------------------
			-- Stop Watchers:
			--------------------------------------------------------------------------------
			mod.scrollingTimelineWatcherDown:stop()
			fcp.app():timeline():unlockPlayhead()

			--------------------------------------------------------------------------------
			-- Display Notification:
			--------------------------------------------------------------------------------
			dialog.displayNotification(i18n("scrollingTimelineDeactivated"))

		else
			--------------------------------------------------------------------------------
			-- Ensure that Playhead Lock is Off:
			--------------------------------------------------------------------------------
			local message = ""
			local lockTimelinePlayhead = settings.get("fcpxHacks.lockTimelinePlayhead") or false
			if lockTimelinePlayhead then
				toggleLockPlayhead()
				message = i18n("playheadLockDeactivated") .. "\n"
			end

			--------------------------------------------------------------------------------
			-- Update Settings:
			--------------------------------------------------------------------------------
			settings.set("fcpxHacks.scrollingTimelineActive", true)

			--------------------------------------------------------------------------------
			-- Start Watchers:
			--------------------------------------------------------------------------------
			mod.scrollingTimelineWatcherDown:start()

			--------------------------------------------------------------------------------
			-- If activated whilst already playing, then turn on Scrolling Timeline:
			--------------------------------------------------------------------------------
			checkScrollingTimeline()

			--------------------------------------------------------------------------------
			-- Display Notification:
			--------------------------------------------------------------------------------
			dialog.displayNotification(message..i18n("scrollingTimelineActivated"))

		end

		--------------------------------------------------------------------------------
		-- Refresh Menu Bar:
		--------------------------------------------------------------------------------
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE LOCK PLAYHEAD:
	--------------------------------------------------------------------------------
	function toggleLockPlayhead()

		local lockTimelinePlayhead = settings.get("fcpxHacks.lockTimelinePlayhead") or false

		if lockTimelinePlayhead then
			if fcp.running() then
				fcp.app():timeline():unlockPlayhead()
			end
			dialog.displayNotification(i18n("playheadLockDeactivated"))
			settings.set("fcpxHacks.lockTimelinePlayhead", false)
		else
			local message = ""
			--------------------------------------------------------------------------------
			-- Ensure that Scrolling Timeline is off
			--------------------------------------------------------------------------------
			local scrollingTimeline = settings.get("fcpxHacks.scrollingTimelineActive") or false
			if scrollingTimeline then
				toggleScrollingTimeline()
				message = i18n("scrollingTimelineDeactivated") .. "\n"
			end
			if fcp.running() then
				fcp.app():timeline():lockPlayhead()
			end
			dialog.displayNotification(message..i18n("playheadLockActivated"))
			settings.set("fcpxHacks.lockTimelinePlayhead", true)
		end

		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE BATCH EXPORT REPLACE EXISTING FILES:
	--------------------------------------------------------------------------------
	function toggleBatchExportReplaceExistingFiles()
		local batchExportReplaceExistingFiles = settings.get("fcpxHacks.batchExportReplaceExistingFiles")
		settings.set("fcpxHacks.batchExportReplaceExistingFiles", not batchExportReplaceExistingFiles)
		refreshMenuBar()
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
			if fcp.frontmost() then
				voicecommands:start()
			end
		end
		refreshMenuBar()

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
			if fcp.frontmost() then
				hackshud.show()
			end
		end

		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE DEBUG MODE:
	--------------------------------------------------------------------------------
	function toggleDebugMode()
		mod.debugMode = not mod.debugMode

		if mod.debugMode then
			logger.defaultLogLevel = 'warn'
		else
			logger.defaultLogLevel = 'debug'
		end

		settings.set("fcpxHacks.debugMode", mod.debugMode)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE CHECK FOR UPDATES:
	--------------------------------------------------------------------------------
	function toggleCheckForUpdates()
		local enableCheckForUpdates = settings.get("fcpxHacks.enableCheckForUpdates")
		settings.set("fcpxHacks.enableCheckForUpdates", not enableCheckForUpdates)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE MENUBAR DISPLAY:
	--------------------------------------------------------------------------------
	function toggleMenubarDisplay(value)
		local menubarEnabled = settings.get("fcpxHacks.menubar" .. value .. "Enabled")
		settings.set("fcpxHacks.menubar" .. value .. "Enabled", not menubarEnabled)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HUD OPTION:
	--------------------------------------------------------------------------------
	function toggleHUDOption(value)
		local result = settings.get("fcpxHacks." .. value)
		settings.set("fcpxHacks." .. value, not result)
		hackshud.reload()
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE MEDIA IMPORT WATCHER:
	--------------------------------------------------------------------------------
	function toggleMediaImportWatcher()
		local enableMediaImportWatcher = settings.get("fcpxHacks.enableMediaImportWatcher") or false
		if not enableMediaImportWatcher then
			mediaImportWatcher()
		else
			mod.newDeviceMounted:stop()
		end
		settings.set("fcpxHacks.enableMediaImportWatcher", not enableMediaImportWatcher)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE CLIPBOARD HISTORY:
	--------------------------------------------------------------------------------
	function toggleEnableClipboardHistory()
		local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false
		if not enableClipboardHistory then
			clipboard.startWatching()
		else
			clipboard.stopWatching()
		end
		settings.set("fcpxHacks.enableClipboardHistory", not enableClipboardHistory)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE SHARED CLIPBOARD:
	--------------------------------------------------------------------------------
	function toggleEnableSharedClipboard()

		local enableSharedClipboard = settings.get("fcpxHacks.enableSharedClipboard") or false

		if not enableSharedClipboard then

			result = dialog.displayChooseFolder("Which folder would you like to use for the Shared Clipboard?")

			if result ~= false then
				debugMessage("Enabled Shared Clipboard Path: " .. tostring(result))
				settings.set("fcpxHacks.sharedClipboardPath", result)

				--------------------------------------------------------------------------------
				-- Watch for Shared Clipboard Changes:
				--------------------------------------------------------------------------------
				sharedClipboardWatcher = pathwatcher.new(result, sharedClipboardFileWatcher):start()

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

		end

		settings.set("fcpxHacks.enableSharedClipboard", not enableSharedClipboard)
		refreshMenuBar()

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
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE MOBILE NOTIFICATIONS:
	--------------------------------------------------------------------------------
	function toggleEnableMobileNotifications()
		local enableMobileNotifications 	= settings.get("fcpxHacks.enableMobileNotifications") or false
		local prowlAPIKey 					= settings.get("fcpxHacks.prowlAPIKey") or ""

		if not enableMobileNotifications then

			local returnToFinalCutPro = fcp.frontmost()
			::retryProwlAPIKeyEntry::

			local result = dialog.displayTextBoxMessage(i18n("mobileNotificationsTextbox"), i18n("mobileNotificationsError") .. "\n\n" .. i18n("pleaseTryAgain"), prowlAPIKey)

			if result == false then
				return "Cancel"
			end
			local prowlAPIKeyValidResult, prowlAPIKeyValidError = prowlAPIKeyValid(result)
			if prowlAPIKeyValidResult then
				if returnToFinalCutPro then fcp.launch() end
				settings.set("fcpxHacks.prowlAPIKey", result)
				notificationWatcher()
				settings.set("fcpxHacks.enableMobileNotifications", not enableMobileNotifications)
			else
				dialog.displayMessage(i18n("prowlError") .. " " .. prowlAPIKeyValidError .. ".\n\n" .. i18n("pleaseTryAgain"))
				goto retryProwlAPIKeyEntry
			end
		else
			shareSuccessNotificationWatcher:stop()
			shareFailedNotificationWatcher:stop()
			settings.set("fcpxHacks.enableMobileNotifications", not enableMobileNotifications)
		end
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HAMMERSPOON DOCK ICON:
	--------------------------------------------------------------------------------
	function toggleHammerspoonDockIcon()
		local originalValue = hs.dockIcon()
		hs.dockIcon(not originalValue)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HAMMERSPOON MENU ICON:
	--------------------------------------------------------------------------------
	function toggleHammerspoonMenuIcon()
		local originalValue = hs.menuIcon()
		hs.menuIcon(not originalValue)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE LAUNCH HAMMERSPOON ON START:
	--------------------------------------------------------------------------------
	function toggleLaunchHammerspoonOnStartup()
		local originalValue = hs.autoLaunch()
		hs.autoLaunch(not originalValue)
		refreshMenuBar()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HAMMERSPOON CHECK FOR UPDATES:
	--------------------------------------------------------------------------------
	function toggleCheckforHammerspoonUpdates()
		local originalValue = hs.automaticallyCheckForUpdates()
		hs.automaticallyCheckForUpdates(not originalValue)
		refreshMenuBar()
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
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE HACKS SHORTCUTS IN FINAL CUT PRO:
	--------------------------------------------------------------------------------
	function toggleEnableHacksShortcutsInFinalCutPro()

		--------------------------------------------------------------------------------
		-- Get current value from settings:
		--------------------------------------------------------------------------------
		local enableHacksShortcutsInFinalCutPro = settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro")
		if enableHacksShortcutsInFinalCutPro == nil then enableHacksShortcutsInFinalCutPro = false end

		--------------------------------------------------------------------------------
		-- Are we enabling or disabling?
		--------------------------------------------------------------------------------
		local enableOrDisableText = nil
		if enableHacksShortcutsInFinalCutPro then
			enableOrDisableText = "Disabling"
		else
			enableOrDisableText = "Enabling"
		end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp.running() then
			if dialog.displayYesNoQuestion(enableOrDisableText .. " " .. i18n("hacksShortcutsRestart") .. " " .. i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		else
			if not dialog.displayYesNoQuestion(enableOrDisableText .. " " .. i18n("hacksShortcutAdminPassword") .. " " .. i18n("doYouWantToContinue")) then
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Let's do it!
		--------------------------------------------------------------------------------
		local saveSettings = false
		if enableHacksShortcutsInFinalCutPro then
			--------------------------------------------------------------------------------
			-- Revert back to default keyboard layout:
			--------------------------------------------------------------------------------
			local result = fcp.setPreference("Active Command Set", fcp.path() .. "/Contents/Resources/en.lproj/Default.commandset")
			if result == nil then
				dialog.displayErrorMessage(i18n("activeCommandSetResetError"))
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Disable Hacks Shortcut in Final Cut Pro:
			--------------------------------------------------------------------------------
			local result = disableHacksShortcuts()
			if result ~= "Done" then
				dialog.displayErrorMessage(i18n("failedToReplaceFile") .. "\n\n" .. result)
				return false
			end
		else
			--------------------------------------------------------------------------------
			-- Revert back to default keyboard layout:
			--------------------------------------------------------------------------------
			local result = fcp.setPreference("Active Command Set", fcp.path() .. "/Contents/Resources/en.lproj/Default.commandset")
			if result == nil then
				dialog.displayErrorMessage(i18n("activeCommandSetResetError"))
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Enable Hacks Shortcut in Final Cut Pro:
			--------------------------------------------------------------------------------
			local result = enableHacksShortcuts()
			if result ~= "Done" then
				dialog.displayErrorMessage(i18n("failedToReplaceFile") .. "\n\n" .. result)
				return false
			end
		end


		--------------------------------------------------------------------------------
		-- Save new value to settings:
		--------------------------------------------------------------------------------
		settings.set("fcpxHacks.enableHacksShortcutsInFinalCutPro", not enableHacksShortcutsInFinalCutPro)

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp.restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Refresh the Keyboard Shortcuts:
		--------------------------------------------------------------------------------
		bindKeyboardShortcuts()

		--------------------------------------------------------------------------------
		-- Refresh the Menu Bar:
		--------------------------------------------------------------------------------
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE ENABLE SHORTCUTS DURING FULLSCREEN PLAYBACK:
	--------------------------------------------------------------------------------
	function toggleEnableShortcutsDuringFullscreenPlayback()

		local enableShortcutsDuringFullscreenPlayback = settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback")
		if enableShortcutsDuringFullscreenPlayback == nil then enableShortcutsDuringFullscreenPlayback = false end
		settings.set("fcpxHacks.enableShortcutsDuringFullscreenPlayback", not enableShortcutsDuringFullscreenPlayback)

		if enableShortcutsDuringFullscreenPlayback == true then
			fullscreenKeyboardWatcherUp:stop()
			fullscreenKeyboardWatcherDown:stop()
		else
			fullscreenKeyboardWatcherUp:start()
			fullscreenKeyboardWatcherDown:start()
		end

		refreshMenuBar()

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
		local executeResult,executeStatus = execute("/usr/libexec/PlistBuddy -c \"Print :TLKMarkerHandler:Configuration:'Allow Moving Markers'\" '" .. fcp.path() .. "/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist'")
		if tools.trim(executeResult) == "true" then mod.allowMovingMarkers = true end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp.running() then
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
			local executeStatus = tools.executeWithAdministratorPrivileges([[/usr/libexec/PlistBuddy -c \"Set :TLKMarkerHandler:Configuration:'Allow Moving Markers' false\" ']] .. fcp.path() .. [[/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist']])
			if executeStatus == false then
				dialog.displayErrorMessage(i18n("movingMarkersError"))
				return "Failed"
			end
		else
			local executeStatus = tools.executeWithAdministratorPrivileges([[/usr/libexec/PlistBuddy -c \"Set :TLKMarkerHandler:Configuration:'Allow Moving Markers' true\" ']] .. fcp.path() .. [[/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist']])
			if executeStatus == false then
				dialog.displayErrorMessage(i18n("movingMarkersError"))
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp.restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Refresh Menu Bar:
		--------------------------------------------------------------------------------
		refreshMenuBar(true)

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
		if fcp.getPreference("FFSuspendBGOpsDuringPlay") == nil then
			mod.FFSuspendBGOpsDuringPlay = false
		else
			mod.FFSuspendBGOpsDuringPlay = fcp.getPreference("FFSuspendBGOpsDuringPlay")
		end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp.running() then
			if dialog.displayYesNoQuestion(i18n("togglingBackgroundTasksRestart") .. "\n\n" ..i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		if mod.FFSuspendBGOpsDuringPlay then
			local result = fcp.setPreference("FFSuspendBGOpsDuringPlay", false)
			if result == nil then
				dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
				return "Failed"
			end
		else
			local result = fcp.setPreference("FFSuspendBGOpsDuringPlay", true)
			if result == nil then
				dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp.restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Refresh Menu Bar:
		--------------------------------------------------------------------------------
		refreshMenuBar(true)

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
		if fcp.getPreference("FFEnableGuards") == nil then
			mod.FFEnableGuards = false
		else
			mod.FFEnableGuards = fcp.getPreference("FFEnableGuards")
		end

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp.running() then
			if dialog.displayYesNoQuestion(i18n("togglingTimecodeOverlayRestart") .. "\n\n" .. i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		if mod.FFEnableGuards then
			local result = fcp.setPreference("FFEnableGuards", false)
			if result == nil then
				dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
				return "Failed"
			end
		else
			local result = fcp.setPreference("FFEnableGuards", true)
			if result == nil then
				dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp.restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end

		--------------------------------------------------------------------------------
		-- Refresh Menu Bar:
		--------------------------------------------------------------------------------
		refreshMenuBar(true)

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
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE CREATE MULTI-CAM OPTIMISED MEDIA:
	--------------------------------------------------------------------------------
	function toggleCreateMulticamOptimizedMedia(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp.launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		log.d("optionalValue: "..inspect(optionalValue))
		if optionalValue ~= nil and optionalValue == fcp.getPreference("FFCreateOptimizedMediaForMulticamClips", true) then
			log.d("optionalValue matches preference value. Bailing.")
			return
		end

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local prefs = fcp:app():preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:playbackPanel():toggleCreateOptimizedMediaForMulticamClips() then
			dialog.displayErrorMessage("Failed to toggle 'Create Optimized Media for Multicam Clips'.\n\nError occurred in toggleCreateMulticamOptimizedMedia().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE CREATE PROXY MEDIA:
	--------------------------------------------------------------------------------
	function toggleCreateProxyMedia(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp.launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		if optionalValue ~= nil and optionalValue == fcp.getPreference("FFImportCreateProxyMedia", false) then
			return
		end

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local prefs = fcp:app():preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:importPanel():toggleCreateProxyMedia() then
			dialog.displayErrorMessage("Failed to toggle 'Create Proxy Media'.\n\nError occurred in toggleCreateProxyMedia().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE CREATE OPTIMIZED MEDIA:
	--------------------------------------------------------------------------------
	function toggleCreateOptimizedMedia(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp.launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		if optionalValue ~= nil and optionalValue == fcp.getPreference("FFImportCreateOptimizeMedia", false) then
			return
		end

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local prefs = fcp:app():preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:importPanel():toggleCreateOptimizedMedia() then
			dialog.displayErrorMessage("Failed to toggle 'Create Optimized Media'.\n\nError occurred in toggleCreateOptimizedMedia().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE LEAVE IN PLACE ON IMPORT:
	--------------------------------------------------------------------------------
	function toggleLeaveInPlace(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp.launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		if optionalValue ~= nil and optionalValue == fcp.getPreference("FFImportCopyToMediaFolder", true) then
			return
		end

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local prefs = fcp:app():preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:importPanel():toggleCopyToMediaFolder() then
			dialog.displayErrorMessage("Failed to toggle 'Copy To Media Folder'.\n\nError occurred in toggleLeaveInPlace().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE BACKGROUND RENDER:
	--------------------------------------------------------------------------------
	function toggleBackgroundRender(optionalValue)

		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp.launch()

		--------------------------------------------------------------------------------
		-- If we're setting rather than toggling...
		--------------------------------------------------------------------------------
		if optionalValue ~= nil and optionalValue == fcp.getPreference("FFAutoStartBGRender", true) then
			return
		end

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local prefs = fcp:app():preferencesWindow()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if not prefs:playbackPanel():toggleAutoStartBGRender() then
			dialog.displayErrorMessage("Failed to toggle 'Enable Background Render'.\n\nError occurred in toggleBackgroundRender().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		prefs:hide()

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
		pasteboard.writeDataForUTI(fcp.clipboardUTI(), data)
		clipboard.startWatching()

		--------------------------------------------------------------------------------
		-- Paste in FCPX:
		--------------------------------------------------------------------------------
		fcp.launch()
		if not fcp.performShortcut("Paste") then
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
				pasteboard.writeDataForUTI(fcp.clipboardUTI(), currentClipboardData)
				clipboard.startWatching()

				--------------------------------------------------------------------------------
				-- Paste in FCPX:
				--------------------------------------------------------------------------------
				fcp.launch()
				if not fcp.performShortcut("Paste") then
					dialog.displayErrorMessage("Failed to trigger the 'Paste' Shortcut.\n\nError occured in pasteFromSharedClipboard().")
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
		refreshMenuBar()
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
			 refreshMenuBar()
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
		refreshMenuBar()

	end

--------------------------------------------------------------------------------
-- OTHER:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- QUIT FCPX HACKS:
	--------------------------------------------------------------------------------
	function quitFCPXHacks()
		application("Hammerspoon"):kill()
	end

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

		local finalCutProRunning = fcp.running()

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
		if result ~= "Done" then
			dialog.displayErrorMessage(i18n("failedToReplaceFile") .. "\n\n" .. result)
			return
		end

		--------------------------------------------------------------------------------
		-- Trash all FCPX Hacks Settings:
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
			if not fcp.restart() then
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
		os.execute('open "' .. fcpxhacks.updateURL .. '"')
	end

	--------------------------------------------------------------------------------
	-- GO TO LATENITE FILMS SITE:
	--------------------------------------------------------------------------------
	function gotoLateNiteSite()
		os.execute('open "' .. fcpxhacks.developerURL .. '"')
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
		local fcpx = fcp.application()
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
		local fcpx = fcp.application()
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
				dialog.displayErrorMessage("Could not find keyword disclosure triangle.\n\nError occured in restoreKeywordSearches().")
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
-- MATCH FRAME RELATED:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- PERFORM MULTICAM MATCH FRAME:
	--------------------------------------------------------------------------------
	function multicamMatchFrame(goBackToTimeline) -- True or False

		--------------------------------------------------------------------------------
		-- Just in case:
		--------------------------------------------------------------------------------
		if goBackToTimeline == nil then goBackToTimeline = true end
		if type(goBackToTimeline) ~= "boolean" then goBackToTimeline = true end

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		local menuBar = fcp:app():menuBar()

		--------------------------------------------------------------------------------
		-- Open in Angle Editor:
		--------------------------------------------------------------------------------
		if menuBar:isEnabled("Clip", "Open in Angle Editor") then
			menuBar:selectMenu("Clip", "Open in Angle Editor")
		else
			dialog.displayErrorMessage("Failed to open clip in Angle Editor.\n\nAre you sure the clip you have selected is a Multicam?\n\nError occured in multicamMatchFrame().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Put focus back on the timeline:
		--------------------------------------------------------------------------------
		if menuBar:isEnabled("Window", "Go To", "Timeline") then
			menuBar:selectMenu("Window", "Go To", "Timeline")
		else
			dialog.displayErrorMessage("Unable to return to timeline.\n\nError occured in multicamMatchFrame().")
			return
		end

		--------------------------------------------------------------------------------
		-- Select Clip:
		--------------------------------------------------------------------------------
		if menuBar:isEnabled("Edit", "Select Clip") then
			menuBar:selectMenu("Edit", "Select Clip")
		else
			dialog.displayErrorMessage("Unable to select clip.\n\nError occured in multicamMatchFrame().")
			return
		end

		--------------------------------------------------------------------------------
		-- Reveal In Browser:
		--------------------------------------------------------------------------------
		if menuBar:isEnabled("File", "Reveal in Browser") then
			menuBar:selectMenu("File", "Reveal in Browser")
		else
			dialog.displayErrorMessage("Unable to Reveal in Browser.\n\nError occured in multicamMatchFrame().")
			return
		end

		--------------------------------------------------------------------------------
		-- Go back to original timeline if appropriate:
		--------------------------------------------------------------------------------
		if goBackToTimeline then
			if menuBar:isEnabled("View", "Timeline History Back") then
				menuBar:selectMenu("View", "Timeline History Back")
			else
				dialog.displayErrorMessage("Unable to go back to previous timeline.\n\nError occured in multicamMatchFrame().")
				return
			end
		end

		--------------------------------------------------------------------------------
		-- Highlight Browser Playhead:
		--------------------------------------------------------------------------------
		highlightFCPXBrowserPlayhead()

	end

	--------------------------------------------------------------------------------
	-- MATCH FRAME THEN HIGHLIGHT FCPX BROWSER PLAYHEAD:
	--------------------------------------------------------------------------------
	function matchFrameThenHighlightFCPXBrowserPlayhead()

		--------------------------------------------------------------------------------
		-- Delete Any Highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Click on 'Reveal in Browser':
		--------------------------------------------------------------------------------
		if fcp:app():menuBar():isEnabled("File", "Reveal in Browser") then
			fcp:app():menuBar():selectMenu("File", "Reveal in Browser")
			highlightFCPXBrowserPlayhead()
		else
			dialog.displayErrorMessage("Failed to 'Reveal in Browser'.\n\nError occurred in matchFrameThenHighlightFCPXBrowserPlayhead().")
			return "Fail"
		end

	end

	--------------------------------------------------------------------------------
	-- FCPX SINGLE MATCH FRAME:
	--------------------------------------------------------------------------------
	function singleMatchFrame()

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Click on 'Reveal in Browser':
		--------------------------------------------------------------------------------
		if fcp:app():menuBar():isEnabled("File", "Reveal in Browser") then
			fcp:app():menuBar():selectMenu("File", "Reveal in Browser")
		else
			dialog.displayErrorMessage("Unable to trigger Reveal in Browser.\n\nError occured in singleMatchFrame().")
			return nil
		end

		--------------------------------------------------------------------------------
		-- Get Browser Persistent Playhead:
		--------------------------------------------------------------------------------
 		local browserPersistentPlayhead = fcp.getBrowserPersistentPlayhead()
		if browserPersistentPlayhead == nil then
			dialog.displayErrorMessage("Unable to find Browser Persistent Playhead.\n\nError occured in singleMatchFrame().")
			return nil
		end

		--------------------------------------------------------------------------------
		-- Get Description Based off Playhead:
		--------------------------------------------------------------------------------
		local persistentPlayheadPosition = browserPersistentPlayhead:attributeValue("AXPosition")

		persistentPlayheadPosition['x'] = persistentPlayheadPosition['x'] + 20
		persistentPlayheadPosition['y'] = persistentPlayheadPosition['y'] + 20

		local currentElement = ax.systemWideElement():elementAtPosition(persistentPlayheadPosition)
		if currentElement == nil then
			dialog.displayErrorMessage("FCPX Hacks was unable to find the clip name. This can sometimes happen when Final Cut Pro fails to 'Reveal in Browser' properly, so it's worth trying again.\n\nError occured in singleMatchFrame().")
			return nil
		end

		if currentElement:attributeValue("AXRole") == "AXHandle" then
			currentElement = currentElement:attributeValue("AXParent")
		end

		local searchTerm = currentElement:attributeValue("AXParent")[1]:attributeValue("AXValue")

		if searchTerm == nil or searchTerm == "" then
			dialog.displayErrorMessage("Unable to work out clip name.\n\nError occured in singleMatchFrame().")
			return nil
		end

		--------------------------------------------------------------------------------
		-- Check to see if Search Bar is already visible:
		--------------------------------------------------------------------------------
		local browserSplitGroup = fcp.getBrowserSplitGroup()
		local searchTextFieldID = nil
		for i=1, browserSplitGroup:attributeValueCount("AXChildren") do
			if browserSplitGroup[i]:attributeValue("AXRole") == "AXTextField" then
				if browserSplitGroup[i]:attributeValue("AXIdentifier") == "_NS:34" then
					searchTextFieldID = i
				end
			end
		end
		if searchTextFieldID == nil then

			--------------------------------------------------------------------------------
			-- Maybe the search bar is not visible?
			--------------------------------------------------------------------------------
			browserSearchButton = fcp.getBrowserSearchButton()
			local result = browserSearchButton:performAction("AXPress")

			if result == nil then
				dialog.displayErrorMessage("Failed to press Search Button.\n\nError occured in singleMatchFrame().")
				return nil
			end

			--------------------------------------------------------------------------------
			-- Try searching for it again:
			--------------------------------------------------------------------------------
			browserSplitGroup = fcp.getBrowserSplitGroup()
			for i=1, browserSplitGroup:attributeValueCount("AXChildren") do
				if browserSplitGroup[i]:attributeValue("AXRole") == "AXTextField" then
					if browserSplitGroup[i]:attributeValue("AXIdentifier") == "_NS:34" then
						searchTextFieldID = i
					end
				end
			end

			if searchTextFieldID == nil then
				dialog.displayErrorMessage("Failed to find Search Text Box.\n\nError occured in singleMatchFrame().")
				return nil
			end

		end

		--------------------------------------------------------------------------------
		-- Enter in search value:
		--------------------------------------------------------------------------------
		local result = browserSplitGroup[searchTextFieldID]:setAttributeValue("AXValue", searchTerm)
		if result == nil then
			dialog.displayErrorMessage("Failed enter value into the Search Text Field.\n\nError occured in singleMatchFrame().")
			return nil
		end

		--------------------------------------------------------------------------------
		-- Press search button:
		--------------------------------------------------------------------------------
		local result = browserSplitGroup[searchTextFieldID][1]:performAction("AXPress")
		if result == nil then
			dialog.displayErrorMessage("Failed trigger search button.\n\nError occured in singleMatchFrame().")
			return nil
		end

		--------------------------------------------------------------------------------
		-- Highlight Browser Playhead:
		--------------------------------------------------------------------------------
		highlightFCPXBrowserPlayhead()

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
		local colorBoard = fcp.app():colorBoard()

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

		colorBoard = fcp:app():colorBoard()

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
-- EFFECTS/TRANSITIONS/TITLES/GENERATOR RELATED:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- TRANSITIONS SHORTCUT PRESSED:
	--------------------------------------------------------------------------------
	function transitionsShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Hide the Touch Bar:
		--------------------------------------------------------------------------------
		hideTouchbar()

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local currentShortcut = nil
		if whichShortcut == 1 then
			currentShortcut = settings.get("fcpxHacks.transitionsShortcutOne")
		elseif whichShortcut == 2 then
			currentShortcut = settings.get("fcpxHacks.transitionsShortcutTwo")
		elseif whichShortcut == 3 then
			currentShortcut = settings.get("fcpxHacks.transitionsShortcutThree")
		elseif whichShortcut == 4 then
			currentShortcut = settings.get("fcpxHacks.transitionsShortcutFour")
		elseif whichShortcut == 5 then
			currentShortcut = settings.get("fcpxHacks.transitionsShortcutFive")
		else
			if tostring(whichShortcut) ~= "" then
				currentShortcut = tostring(whichShortcut)
			end
		end

		if currentShortcut == nil then
			dialog.displayMessage(i18n("noTransitionShortcut"))
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get Timeline Button Bar:
		--------------------------------------------------------------------------------
		local finalCutProTimelineButtonBar = fcp.getTimelineButtonBar()
		if finalCutProTimelineButtonBar == nil then
			dialog.displayErrorMessage("Unable to detect Timeline Button Bar.\n\nError occured in transitionsShortcut() whilst using fcp.getTimelineButtonBar().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Find Transitions Browser Button:
		--------------------------------------------------------------------------------
		local whichRadioGroup = nil
		for i=1, finalCutProTimelineButtonBar:attributeValueCount("AXChildren") do
			if finalCutProTimelineButtonBar[i]:attributeValue("AXRole") == "AXRadioGroup" then
				if finalCutProTimelineButtonBar[i]:attributeValue("AXIdentifier") == "_NS:165" then
					whichRadioGroup = i
				end
			end
		end
		if whichRadioGroup == nil then
			dialog.displayErrorMessage("Unable to detect Timeline Button Bar Radio Group.\n\nError occured in transitionsShortcut().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Effects or Transitions Panel Open?
		--------------------------------------------------------------------------------
		local whichPanelActivated = "None"
		if finalCutProTimelineButtonBar[whichRadioGroup][1] ~= nil then
			if finalCutProTimelineButtonBar[whichRadioGroup][1]:attributeValue("AXValue") == 1 then whichPanelActivated = "Effects" end
			if finalCutProTimelineButtonBar[whichRadioGroup][2]:attributeValue("AXValue") == 1 then whichPanelActivated = "Transitions" end
		end

		--------------------------------------------------------------------------------
		-- Make sure Transitions panel is open:
		--------------------------------------------------------------------------------
		local effectsBrowserButton = finalCutProTimelineButtonBar[whichRadioGroup][2]
		if effectsBrowserButton ~= nil then
			if effectsBrowserButton:attributeValue("AXValue") == 0 then
				local presseffectsBrowserButtonResult = effectsBrowserButton:performAction("AXPress")
				if presseffectsBrowserButtonResult == nil then
					dialog.displayErrorMessage("Unable to press Effects Browser Button icon.\n\nError occured in transitionsShortcut().")
					showTouchbar()
					return "Fail"
				end
			end
		else
			dialog.displayErrorMessage("Unable to activate Video Effects Panel\n\nError occured in transitionsShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Make sure "Installed Effects" is selected:
		--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Get Transitions Browser Group:
			--------------------------------------------------------------------------------
			local finalCutProEffectsTransitionsBrowserGroup = fcp.getEffectsTransitionsBrowserGroup()
			if finalCutProEffectsTransitionsBrowserGroup == nil then
				dialog.displayErrorMessage("Unable to get Transitions Browser Group.\n\nError occured in transitionsShortcut().")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Get Transitions Browser Split Group:
			--------------------------------------------------------------------------------
			local whichEffectsBrowserSplitGroup = nil
			for i=1, finalCutProEffectsTransitionsBrowserGroup:attributeValueCount("AXChildren") do
				if finalCutProEffectsTransitionsBrowserGroup[i]:attributeValue("AXRole") == "AXSplitGroup" then
					--if finalCutProEffectsTransitionsBrowserGroup[i]:attributeValue("AXIdentifier") == "_NS:452" then
						whichEffectsBrowserSplitGroup = i
					--end
				end
			end
			if whichEffectsBrowserSplitGroup == nil then
				dialog.displayErrorMessage("Unable to detect Transitions Browser's Split Group.\n\nError occured in transitionsShortcut().")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Get Transitions Browser Split Group:
			--------------------------------------------------------------------------------
			local whichEffectsBrowserPopupButton = nil
			for i=1, finalCutProEffectsTransitionsBrowserGroup[whichEffectsBrowserSplitGroup]:attributeValueCount("AXChildren") do
				if finalCutProEffectsTransitionsBrowserGroup[whichEffectsBrowserSplitGroup][i]:attributeValue("AXRole") == "AXPopUpButton" then
					if finalCutProEffectsTransitionsBrowserGroup[whichEffectsBrowserSplitGroup][i]:attributeValue("AXIdentifier") == "_NS:45" then
						whichEffectsBrowserPopupButton = i
					end
				end
			end
			if whichEffectsBrowserPopupButton == nil then
				dialog.displayErrorMessage("Unable to detect Transitions Browser's Popup Button.\n\nError occured in transitionsShortcut().")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Check that "Installed Effects" is selected:
			--------------------------------------------------------------------------------
			local installedEffectsPopup = finalCutProEffectsTransitionsBrowserGroup[whichEffectsBrowserSplitGroup][whichEffectsBrowserPopupButton]
			if installedEffectsPopup ~= nil then
				if installedEffectsPopup:attributeValue("AXValue") ~= "Installed Effects" then
					installedEffectsPopup:performAction("AXPress")
					finalCutProEffectsTransitionsBrowserGroup = fcp.getEffectsTransitionsBrowserGroup()
					if finalCutProEffectsTransitionsBrowserGroup == nil then
						dialog.displayErrorMessage("Unable to get Transitions Browser Group.\n\nError occured in transitionsShortcut().")
						return "Failed"
					end
					installedEffectsPopupMenuItem = finalCutProEffectsTransitionsBrowserGroup[whichEffectsBrowserSplitGroup][whichEffectsBrowserPopupButton][1][1]
					installedEffectsPopupMenuItem:performAction("AXPress")
				end
			else
				dialog.displayErrorMessage("Unable to find 'Installed Effects' popup.\n\nError occured in transitionsShortcut().")
				showTouchbar()
				return "Fail"
			end

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		local effectsSearchCancelButton = nil
		if finalCutProEffectsTransitionsBrowserGroup[4] ~= nil then
			if finalCutProEffectsTransitionsBrowserGroup[4][2] ~= nil then
				effectsSearchCancelButton = finalCutProEffectsTransitionsBrowserGroup[4][2]
			end
		end
		if effectsSearchCancelButton ~= nil then
			effectsSearchCancelButtonResult = effectsSearchCancelButton:performAction("AXPress")
			if effectsSearchCancelButtonResult == nil then
				dialog.displayErrorMessage("Unable to cancel effects search.\n\nError occured in transitionsShortcut().")
				showTouchbar()
				return "Fail"
			end
		end

		--------------------------------------------------------------------------------
		-- Click 'All':
		--------------------------------------------------------------------------------
		local allVideoAndAudioButton = nil
		if finalCutProEffectsTransitionsBrowserGroup[1] ~= nil then
			if finalCutProEffectsTransitionsBrowserGroup[1][1] ~= nil then
				if finalCutProEffectsTransitionsBrowserGroup[1][1][1] ~= nil then
					if finalCutProEffectsTransitionsBrowserGroup[1][1][1][1] ~= nil then
						allVideoAndAudioButton = finalCutProEffectsTransitionsBrowserGroup[1][1][1][1]
					end
				end
			end
		end
		if allVideoAndAudioButton ~= nil then
			allVideoAndAudioButton:setAttributeValue("AXSelected", true)
		else

			--------------------------------------------------------------------------------
			-- Make sure Transitions Browser Sidebar is Visible:
			--------------------------------------------------------------------------------
			effectsBrowserSidebar = finalCutProEffectsTransitionsBrowserGroup[2]
			if effectsBrowserSidebar ~= nil then
				if effectsBrowserSidebar:attributeValue("AXValue") == 1 then
					effectsBrowserSidebar:performAction("AXPress")
				end
			else
				dialog.displayErrorMessage("Unable to locate Effects Browser Sidebar button.\n\nError occured in transitionsShortcut().")
				showTouchbar()
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Click 'All Video & Audio':
			--------------------------------------------------------------------------------
			local allVideoAndAudioButton = nil
			if finalCutProEffectsTransitionsBrowserGroup[1] ~= nil then
				if finalCutProEffectsTransitionsBrowserGroup[1][1] ~= nil then
					if finalCutProEffectsTransitionsBrowserGroup[1][1][1] ~= nil then
						if finalCutProEffectsTransitionsBrowserGroup[1][1][1][1] ~= nil then
							allVideoAndAudioButton = finalCutProEffectsTransitionsBrowserGroup[1][1][1][1]
						end
					end
				end
			end
			if allVideoAndAudioButton ~= nil then
				allVideoAndAudioButton:setAttributeValue("AXSelected", true)
			else
				dialog.displayErrorMessage("Unable to locate 'All Video & Audio' button.\n\nError occured in transitionsShortcut().")
				showTouchbar()
				return "Fail"
			end
		end

		--------------------------------------------------------------------------------
		-- Add a bit of a delay...
		--------------------------------------------------------------------------------
		timer.usleep(100000)

		--------------------------------------------------------------------------------
		-- Perform Search:
		--------------------------------------------------------------------------------
		local effectsSearchField = nil
		if finalCutProEffectsTransitionsBrowserGroup[4] ~= nil then effectsSearchField = finalCutProEffectsTransitionsBrowserGroup[4] end
		if effectsSearchField ~= nil then
			effectsSearchField:setAttributeValue("AXValue", currentShortcut)
			effectsSearchField[1]:performAction("AXPress")
		else
			dialog.displayErrorMessage("Unable to type search request in search box.\n\nError occured in transitionsShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Make sure scroll bar is at top:
		--------------------------------------------------------------------------------
		local effectsScrollBar = nil
		if finalCutProEffectsTransitionsBrowserGroup[1] ~= nil then
			if finalCutProEffectsTransitionsBrowserGroup[1][4] ~= nil then
				if finalCutProEffectsTransitionsBrowserGroup[1][4][2] ~= nil then
					if finalCutProEffectsTransitionsBrowserGroup[1][4][2][1] ~= nil then
						effectsScrollBar = finalCutProEffectsTransitionsBrowserGroup[1][4][2][1]
					end
				end
			end
		end
		if effectsScrollBar ~= nil then
			effectsScrollBar:setAttributeValue("AXValue", 0)
		end

		--------------------------------------------------------------------------------
		-- Get First Item in Browser:
		--------------------------------------------------------------------------------
		local effectButton = nil
		if finalCutProEffectsTransitionsBrowserGroup[1] ~= nil then
			if finalCutProEffectsTransitionsBrowserGroup[1][4] ~= nil then
				if finalCutProEffectsTransitionsBrowserGroup[1][4][1] ~= nil then
					if finalCutProEffectsTransitionsBrowserGroup[1][4][1][1] ~= nil then
						effectButton = finalCutProEffectsTransitionsBrowserGroup[1][4][1][1]
					end
				end
			end
		end

		--------------------------------------------------------------------------------
		-- If Needed, Search Again Without Text Before First Dash:
		--------------------------------------------------------------------------------
		if effectButton == nil then

			--------------------------------------------------------------------------------
			-- Remove first dash:
			--------------------------------------------------------------------------------
			currentShortcut = string.sub(currentShortcut, string.find(currentShortcut, "-") + 2)

			writeToConsole("currentShortcut: " .. currentShortcut)

			--------------------------------------------------------------------------------
			-- Perform Search:
			--------------------------------------------------------------------------------
			if finalCutProEffectsTransitionsBrowserGroup[4] ~= nil then effectsSearchField = finalCutProEffectsTransitionsBrowserGroup[4] end
			if effectsSearchField ~= nil then
				effectsSearchField:setAttributeValue("AXValue", currentShortcut)
				effectsSearchField[1]:performAction("AXPress")
			else
				dialog.displayErrorMessage("Unable to type search request in search box.\n\nError occured in transitionsShortcut().")
				showTouchbar()
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Get First Item in Browser:
			--------------------------------------------------------------------------------
			if finalCutProEffectsTransitionsBrowserGroup[1] ~= nil then
				if finalCutProEffectsTransitionsBrowserGroup[1][4] ~= nil then
					if finalCutProEffectsTransitionsBrowserGroup[1][4][1] ~= nil then
						if finalCutProEffectsTransitionsBrowserGroup[1][4][1][1] ~= nil then
							effectButton = finalCutProEffectsTransitionsBrowserGroup[1][4][1][1]
						end
					end
				end
			end

		end

		--------------------------------------------------------------------------------
		-- Double Click on First Item in Browser:
		--------------------------------------------------------------------------------
		if effectButton ~= nil then

			--------------------------------------------------------------------------------
			-- Original Mouse Position:
			--------------------------------------------------------------------------------
			local originalMousePosition = mouse.getAbsolutePosition()

			--------------------------------------------------------------------------------
			-- Get centre of button:
			--------------------------------------------------------------------------------
			local effectButtonPosition = {}
			effectButtonPosition['x'] = effectButton:attributeValue("AXPosition")['x'] + (effectButton:attributeValue("AXSize")['w'] / 2)
			effectButtonPosition['y'] = effectButton:attributeValue("AXPosition")['y'] + (effectButton:attributeValue("AXSize")['h'] / 2)

			--------------------------------------------------------------------------------
			-- Double Click:
			--------------------------------------------------------------------------------
			tools.doubleLeftClick(effectButtonPosition)

			--------------------------------------------------------------------------------
			-- Put it back:
			--------------------------------------------------------------------------------
			mouse.setAbsolutePosition(originalMousePosition)

		else
			dialog.displayErrorMessage("Unable to locate effect.\n\nError occured in transitionsShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Add a bit of a delay:
		--------------------------------------------------------------------------------
		timer.doAfter(0.1, function()

			--------------------------------------------------------------------------------
			-- Make sure there's nothing in the search box:
			--------------------------------------------------------------------------------
			local effectsSearchCancelButton = nil
			if finalCutProEffectsTransitionsBrowserGroup[4] ~= nil then
				if finalCutProEffectsTransitionsBrowserGroup[4][2] ~= nil then
					effectsSearchCancelButton = finalCutProEffectsTransitionsBrowserGroup[4][2]
				end
			end
			if effectsSearchCancelButton ~= nil then
				effectsSearchCancelButtonResult = effectsSearchCancelButton:performAction("AXPress")
				if effectsSearchCancelButtonResult == nil then
					dialog.displayErrorMessage("Unable to cancel effects search.\n\nError occured in transitionsShortcut().")
					showTouchbar()
					return "Fail"
				end
			end

			--------------------------------------------------------------------------------
			-- Restore Effects or Transitions Panel:
			--------------------------------------------------------------------------------
			if whichPanelActivated == "Effects" then
				finalCutProTimelineButtonBar[whichRadioGroup][1]:performAction("AXPress")
			elseif whichPanelActivated == "None" then
				finalCutProTimelineButtonBar[whichRadioGroup][2]:performAction("AXPress")
			end

			--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			showTouchbar()

		end)

	end

	--------------------------------------------------------------------------------
	-- EFFECTS SHORTCUT PRESSED:
	--------------------------------------------------------------------------------
	function effectsShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Hide the Touch Bar:
		--------------------------------------------------------------------------------
		hideTouchbar()

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local currentShortcut = nil
		if whichShortcut == 1 then
			currentShortcut = settings.get("fcpxHacks.effectsShortcutOne")
		elseif whichShortcut == 2 then
			currentShortcut = settings.get("fcpxHacks.effectsShortcutTwo")
		elseif whichShortcut == 3 then
			currentShortcut = settings.get("fcpxHacks.effectsShortcutThree")
		elseif whichShortcut == 4 then
			currentShortcut = settings.get("fcpxHacks.effectsShortcutFour")
		elseif whichShortcut == 5 then
			currentShortcut = settings.get("fcpxHacks.effectsShortcutFive")
		else
			if tostring(whichShortcut) ~= "" then
				currentShortcut = tostring(whichShortcut)
			end
		end

		if currentShortcut == nil then
			dialog.displayMessage(i18n("noEffectShortcut"))
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get Timeline Button Bar:
		--------------------------------------------------------------------------------
		local finalCutProTimelineButtonBar = fcp.getTimelineButtonBar()
		if finalCutProTimelineButtonBar == nil then
			dialog.displayErrorMessage("Unable to detect Timeline Button Bar.\n\nError occured in effectsShortcut() whilst using fcp.getTimelineButtonBar().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Find Effects Browser Button:
		--------------------------------------------------------------------------------
		local whichRadioGroup = nil
		for i=1, finalCutProTimelineButtonBar:attributeValueCount("AXChildren") do
			if finalCutProTimelineButtonBar[i]:attributeValue("AXRole") == "AXRadioGroup" then
				if finalCutProTimelineButtonBar[i]:attributeValue("AXIdentifier") == "_NS:165" then
					whichRadioGroup = i
				end
			end
		end
		if whichRadioGroup == nil then
			dialog.displayErrorMessage("Unable to detect Timeline Button Bar Radio Group.\n\nError occured in effectsShortcut().")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Effects or Transitions Panel Open?
		--------------------------------------------------------------------------------
		local whichPanelActivated = "None"
		if finalCutProTimelineButtonBar[whichRadioGroup][1] ~= nil then
			if finalCutProTimelineButtonBar[whichRadioGroup][1]:attributeValue("AXValue") == 1 then whichPanelActivated = "Effects" end
			if finalCutProTimelineButtonBar[whichRadioGroup][2]:attributeValue("AXValue") == 1 then whichPanelActivated = "Transitions" end
		end

		--------------------------------------------------------------------------------
		-- Make sure Video Effects panel is open:
		--------------------------------------------------------------------------------
		local effectsBrowserButton = finalCutProTimelineButtonBar[whichRadioGroup][1]
		if effectsBrowserButton ~= nil then
			if effectsBrowserButton:attributeValue("AXValue") == 0 then
				local presseffectsBrowserButtonResult = effectsBrowserButton:performAction("AXPress")
				if presseffectsBrowserButtonResult == nil then
					dialog.displayErrorMessage("Unable to press Effects Browser Button icon.\n\nError occured in effectsShortcut().")
					showTouchbar()
					return "Fail"
				end
			end
		else
			dialog.displayErrorMessage("Unable to activate Video Effects Panel.\n\nError occured in effectsShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Make sure "Installed Effects" is selected:
		--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Get Transitions Browser Group:
			--------------------------------------------------------------------------------
			local finalCutProEffectsTransitionsBrowserGroup = fcp.getEffectsTransitionsBrowserGroup()
			if finalCutProEffectsTransitionsBrowserGroup == nil then
				dialog.displayErrorMessage("Unable to get Transitions Browser Group.\n\nError occured in effectsShortcut().")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Get Transitions Browser Split Group:
			--------------------------------------------------------------------------------
			local whichEffectsBrowserSplitGroup = nil
			for i=1, finalCutProEffectsTransitionsBrowserGroup:attributeValueCount("AXChildren") do
				if finalCutProEffectsTransitionsBrowserGroup[i]:attributeValue("AXRole") == "AXSplitGroup" then
					--if finalCutProEffectsTransitionsBrowserGroup[i]:attributeValue("AXIdentifier") == "_NS:452" then
						whichEffectsBrowserSplitGroup = i
					--end
				end
			end
			if whichEffectsBrowserSplitGroup == nil then
				dialog.displayErrorMessage("Unable to detect Transitions Browser's Split Group.\n\nError occured in effectsShortcut().")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Get Transitions Browsers Popup Button:
			--------------------------------------------------------------------------------
			local whichEffectsBrowserPopupButton = nil
			for i=1, finalCutProEffectsTransitionsBrowserGroup[whichEffectsBrowserSplitGroup]:attributeValueCount("AXChildren") do
				if finalCutProEffectsTransitionsBrowserGroup[whichEffectsBrowserSplitGroup][i]:attributeValue("AXRole") == "AXPopUpButton" then
					if finalCutProEffectsTransitionsBrowserGroup[whichEffectsBrowserSplitGroup][i]:attributeValue("AXIdentifier") == "_NS:45" then
						whichEffectsBrowserPopupButton = i
					end
				end
			end
			if whichEffectsBrowserPopupButton == nil then
				dialog.displayErrorMessage("Unable to detect Transitions Browser's Popup Button.\n\nError occured in effectsShortcut().")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Check that "Installed Effects" is selected:
			--------------------------------------------------------------------------------
			local installedEffectsPopup = finalCutProEffectsTransitionsBrowserGroup[whichEffectsBrowserSplitGroup][whichEffectsBrowserPopupButton]
			if installedEffectsPopup ~= nil then
				if installedEffectsPopup:attributeValue("AXValue") ~= "Installed Effects" then
					installedEffectsPopup:performAction("AXPress")
					finalCutProEffectsTransitionsBrowserGroup = fcp.getEffectsTransitionsBrowserGroup()
					if finalCutProEffectsTransitionsBrowserGroup == nil then
						dialog.displayErrorMessage("Unable to get Transitions Browser Group.\n\nError occured in effectsShortcut().")
						return "Failed"
					end
					installedEffectsPopupMenuItem = finalCutProEffectsTransitionsBrowserGroup[whichEffectsBrowserSplitGroup][whichEffectsBrowserPopupButton][1][1]
					installedEffectsPopupMenuItem:performAction("AXPress")
				end
			else
				dialog.displayErrorMessage("Unable to find 'Installed Effects' popup.\n\nError occured in effectsShortcut().")
				showTouchbar()
				return "Fail"
			end

		--------------------------------------------------------------------------------
		-- Make sure there's nothing in the search box:
		--------------------------------------------------------------------------------
		local effectsSearchCancelButton = nil
		if finalCutProEffectsTransitionsBrowserGroup[4] ~= nil then
			if finalCutProEffectsTransitionsBrowserGroup[4][2] ~= nil then
				effectsSearchCancelButton = finalCutProEffectsTransitionsBrowserGroup[4][2]
			end
		end
		if effectsSearchCancelButton ~= nil then
			effectsSearchCancelButtonResult = effectsSearchCancelButton:performAction("AXPress")
			if effectsSearchCancelButtonResult == nil then
				dialog.displayErrorMessage("Unable to cancel effects search.\n\nError occured in effectsShortcut().")
				showTouchbar()
				return "Fail"
			end
		end

		--------------------------------------------------------------------------------
		-- Click 'All Video & Audio':
		--------------------------------------------------------------------------------
		local allVideoAndAudioButton = nil
		if finalCutProEffectsTransitionsBrowserGroup[1] ~= nil then
			if finalCutProEffectsTransitionsBrowserGroup[1][1] ~= nil then
				if finalCutProEffectsTransitionsBrowserGroup[1][1][1] ~= nil then
					if finalCutProEffectsTransitionsBrowserGroup[1][1][1][1] ~= nil then
						allVideoAndAudioButton = finalCutProEffectsTransitionsBrowserGroup[1][1][1][1]
					end
				end
			end
		end
		if allVideoAndAudioButton ~= nil then
			allVideoAndAudioButton:setAttributeValue("AXSelected", true)
		else

			--------------------------------------------------------------------------------
			-- Make sure Effects Browser Sidebar is Visible:
			--------------------------------------------------------------------------------
			effectsBrowserSidebar = finalCutProEffectsTransitionsBrowserGroup[2]
			if effectsBrowserSidebar ~= nil then
				if effectsBrowserSidebar:attributeValue("AXValue") == 1 then
					effectsBrowserSidebar:performAction("AXPress")
				end
			else
				dialog.displayErrorMessage("Unable to locate Effects Browser Sidebar button.\n\nError occured in effectsShortcut().")
				showTouchbar()
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Click 'All Video & Audio':
			--------------------------------------------------------------------------------
			local allVideoAndAudioButton = nil
			if finalCutProEffectsTransitionsBrowserGroup[1] ~= nil then
				if finalCutProEffectsTransitionsBrowserGroup[1][1] ~= nil then
					if finalCutProEffectsTransitionsBrowserGroup[1][1][1] ~= nil then
						if finalCutProEffectsTransitionsBrowserGroup[1][1][1][1] ~= nil then
							allVideoAndAudioButton = finalCutProEffectsTransitionsBrowserGroup[1][1][1][1]
						end
					end
				end
			end
			if allVideoAndAudioButton ~= nil then
				allVideoAndAudioButton:setAttributeValue("AXSelected", true)
			else
				dialog.displayErrorMessage("Unable to locate 'All Video & Audio' button.\n\nError occured in effectsShortcut().")
				showTouchbar()
				return "Fail"
			end
		end

		--------------------------------------------------------------------------------
		-- Add a bit of a delay...
		--------------------------------------------------------------------------------
		timer.usleep(100000)

		--------------------------------------------------------------------------------
		-- Perform Search:
		--------------------------------------------------------------------------------
		local effectsSearchField = nil
		if finalCutProEffectsTransitionsBrowserGroup[4] ~= nil then effectsSearchField = finalCutProEffectsTransitionsBrowserGroup[4] end
		if effectsSearchField ~= nil then
			effectsSearchField:setAttributeValue("AXValue", currentShortcut)
			effectsSearchField[1]:performAction("AXPress")
		else
			dialog.displayErrorMessage("Unable to type search request in search box.\n\nError occured in effectsShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Make sure scroll bar is at top:
		--------------------------------------------------------------------------------
		local effectsScrollBar = nil
		if finalCutProEffectsTransitionsBrowserGroup[1] ~= nil then
			if finalCutProEffectsTransitionsBrowserGroup[1][4] ~= nil then
				if finalCutProEffectsTransitionsBrowserGroup[1][4][2] ~= nil then
					if finalCutProEffectsTransitionsBrowserGroup[1][4][2][1] ~= nil then
						effectsScrollBar = finalCutProEffectsTransitionsBrowserGroup[1][4][2][1]
					end
				end
			end
		end
		if effectsScrollBar ~= nil then
			effectsScrollBar:setAttributeValue("AXValue", 0)
		end

		--------------------------------------------------------------------------------
		-- Double click on effect:
		--------------------------------------------------------------------------------
		local effectButton = nil
		if finalCutProEffectsTransitionsBrowserGroup[1] ~= nil then
			if finalCutProEffectsTransitionsBrowserGroup[1][4] ~= nil then
				if finalCutProEffectsTransitionsBrowserGroup[1][4][1] ~= nil then
					if finalCutProEffectsTransitionsBrowserGroup[1][4][1][1] ~= nil then
						effectButton = finalCutProEffectsTransitionsBrowserGroup[1][4][1][1]
					end
				end
			end
		end

		--------------------------------------------------------------------------------
		-- If Needed, Search Again Without Text Before First Dash:
		--------------------------------------------------------------------------------
		if effectButton == nil then

			--------------------------------------------------------------------------------
			-- Remove first dash:
			--------------------------------------------------------------------------------
			currentShortcut = string.sub(currentShortcut, string.find(currentShortcut, "-") + 2)

			writeToConsole("currentShortcut: " .. currentShortcut)

			--------------------------------------------------------------------------------
			-- Perform Search:
			--------------------------------------------------------------------------------
			if finalCutProEffectsTransitionsBrowserGroup[4] ~= nil then effectsSearchField = finalCutProEffectsTransitionsBrowserGroup[4] end
			if effectsSearchField ~= nil then
				effectsSearchField:setAttributeValue("AXValue", currentShortcut)
				effectsSearchField[1]:performAction("AXPress")
			else
				dialog.displayErrorMessage("Unable to type search request in search box.\n\nError occured in effectsShortcut().")
				showTouchbar()
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Get First Item in Browser:
			--------------------------------------------------------------------------------
			if finalCutProEffectsTransitionsBrowserGroup[1] ~= nil then
				if finalCutProEffectsTransitionsBrowserGroup[1][4] ~= nil then
					if finalCutProEffectsTransitionsBrowserGroup[1][4][1] ~= nil then
						if finalCutProEffectsTransitionsBrowserGroup[1][4][1][1] ~= nil then
							effectButton = finalCutProEffectsTransitionsBrowserGroup[1][4][1][1]
						end
					end
				end
			end

		end

		--------------------------------------------------------------------------------
		-- Get First Item in Browser:
		--------------------------------------------------------------------------------
		if effectButton ~= nil then

			--------------------------------------------------------------------------------
			-- Original Mouse Position:
			--------------------------------------------------------------------------------
			local originalMousePosition = mouse.getAbsolutePosition()

			--------------------------------------------------------------------------------
			-- Get centre of button:
			--------------------------------------------------------------------------------
			local effectButtonPosition = {}
			effectButtonPosition['x'] = effectButton:attributeValue("AXPosition")['x'] + (effectButton:attributeValue("AXSize")['w'] / 2)
			effectButtonPosition['y'] = effectButton:attributeValue("AXPosition")['y'] + (effectButton:attributeValue("AXSize")['h'] / 2)

			--------------------------------------------------------------------------------
			-- Double Click:
			--------------------------------------------------------------------------------
			tools.doubleLeftClick(effectButtonPosition)

			--------------------------------------------------------------------------------
			-- Put it back:
			--------------------------------------------------------------------------------
			mouse.setAbsolutePosition(originalMousePosition)

		else
			dialog.displayErrorMessage("Unable to locate effect.\n\nError occured in effectsShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Add a bit of a delay:
		--------------------------------------------------------------------------------
		timer.doAfter(0.1, function()

			--------------------------------------------------------------------------------
			-- Make sure there's nothing in the search box:
			--------------------------------------------------------------------------------
			local effectsSearchCancelButton = nil
			if finalCutProEffectsTransitionsBrowserGroup[4] ~= nil then
				if finalCutProEffectsTransitionsBrowserGroup[4][2] ~= nil then
					effectsSearchCancelButton = finalCutProEffectsTransitionsBrowserGroup[4][2]
				end
			end
			if effectsSearchCancelButton ~= nil then
				effectsSearchCancelButtonResult = effectsSearchCancelButton:performAction("AXPress")
				if effectsSearchCancelButtonResult == nil then
					dialog.displayErrorMessage("Unable to cancel effects search.\n\nError occured in effectsShortcut().")
					showTouchbar()
					return "Fail"
				end
			end

			--------------------------------------------------------------------------------
			-- Restore Effects or Transitions Panel:
			--------------------------------------------------------------------------------
			if whichPanelActivated == "None" then
				finalCutProTimelineButtonBar[whichRadioGroup][1]:performAction("AXPress")
			elseif whichPanelActivated == "Transitions" then
				finalCutProTimelineButtonBar[whichRadioGroup][2]:performAction("AXPress")
			end

			--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			showTouchbar()

		end)

	end

	--------------------------------------------------------------------------------
	-- TITLES SHORTCUT PRESSED:
	--------------------------------------------------------------------------------
	function titlesShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Hide the Touch Bar:
		--------------------------------------------------------------------------------
		hideTouchbar()

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local currentShortcut = nil
		if whichShortcut == 1 then
			currentShortcut = settings.get("fcpxHacks.titlesShortcutOne")
		elseif whichShortcut == 2 then
			currentShortcut = settings.get("fcpxHacks.titlesShortcutTwo")
		elseif whichShortcut == 3 then
			currentShortcut = settings.get("fcpxHacks.titlesShortcutThree")
		elseif whichShortcut == 4 then
			currentShortcut = settings.get("fcpxHacks.titlesShortcutFour")
		elseif whichShortcut == 5 then
			currentShortcut = settings.get("fcpxHacks.titlesShortcutFive")
		else
			if tostring(whichShortcut) ~= "" then
				currentShortcut = tostring(whichShortcut)
			end
		end

		if currentShortcut == nil then
			dialog.displayMessage(i18n("noTitleShortcut"))
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get Browser Button Bar:
		--------------------------------------------------------------------------------
		local finalCutProBrowserButtonBar = fcp.getBrowserButtonBar()
		if finalCutProBrowserButtonBar == nil then
			dialog.displayErrorMessage("Unable to detect Browser Button Bar.\n\nError occured in titlesShortcut() whilst using fcp.getBrowserButtonBar().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get Button IDs:
		--------------------------------------------------------------------------------
		local libariesButtonID = nil
		local photosAudioButtonID = nil
		local titlesGeneratorsButtonID = nil
		local checkBoxCount = 1
		local whichBrowserPanelWasOpen = nil
		for i=1, finalCutProBrowserButtonBar:attributeValueCount("AXChildren") do
			if finalCutProBrowserButtonBar[i]:attributeValue("AXRole") == "AXCheckBox" then

				if finalCutProBrowserButtonBar[i]:attributeValue("AXValue") == 1 then
					if checkBoxCount == 3 then whichBrowserPanelWasOpen = "Library" end
					if checkBoxCount == 2 then whichBrowserPanelWasOpen = "PhotosAndAudio" end
					if checkBoxCount == 1 then whichBrowserPanelWasOpen = "TitlesAndGenerators" end
				end
				if checkBoxCount == 3 then libariesButtonID = i end
				if checkBoxCount == 2 then photosAudioButtonID = i end
				if checkBoxCount == 1 then titlesGeneratorsButtonID = i end
				checkBoxCount = checkBoxCount + 1

			end
		end
		if libariesButtonID == nil or photosAudioButtonID == nil or titlesGeneratorsButtonID == nil then
			dialog.displayErrorMessage("Unable to detect Browser Buttons.\n\nError occured in titlesShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Which Browser Panel is Open?
		--------------------------------------------------------------------------------
		local whichBrowserPanelWasOpen = nil
		if finalCutProBrowserButtonBar[libariesButtonID]:attributeValue("AXValue") == 1 then whichBrowserPanelWasOpen = "Library" end
		if finalCutProBrowserButtonBar[photosAudioButtonID]:attributeValue("AXValue") == 1 then whichBrowserPanelWasOpen = "PhotosAndAudio" end
		if finalCutProBrowserButtonBar[titlesGeneratorsButtonID]:attributeValue("AXValue") == 1 then whichBrowserPanelWasOpen = "TitlesAndGenerators" end

		--------------------------------------------------------------------------------
		-- If Titles & Generators is Closed, let's open it:
		--------------------------------------------------------------------------------
		if whichBrowserPanelWasOpen ~= "TitlesAndGenerators" then
			result = finalCutProBrowserButtonBar[titlesGeneratorsButtonID]:performAction("AXPress")
			if result == nil then
				dialog.displayErrorMessage("Unable to press Titles/Generator Button.\n\nError occured in titlesShortcut().")
				showTouchbar()
				return "Fail"
			end
		end

		--------------------------------------------------------------------------------
		-- Which Split Group?
		--------------------------------------------------------------------------------
		local titlesGeneratorsSplitGroup = nil
		for i=1, finalCutProBrowserButtonBar:attributeValueCount("AXChildren") do
			if finalCutProBrowserButtonBar[i]:attributeValue("AXRole") == "AXSplitGroup" then
				titlesGeneratorsSplitGroup = i
				goto titlesGeneratorsSplitGroupExit
			end
		end
		::titlesGeneratorsSplitGroupExit::
		if titlesGeneratorsSplitGroup == nil then
			dialog.displayErrorMessage("Unable to find Titles/Generators Split Group.\n\nError occured in titlesShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Is the Side Bar Closed?
		--------------------------------------------------------------------------------
		local titlesGeneratorsSideBarClosed = true
		if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][1] ~= nil then
			if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][1][1] ~= nil then
				if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][1][1][1] ~= nil then
					titlesGeneratorsSideBarClosed = false
				end
			end
		end
		if titlesGeneratorsSideBarClosed then
			result = finalCutProBrowserButtonBar[titlesGeneratorsButtonID]:performAction("AXPress")
			if result == nil then
				dialog.displayErrorMessage("Unable to press Titles/Generator Button.\n\nError occured in titlesShortcut().")
				showTouchbar()
				return "Fail"
			end
		end

		--------------------------------------------------------------------------------
		-- Make sure Titles is selected:
		--------------------------------------------------------------------------------
		local result = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][1][1][1]:setAttributeValue("AXSelected", true)
		if result == nil then
			dialog.displayErrorMessage("Unable to select Titles from List.\n\nError occured in titlesShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get Titles/Generators Popup Button:
		--------------------------------------------------------------------------------
		local titlesPopupButton = nil
		for i=1, finalCutProBrowserButtonBar:attributeValueCount("AXChildren") do
			if finalCutProBrowserButtonBar[i]:attributeValue("AXRole") == "AXPopUpButton" then
				--if finalCutProBrowserButtonBar[i]:attributeValue("AXIdentifier") == "_NS:46" then
					titlesPopupButton = i
					goto titlesGeneratorsDropdownExit
				--end
			end
		end
		if titlesPopupButton == nil then
			dialog.displayErrorMessage("Unable to detect Titles/Generators Popup Button.\n\nError occured in titlesShortcut().")
			showTouchbar()
			return "Fail"
		end
		::titlesGeneratorsDropdownExit::

		--------------------------------------------------------------------------------
		-- Make sure Titles/Generators Popup Button is set to Installed Titles:
		--------------------------------------------------------------------------------
		if finalCutProBrowserButtonBar[titlesPopupButton]:attributeValue("AXValue") ~= "Installed Titles" then
			local result = finalCutProBrowserButtonBar[titlesPopupButton]:performAction("AXPress")
			if result == nil then
				dialog.displayErrorMessage("Unable to press Titles/Generators Popup Button.\n\nError occured in titlesShortcut().")
				showTouchbar()
				return "Fail"
			end

			local result = finalCutProBrowserButtonBar[titlesPopupButton][1][1]:performAction("AXPress")
			if result == nil then
				dialog.displayErrorMessage("Unable to press First Popup Item.\n\nError occured in titlesShortcut().")
				showTouchbar()
				return "Fail"
			end
		end

		--------------------------------------------------------------------------------
		-- Add a bit of a delay...
		--------------------------------------------------------------------------------
		timer.usleep(100000)

		--------------------------------------------------------------------------------
		-- Get Titles/Generators Group:
		--------------------------------------------------------------------------------
		local titlesGeneratorsGroup = nil
		for i=1, finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup]:attributeValueCount("AXChildren") do
			if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][i]:attributeValue("AXRole") == "AXGroup" then
				if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][i][1] ~= nil then
					if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][i][1]:attributeValue("AXRole") == "AXScrollArea" then
						--if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][i][1]:attributeValue("AXIdentifier") == "_NS:9" then
							titlesGeneratorsGroup = i
							goto titlesGeneratorsGroupExit
						--end
					end
				end
			end
		end
		if titlesGeneratorsGroup == nil then
			dialog.displayErrorMessage("Unable to detect Titles/Generators Group.\n\nError occured in titlesShortcut().")
			showTouchbar()
			return "Fail"
		end
		::titlesGeneratorsGroupExit::

		--------------------------------------------------------------------------------
		-- Enter text into Search box:
		--------------------------------------------------------------------------------
		local result = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][3]:setAttributeValue("AXValue", currentShortcut)
		if result == nil then
			dialog.displayErrorMessage("Unable to enter search value.\n\nError occured in titlesShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Trigger Search:
		--------------------------------------------------------------------------------
		local result = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][3][1]:performAction("AXPress")
		if result == nil then
			dialog.displayErrorMessage("Unable to press Search Button.\n\nError occured in titlesShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get Selected Title:
		--------------------------------------------------------------------------------
		local selectedTitle = nil
		if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup] ~= nil then
			if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1] ~= nil then
				if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1][1] ~= nil then
					if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1][1][1] ~= nil then
						selectedTitle = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1][1][1]
					end
				end
			end
		end

		--------------------------------------------------------------------------------
		-- If Needed, Search Again Without Text Before First Dash:
		--------------------------------------------------------------------------------
		if selectedTitle == nil then

			--------------------------------------------------------------------------------
			-- Remove first dash:
			--------------------------------------------------------------------------------
			currentShortcut = string.sub(currentShortcut, string.find(currentShortcut, "-") + 2)

			--------------------------------------------------------------------------------
			-- Enter text into Search box:
			--------------------------------------------------------------------------------
			local result = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][3]:setAttributeValue("AXValue", currentShortcut)
			if result == nil then
				dialog.displayErrorMessage("Unable to enter search value.\n\nError occured in titlesShortcut().")
				showTouchbar()
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Trigger Search:
			--------------------------------------------------------------------------------
			local result = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][3][1]:performAction("AXPress")
			if result == nil then
				dialog.displayErrorMessage("Unable to press Search Button.\n\nError occured in titlesShortcut().")
				showTouchbar()
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Get Selected Title:
			--------------------------------------------------------------------------------
			if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup] ~= nil then
				if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1] ~= nil then
					if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1][1] ~= nil then
						if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1][1][1] ~= nil then
							selectedTitle = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1][1][1]
						end
					end
				end
			end

		end

		--------------------------------------------------------------------------------
		-- Click First Item in Browser:
		--------------------------------------------------------------------------------
		if selectedTitle ~= nil then

			--------------------------------------------------------------------------------
			-- Original Mouse Position:
			--------------------------------------------------------------------------------
			local originalMousePosition = mouse.getAbsolutePosition()

			--------------------------------------------------------------------------------
			-- Get centre of button:
			--------------------------------------------------------------------------------
			local selectedTitlePosition = {}
			selectedTitlePosition['x'] = selectedTitle:attributeValue("AXPosition")['x'] + (selectedTitle:attributeValue("AXSize")['w'] / 2)
			selectedTitlePosition['y'] = selectedTitle:attributeValue("AXPosition")['y'] + (selectedTitle:attributeValue("AXSize")['h'] / 2)

			--------------------------------------------------------------------------------
			-- Double Click:
			--------------------------------------------------------------------------------
			tools.doubleLeftClick(selectedTitlePosition)

			--------------------------------------------------------------------------------
			-- Put it back:
			--------------------------------------------------------------------------------
			mouse.setAbsolutePosition(originalMousePosition)

		else
			dialog.displayErrorMessage("Unable to locate Title.\n\nError occured in titlesShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Add a bit of a delay:
		--------------------------------------------------------------------------------
		timer.doAfter(0.1, function()

			--------------------------------------------------------------------------------
			-- Make sure there's nothing in the search box:
			--------------------------------------------------------------------------------
			local result = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][3][2]:performAction("AXPress")
			if result == nil then
				dialog.displayErrorMessage("Unable to press Cancel Search Button.\n\nError occured in titlesShortcut().")
				showTouchbar()
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Get Button IDs Again:
			--------------------------------------------------------------------------------
			local checkBoxCount = 1
			for i=1, finalCutProBrowserButtonBar:attributeValueCount("AXChildren") do
				if finalCutProBrowserButtonBar[i]:attributeValue("AXRole") == "AXCheckBox" then
					if checkBoxCount == 3 then libariesButtonID = i end
					if checkBoxCount == 2 then photosAudioButtonID = i end
					if checkBoxCount == 1 then titlesGeneratorsButtonID = i end
					checkBoxCount = checkBoxCount + 1
				end
			end
			if libariesButtonID == nil or photosAudioButtonID == nil or titlesGeneratorsButtonID == nil then
				dialog.displayErrorMessage("Unable to detect Browser Buttons.\n\nError occured in titlesShortcut().")
				showTouchbar()
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Go back to previously selected panel:
			--------------------------------------------------------------------------------
			if whichBrowserPanelWasOpen == "Library" then
				local result = finalCutProBrowserButtonBar[libariesButtonID]:performAction("AXPress")
				if result == nil then
					dialog.displayErrorMessage("Unable to press Libraries Button.\n\nError occured in titlesShortcut().")
					showTouchbar()
					return "Fail"
				end
			end
			if whichBrowserPanelWasOpen == "PhotosAndAudio" then
				local result = finalCutProBrowserButtonBar[photosAudioButtonID]:performAction("AXPress")
				if result == nil then
					dialog.displayErrorMessage("Unable to press Photos & Audio Button.\n\nError occured in titlesShortcut().")
					showTouchbar()
					return "Fail"
				end
			end
			if titlesGeneratorsSideBarClosed then
				local result = finalCutProBrowserButtonBar[titlesGeneratorsButtonID]:performAction("AXPress")
				if result == nil then
					dialog.displayErrorMessage("Unable to press Titles/Generator Button.\n\nError occured in titlesShortcut().")
					showTouchbar()
					return "Fail"
				end
			end

			--------------------------------------------------------------------------------
			-- Restore Touch Bar:
			--------------------------------------------------------------------------------
			showTouchbar()
		end)

	end

	--------------------------------------------------------------------------------
	-- GENERATORS SHORTCUT PRESSED:
	--------------------------------------------------------------------------------
	function generatorsShortcut(whichShortcut)

		--------------------------------------------------------------------------------
		-- Hide the Touch Bar:
		--------------------------------------------------------------------------------
		hideTouchbar()

		--------------------------------------------------------------------------------
		-- Get settings:
		--------------------------------------------------------------------------------
		local currentShortcut = nil
		if whichShortcut == 1 then
			currentShortcut = settings.get("fcpxHacks.generatorsShortcutOne")
		elseif whichShortcut == 2 then
			currentShortcut = settings.get("fcpxHacks.generatorsShortcutTwo")
		elseif whichShortcut == 3 then
			currentShortcut = settings.get("fcpxHacks.generatorsShortcutThree")
		elseif whichShortcut == 4 then
			currentShortcut = settings.get("fcpxHacks.generatorsShortcutFour")
		elseif whichShortcut == 5 then
			currentShortcut = settings.get("fcpxHacks.generatorsShortcutFive")
		else
			if tostring(whichShortcut) ~= "" then
				currentShortcut = tostring(whichShortcut)
			end
		end

		if currentShortcut == nil then
			dialog.displayMessage(i18n("noGeneratorShortcut"))
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get Browser Button Bar:
		--------------------------------------------------------------------------------
		local finalCutProBrowserButtonBar = fcp.getBrowserButtonBar()
		if finalCutProBrowserButtonBar == nil then
			dialog.displayErrorMessage("Unable to detect Browser Button Bar.\n\nError occured in generatorsShortcut() whilst using fcp.getBrowserButtonBar().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get Button IDs:
		--------------------------------------------------------------------------------
		local libariesButtonID = nil
		local photosAudioButtonID = nil
		local titlesGeneratorsButtonID = nil
		local checkBoxCount = 1
		local whichBrowserPanelWasOpen = nil
		for i=1, finalCutProBrowserButtonBar:attributeValueCount("AXChildren") do
			if finalCutProBrowserButtonBar[i]:attributeValue("AXRole") == "AXCheckBox" then

				if finalCutProBrowserButtonBar[i]:attributeValue("AXValue") == 1 then
					if checkBoxCount == 3 then whichBrowserPanelWasOpen = "Library" end
					if checkBoxCount == 2 then whichBrowserPanelWasOpen = "PhotosAndAudio" end
					if checkBoxCount == 1 then whichBrowserPanelWasOpen = "TitlesAndGenerators" end
				end
				if checkBoxCount == 3 then libariesButtonID = i end
				if checkBoxCount == 2 then photosAudioButtonID = i end
				if checkBoxCount == 1 then titlesGeneratorsButtonID = i end
				checkBoxCount = checkBoxCount + 1

			end
		end
		if libariesButtonID == nil or photosAudioButtonID == nil or titlesGeneratorsButtonID == nil then
			dialog.displayErrorMessage("Unable to detect Browser Buttons.\n\nError occured in generatorsShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Which Browser Panel is Open?
		--------------------------------------------------------------------------------
		local whichBrowserPanelWasOpen = nil
		if finalCutProBrowserButtonBar[libariesButtonID]:attributeValue("AXValue") == 1 then whichBrowserPanelWasOpen = "Library" end
		if finalCutProBrowserButtonBar[photosAudioButtonID]:attributeValue("AXValue") == 1 then whichBrowserPanelWasOpen = "PhotosAndAudio" end
		if finalCutProBrowserButtonBar[titlesGeneratorsButtonID]:attributeValue("AXValue") == 1 then whichBrowserPanelWasOpen = "TitlesAndGenerators" end

		--------------------------------------------------------------------------------
		-- If Titles & Generators is Closed, let's open it:
		--------------------------------------------------------------------------------
		if whichBrowserPanelWasOpen ~= "TitlesAndGenerators" then
			result = finalCutProBrowserButtonBar[titlesGeneratorsButtonID]:performAction("AXPress")
			if result == nil then
				dialog.displayErrorMessage("Unable to press Titles/Generator Button.\n\nError occured in generatorsShortcut().")
				showTouchbar()
				return "Fail"
			end
		end

		--------------------------------------------------------------------------------
		-- Which Split Group?
		--------------------------------------------------------------------------------
		local titlesGeneratorsSplitGroup = nil
		for i=1, finalCutProBrowserButtonBar:attributeValueCount("AXChildren") do
			if finalCutProBrowserButtonBar[i]:attributeValue("AXRole") == "AXSplitGroup" then
				titlesGeneratorsSplitGroup = i
				goto titlesGeneratorsSplitGroupExit
			end
		end
		::titlesGeneratorsSplitGroupExit::
		if titlesGeneratorsSplitGroup == nil then
			dialog.displayErrorMessage("Unable to find Titles/Generators Split Group.\n\nError occured in generatorsShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Is the Side Bar Closed?
		--------------------------------------------------------------------------------
		local titlesGeneratorsSideBarClosed = true
		if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][1] ~= nil then
			if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][1][1] ~= nil then
				if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][1][1][1] ~= nil then
					titlesGeneratorsSideBarClosed = false
				end
			end
		end
		if titlesGeneratorsSideBarClosed then
			result = finalCutProBrowserButtonBar[titlesGeneratorsButtonID]:performAction("AXPress")
			if result == nil then
				dialog.displayErrorMessage("Unable to press Titles/Generator Button.\n\nError occured in generatorsShortcut().")
				showTouchbar()
				return "Fail"
			end
		end

		--------------------------------------------------------------------------------
		-- Find Generators Row:
		--------------------------------------------------------------------------------
		local generatorsRow = nil
		local foundTitles = false
		for i=1, finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][1][1]:attributeValueCount("AXChildren") do
			if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][1][1][i][1]:attributeValue("AXRole") == "AXGroup" then
				if foundTitles == false then
					foundTitles = true
				else
					generatorsRow = i
					goto generatorsRowExit
				end
			end
		end
		::generatorsRowExit::
		if generatorsRow == nil then
			dialog.displayErrorMessage("Unable to find Generators Row.\n\nError occured in generatorsShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Select Generators Row:
		--------------------------------------------------------------------------------
		local result = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][1][1][generatorsRow]:setAttributeValue("AXSelected", true)
		if result == nil then
			dialog.displayErrorMessage("Unable to select Generators from Sidebar.\n\nError occured in generatorsShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get Titles/Generators Popup Button:
		--------------------------------------------------------------------------------
		local titlesPopupButton = nil
		for i=1, finalCutProBrowserButtonBar:attributeValueCount("AXChildren") do
			if finalCutProBrowserButtonBar[i]:attributeValue("AXRole") == "AXPopUpButton" then
				if finalCutProBrowserButtonBar[i]:attributeValue("AXIdentifier") == "_NS:46" then
					titlesPopupButton = i
					goto titlesGeneratorsDropdownExit
				end
			end
		end
		if titlesPopupButton == nil then
			dialog.displayErrorMessage("Unable to detect Titles/Generators Popup Button.\n\nError occured in generatorsShortcut().")
			showTouchbar()
			return "Fail"
		end
		::titlesGeneratorsDropdownExit::

		--------------------------------------------------------------------------------
		-- Make sure Titles/Generators Popup Button is set to Installed Titles:
		--------------------------------------------------------------------------------
		if finalCutProBrowserButtonBar[titlesPopupButton]:attributeValue("AXValue") ~= "Installed Titles" then
			local result = finalCutProBrowserButtonBar[titlesPopupButton]:performAction("AXPress")
			if result == nil then
				dialog.displayErrorMessage("Unable to press Titles/Generators Popup Button.\n\nError occured in generatorsShortcut().")
				showTouchbar()
				return "Fail"
			end

			local result = finalCutProBrowserButtonBar[titlesPopupButton][1][1]:performAction("AXPress")
			if result == nil then
				dialog.displayErrorMessage("Unable to press First Popup Item.\n\nError occured in generatorsShortcut().")
				showTouchbar()
				return "Fail"
			end
		end

		--------------------------------------------------------------------------------
		-- Add a bit of a delay...
		--------------------------------------------------------------------------------
		timer.usleep(100000)

		--------------------------------------------------------------------------------
		-- Get Titles/Generators Group:
		--------------------------------------------------------------------------------
		local titlesGeneratorsGroup = nil
		for i=1, finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup]:attributeValueCount("AXChildren") do
			if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][i]:attributeValue("AXRole") == "AXGroup" then
				if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][i][1] ~= nil then
					if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][i][1]:attributeValue("AXRole") == "AXScrollArea" then
						if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][i][1]:attributeValue("AXIdentifier") == "_NS:9" then
							titlesGeneratorsGroup = i
							goto titlesGeneratorsGroupExit
						end
					end
				end
			end
		end
		if titlesGeneratorsGroup == nil then
			dialog.displayErrorMessage("Unable to detect Titles/Generators Group.\n\nError occured in generatorsShortcut().")
			showTouchbar()
			return "Fail"
		end
		::titlesGeneratorsGroupExit::

		--------------------------------------------------------------------------------
		-- Enter text into Search box:
		--------------------------------------------------------------------------------
		local result = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][3]:setAttributeValue("AXValue", currentShortcut)
		if result == nil then
			dialog.displayErrorMessage("Unable to enter search value.\n\nError occured in generatorsShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Trigger Search:
		--------------------------------------------------------------------------------
		local result = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][3][1]:performAction("AXPress")
		if result == nil then
			dialog.displayErrorMessage("Unable to press Search Button.\n\nError occured in generatorsShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get Selected Title:
		--------------------------------------------------------------------------------
		local selectedTitle = nil
		if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup] ~= nil then
			if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1] ~= nil then
				if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1][1] ~= nil then
					if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1][1][1] ~= nil then
						selectedTitle = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1][1][1]
					end
				end
			end
		end

		--------------------------------------------------------------------------------
		-- If Needed, Search Again Without Text Before First Dash:
		--------------------------------------------------------------------------------
		if selectedTitle == nil then

			--------------------------------------------------------------------------------
			-- Remove first dash:
			--------------------------------------------------------------------------------
			currentShortcut = string.sub(currentShortcut, string.find(currentShortcut, "-") + 2)

			--------------------------------------------------------------------------------
			-- Enter text into Search box:
			--------------------------------------------------------------------------------
			local result = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][3]:setAttributeValue("AXValue", currentShortcut)
			if result == nil then
				dialog.displayErrorMessage("Unable to enter search value.\n\nError occured in generatorsShortcut().")
				showTouchbar()
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Trigger Search:
			--------------------------------------------------------------------------------
			local result = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][3][1]:performAction("AXPress")
			if result == nil then
				dialog.displayErrorMessage("Unable to press Search Button.\n\nError occured in generatorsShortcut().")
				showTouchbar()
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Get Selected Title:
			--------------------------------------------------------------------------------
			if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup] ~= nil then
				if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1] ~= nil then
					if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1][1] ~= nil then
						if finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1][1][1] ~= nil then
							selectedTitle = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][titlesGeneratorsGroup][1][1][1]
						end
					end
				end
			end

		end

		--------------------------------------------------------------------------------
		-- Click First Item in Browser:
		--------------------------------------------------------------------------------
		if selectedTitle ~= nil then

			--------------------------------------------------------------------------------
			-- Original Mouse Position:
			--------------------------------------------------------------------------------
			local originalMousePosition = mouse.getAbsolutePosition()

			--------------------------------------------------------------------------------
			-- Get centre of button:
			--------------------------------------------------------------------------------
			local selectedTitlePosition = {}
			selectedTitlePosition['x'] = selectedTitle:attributeValue("AXPosition")['x'] + (selectedTitle:attributeValue("AXSize")['w'] / 2)
			selectedTitlePosition['y'] = selectedTitle:attributeValue("AXPosition")['y'] + (selectedTitle:attributeValue("AXSize")['h'] / 2)

			--------------------------------------------------------------------------------
			-- Double Click:
			--------------------------------------------------------------------------------
			tools.doubleLeftClick(selectedTitlePosition)

			--------------------------------------------------------------------------------
			-- Put it back:
			--------------------------------------------------------------------------------
			mouse.setAbsolutePosition(originalMousePosition)

		else
			dialog.displayErrorMessage("Unable to locate Generator.\n\nError occured in generatorsShortcut().")
			showTouchbar()
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Add a bit of a delay:
		--------------------------------------------------------------------------------
		timer.doAfter(0.1, function()

			--------------------------------------------------------------------------------
			-- Make sure there's nothing in the search box:
			--------------------------------------------------------------------------------
			local result = finalCutProBrowserButtonBar[titlesGeneratorsSplitGroup][3][2]:performAction("AXPress")
			if result == nil then
				dialog.displayErrorMessage("Unable to press Cancel Search Button.\n\nError occured in generatorsShortcut().")
				showTouchbar()
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Get Button IDs Again:
			--------------------------------------------------------------------------------
			local checkBoxCount = 1
			for i=1, finalCutProBrowserButtonBar:attributeValueCount("AXChildren") do
				if finalCutProBrowserButtonBar[i]:attributeValue("AXRole") == "AXCheckBox" then
					if checkBoxCount == 3 then libariesButtonID = i end
					if checkBoxCount == 2 then photosAudioButtonID = i end
					if checkBoxCount == 1 then titlesGeneratorsButtonID = i end
					checkBoxCount = checkBoxCount + 1
				end
			end
			if libariesButtonID == nil or photosAudioButtonID == nil or titlesGeneratorsButtonID == nil then
				dialog.displayErrorMessage("Unable to detect Browser Buttons.\n\nError occured in generatorsShortcut().")
				showTouchbar()
				return "Fail"
			end

			--------------------------------------------------------------------------------
			-- Go back to previously selected panel:
			--------------------------------------------------------------------------------
			if whichBrowserPanelWasOpen == "Library" then
				local result = finalCutProBrowserButtonBar[libariesButtonID]:performAction("AXPress")
				if result == nil then
					dialog.displayErrorMessage("Unable to press Libraries Button.\n\nError occured in generatorsShortcut().")
					showTouchbar()
					return "Fail"
				end
			end
			if whichBrowserPanelWasOpen == "PhotosAndAudio" then
				local result = finalCutProBrowserButtonBar[photosAudioButtonID]:performAction("AXPress")
				if result == nil then
					dialog.displayErrorMessage("Unable to press Photos & Audio Button.\n\nError occured in generatorsShortcut().")
					showTouchbar()
					return "Fail"
				end
			end
			if titlesGeneratorsSideBarClosed then
				local result = finalCutProBrowserButtonBar[titlesGeneratorsButtonID]:performAction("AXPress")
				if result == nil then
					dialog.displayErrorMessage("Unable to press Titles/Generator Button.\n\nError occured in generatorsShortcut().")
					showTouchbar()
					return "Fail"
				end
			end

			--------------------------------------------------------------------------------
			-- Restore Touch Bar:
			--------------------------------------------------------------------------------
			showTouchbar()
		end)

	end

--------------------------------------------------------------------------------
-- OTHER SHORTCUTS:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- CHANGE TIMELINE CLIP HEIGHT:
	--------------------------------------------------------------------------------
	function changeTimelineClipHeight(direction)

		--------------------------------------------------------------------------------
		-- Prevent multiple keypresses:
		--------------------------------------------------------------------------------
		if changeTimelineClipHeightAlreadyInProgress then return end
		changeTimelineClipHeightAlreadyInProgress = true

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		--------------------------------------------------------------------------------
		-- Get Timeline Button Bar:
		--------------------------------------------------------------------------------
		timelineButtonBar = fcp.getTimelineButtonBar()
		if timelineButtonBar == nil then
			displayErrorMessage("Unable to locate the Timeline Button Bar.\n\nError Occurred in changeTimelineClipHeight().")
			return
		end

		--------------------------------------------------------------------------------
		-- Find the Timeline Appearance Button:
		--------------------------------------------------------------------------------
		timelineApperanceButtonID = nil
		for i=1, timelineButtonBar:attributeValueCount("AXChildren") do
			if timelineButtonBar[i]:attributeValue("AXIdentifier") == "_NS:154" then
				timelineApperanceButtonID = i
			end
		end
		if timelineApperanceButtonID == nil then
			displayErrorMessage("Unable to locate the Timeline Apperance Button.\n\nError Occurred in changeTimelineClipHeight().")
			return
		end

		--------------------------------------------------------------------------------
		-- Open Appearance Popup if not already open:
		--------------------------------------------------------------------------------
		if timelineButtonBar[timelineApperanceButtonID]:attributeValue("AXValue") == 0 then
			-- Appearance Popup Closed:
			local result = timelineButtonBar[timelineApperanceButtonID]:performAction("AXPress")
			if result == nil then
				displayErrorMessage("Unable to open the Timeline Apperance Popup.\n\nError Occurred in changeTimelineClipHeight().")
				return
			end
		end

		--------------------------------------------------------------------------------
		-- Change Value of Zoom Slider:
		--------------------------------------------------------------------------------
		local AXPopoverID = 1
		local AXSliderID = 8
		local AXValueIndicator = 1
		local value = 0

		if direction == "up" then value = 0.2 else value = -0.2 end

		if timelineButtonBar[timelineApperanceButtonID][AXPopoverID] ~= nil then
			local currentZoomValue = timelineButtonBar[timelineApperanceButtonID][AXPopoverID][AXSliderID][AXValueIndicator]:attributeValue("AXValue")
			timelineButtonBar[timelineApperanceButtonID][AXPopoverID][AXSliderID][AXValueIndicator]:setAttributeValue("AXValue", currentZoomValue + value)

			if changeTimelineClipHeightAlreadyInProgress then
				timer.doUntil(function() return not changeTimelineClipHeightAlreadyInProgress end, function()
					local currentZoomValue = timelineButtonBar[timelineApperanceButtonID][AXPopoverID][AXSliderID][AXValueIndicator]:attributeValue("AXValue")
					timelineButtonBar[timelineApperanceButtonID][AXPopoverID][AXSliderID][AXValueIndicator]:setAttributeValue("AXValue", currentZoomValue + value)
				end, eventtap.keyRepeatInterval())
			end
		end

	end

		--------------------------------------------------------------------------------
		-- CHANGE TIMELINE CLIP HEIGHT RELEASE:
		--------------------------------------------------------------------------------
		function changeTimelineClipHeightRelease()

			changeTimelineClipHeightAlreadyInProgress = false

			--------------------------------------------------------------------------------
			-- Close the popup via mouse (as GUI Scripting fails):
			--------------------------------------------------------------------------------
			local changeAppearanceButtonSize 			= timelineButtonBar[timelineApperanceButtonID]:attributeValue("AXSize")
			local changeAppearanceButtonPosition 		= timelineButtonBar[timelineApperanceButtonID]:attributeValue("AXPosition")
			local changeAppearanceButtonLocation 		= {}
			changeAppearanceButtonLocation['x'] 	= changeAppearanceButtonPosition['x'] + (changeAppearanceButtonSize['w'] / 2 )
			changeAppearanceButtonLocation['y'] 	= changeAppearanceButtonPosition['y'] + (changeAppearanceButtonSize['h'] / 2 )

			tools.ninjaMouseClick(changeAppearanceButtonLocation)

		end

	--------------------------------------------------------------------------------
	-- SELECT CLIP AT LANE:
	--------------------------------------------------------------------------------
	function selectClipAtLane(whichLane)
		local content = fcp:app():timeline():content()
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

		local fcpxElements = ax.applicationElement(fcp.application())

		local whichMenuBar = nil
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if fcpxElements[i]:attributeValue("AXRole") == "AXMenuBar" then
				whichMenuBar = i
			end
		end

		if whichMenuBar == nil then
			displayErrorMessage("Failed to find menu bar.\n\nError occured in menuItemShortcut().")
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
	-- TOGGLE TOUCH BAR:
	--------------------------------------------------------------------------------
	function toggleTouchBar()

		--------------------------------------------------------------------------------
		-- Check for compatibility:
		--------------------------------------------------------------------------------
		if not touchBarSupported then
			dialog.displayMessage(i18n("touchBarError"))
			return "Fail"
		end

		--------------------------------------------------------------------------------
		-- Get Settings:
		--------------------------------------------------------------------------------
		local displayTouchBar = settings.get("fcpxHacks.displayTouchBar") or false

		--------------------------------------------------------------------------------
		-- Toggle Touch Bar:
		--------------------------------------------------------------------------------
		setTouchBarLocation()
		if fcp.running() then
			mod.touchBarWindow:toggle()
		end

		--------------------------------------------------------------------------------
		-- Update Settings:
		--------------------------------------------------------------------------------
		settings.set("fcpxHacks.displayTouchBar", not displayTouchBar)

		--------------------------------------------------------------------------------
		-- Refresh Menubar:
		--------------------------------------------------------------------------------
		refreshMenuBar()

	end

	--------------------------------------------------------------------------------
	-- CUT AND SWITCH MULTI-CAM:
	--------------------------------------------------------------------------------
	function cutAndSwitchMulticam(whichMode, whichAngle)

		if whichMode == "Audio" then
			if not fcp.performShortcut("MultiAngleEditStyleAudio") then
				dialog.displayErrorMessage("We were unable to trigger the 'Cut/Switch Multicam Audio Only' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
				return "Failed"
			end
		end

		if whichMode == "Video" then
			if not fcp.performShortcut("MultiAngleEditStyleVideo") then
				dialog.displayErrorMessage("We were unable to trigger the 'Cut/Switch Multicam Video Only' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
				return "Failed"
			end
		end

		if whichMode == "Both" then
			if not fcp.performShortcut("MultiAngleEditStyleAudioVideo") then
				dialog.displayErrorMessage("We were unable to trigger the 'Cut/Switch Multicam Audio and Video' Shortcut.\n\nPlease make sure this shortcut is allocated in the Command Editor.\n\nError Occured in cutAndSwitchMulticam().")
				return "Failed"
			end
		end

		if not fcp.performShortcut("CutSwitchAngle" .. tostring(string.format("%02d", whichAngle))) then
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

		if not fcp.performShortcut("Cut") then
			dialog.displayErrorMessage("Failed to trigger the 'Cut' Shortcut.\n\nError occured in moveToPlayhead().")
			goto moveToPlayheadEnd
		end

		if not fcp.performShortcut("Paste") then
			dialog.displayErrorMessage("Failed to trigger the 'Paste' Shortcut.\n\nError occured in moveToPlayhead().")
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

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()


		--------------------------------------------------------------------------------
		-- Get Browser Persistent Playhead:
		--------------------------------------------------------------------------------
		local persistentPlayhead = fcp.getBrowserPersistentPlayhead()
		if persistentPlayhead ~= nil then

			--------------------------------------------------------------------------------
			-- Playhead Position:
			--------------------------------------------------------------------------------
			persistentPlayheadPosition = persistentPlayhead:attributeValue("AXPosition")
			persistentPlayheadSize = persistentPlayhead:attributeValue("AXSize")

			--------------------------------------------------------------------------------
			-- Highlight Mouse:
			--------------------------------------------------------------------------------
			mouseHighlight(persistentPlayheadPosition["x"], persistentPlayheadPosition["y"], persistentPlayheadSize["w"], persistentPlayheadSize["h"])

		end

	end

		--------------------------------------------------------------------------------
		-- HIGHLIGHT MOUSE IN FCPX:
		--------------------------------------------------------------------------------
		function mouseHighlight(mouseHighlightX, mouseHighlightY, mouseHighlightW, mouseHighlightH)

			--------------------------------------------------------------------------------
			-- Delete Previous Highlights:
			--------------------------------------------------------------------------------
			deleteAllHighlights()

			--------------------------------------------------------------------------------
			-- Get Sizing Preferences:
			--------------------------------------------------------------------------------
			local displayHighlightShape = nil
			displayHighlightShape = settings.get("fcpxHacks.displayHighlightShape")
			if displayHighlightShape == nil then displayHighlightShape = "Rectangle" end

			--------------------------------------------------------------------------------
			-- Get Highlight Colour Preferences:
			--------------------------------------------------------------------------------
			local displayHighlightColour = settings.get("fcpxHacks.displayHighlightColour") or "Red"
			if displayHighlightColour == "Red" then 	displayHighlightColour = {["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1} 	end
			if displayHighlightColour == "Blue" then 	displayHighlightColour = {["red"]=0,["blue"]=1,["green"]=0,["alpha"]=1}		end
			if displayHighlightColour == "Green" then 	displayHighlightColour = {["red"]=0,["blue"]=0,["green"]=1,["alpha"]=1}		end
			if displayHighlightColour == "Yellow" then 	displayHighlightColour = {["red"]=1,["blue"]=0,["green"]=1,["alpha"]=1}		end
			if displayHighlightColour == "Custom" then
				local displayHighlightCustomColour = settings.get("fcpxHacks.displayHighlightCustomColour")
				displayHighlightColour = {red=displayHighlightCustomColour["red"],blue=displayHighlightCustomColour["blue"],green=displayHighlightCustomColour["green"],alpha=1}
			end

			--------------------------------------------------------------------------------
			-- Highlight the FCPX Browser Playhead:
			--------------------------------------------------------------------------------
			if displayHighlightShape == "Rectangle" then
				mod.browserHighlight = drawing.rectangle(geometry.rect(mouseHighlightX, mouseHighlightY, mouseHighlightW, mouseHighlightH - 12))
				mod.browserHighlight:setStrokeColor(displayHighlightColour)
				mod.browserHighlight:setFill(false)
				mod.browserHighlight:setStrokeWidth(5)
				mod.browserHighlight:show()
			end
			if displayHighlightShape == "Circle" then
				mod.browserHighlight = drawing.circle(geometry.rect((mouseHighlightX-(mouseHighlightH/2)+10), mouseHighlightY, mouseHighlightH-12, mouseHighlightH-12))
				mod.browserHighlight:setStrokeColor(displayHighlightColour)
				mod.browserHighlight:setFill(false)
				mod.browserHighlight:setStrokeWidth(5)
				mod.browserHighlight:show()
			end
			if displayHighlightShape == "Diamond" then
				mod.browserHighlight = drawing.circle(geometry.rect(mouseHighlightX, mouseHighlightY, mouseHighlightW, mouseHighlightH - 12))
				mod.browserHighlight:setStrokeColor(displayHighlightColour)
				mod.browserHighlight:setFill(false)
				mod.browserHighlight:setStrokeWidth(5)
				mod.browserHighlight:show()
			end

			--------------------------------------------------------------------------------
			-- Set a timer to delete the circle after 3 seconds:
			--------------------------------------------------------------------------------
			mod.browserHighlightTimer = timer.doAfter(3, function() mod.browserHighlight:delete() end)

		end

	--------------------------------------------------------------------------------
	-- SELECT ALL TIMELINE CLIPS IN SPECIFIC DIRECTION:
	--------------------------------------------------------------------------------
	function selectAllTimelineClips(forwards)

		local content = fcp:app():timeline():content()
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
-- BATCH EXPORT:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- BATCH EXPORT FROM BROWSER:
	--------------------------------------------------------------------------------
	function batchExport()

		--------------------------------------------------------------------------------
		-- Set Custom Export Path (or Default to Desktop):
		--------------------------------------------------------------------------------
		local batchExportDestinationFolder = settings.get("fcpxHacks.batchExportDestinationFolder")
		local NSNavLastRootDirectory = fcp.getPreference("NSNavLastRootDirectory")
		local exportPath = "~/Desktop"
		if batchExportDestinationFolder ~= nil then
			 if tools.doesDirectoryExist(batchExportDestinationFolder) then
				exportPath = batchExportDestinationFolder
			 end
		else
			if tools.doesDirectoryExist(NSNavLastRootDirectory) then
				exportPath = NSNavLastRootDirectory
			end
		end

		--------------------------------------------------------------------------------
		-- Destination Preset:
		--------------------------------------------------------------------------------
		local destinationPreset = settings.get("fcpxHacks.batchExportDestinationPreset")
		if destinationPreset == nil then

			destinationPreset = fcp.app():menuBar():findMenuUI("File", "Share", function(menuItem)
				return menuItem:attributeValue("AXMenuItemCmdChar") ~= nil
			end):attributeValue("AXTitle")

			if destinationPreset == nil then
				displayErrorMessage(i18n("batchExportNoDestination"))
				return false
			else
				-- Remove (default) text:
				local firstBracket = string.find(destinationPreset, " %(", 1)
				if firstBracket == nil then
					firstBracket = string.find(destinationPreset, "（", 1)
				end
				destinationPreset = string.sub(destinationPreset, 1, firstBracket - 1)
			end

		end

		--------------------------------------------------------------------------------
		-- Delete All Highlights:
		--------------------------------------------------------------------------------
		deleteAllHighlights()

		local libraries = fcp.app():browser():libraries()

		if not libraries:isShowing() then
			dialog.displayErrorMessage(i18n("batchExportEnableBrowser"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Check if we have any currently-selected clips:
		--------------------------------------------------------------------------------
		local clips = libraries:selectedClipsUI()

		if libraries:sidebar():isFocused() then
			--------------------------------------------------------------------------------
			-- Use All Clips:
			--------------------------------------------------------------------------------
			clips = libraries:clipsUI()
		end

		local failedExports = 0

		if clips and #clips > 0 then

			--------------------------------------------------------------------------------
			-- Display Dialog to make sure the current path is acceptable:
			--------------------------------------------------------------------------------
			local countText = " "
			if #clips > 1 then countText = " " .. tostring(#clips) .. " " end
			local result = dialog.displayMessage(i18n("batchExportCheckPath", {count=countText, path=exportPath, preset=destinationPreset, item=i18n("item", {count=#clips})}), {i18n("buttonContinueBatchExport"), i18n("cancel")})
			if result == nil then return end

			--os.execute([[osascript -e 'tell app "Final Cut Pro" to display dialog "Hello World"']])

			--------------------------------------------------------------------------------
			-- Export the clips:
			--------------------------------------------------------------------------------
			failedExports = batchExportClips(libraries, clips, exportPath, destinationPreset)

		else
			--------------------------------------------------------------------------------
			-- No Clips are Available:
			--------------------------------------------------------------------------------
			dialog.displayErrorMessage(i18n("batchExportNoClipsSelected"))
		end

		--------------------------------------------------------------------------------
		-- Batch Export Complete:
		--------------------------------------------------------------------------------
		if failedExports >= 0 then
			local completeMessage = i18n("batchExportComplete")
			if failedExports > 0 then
				completeMessage = completeMessage .. "\n\n" .. i18n("batchExportSkipped", {count=failedExports})
			end
			dialog.displayMessage(completeMessage, {i18n("done")})
		end

	end

		--------------------------------------------------------------------------------
		-- BATCH EXPORT CLIPS:
		--------------------------------------------------------------------------------
		function batchExportClips(libraries, clips, exportPath, destinationPreset)

			local firstTime = true
			local batchExportReplaceExistingFiles = settings.get("fcpxHacks.batchExportReplaceExistingFiles")

			local failedExports = 0
			for i,clip in ipairs(clips) do

				--------------------------------------------------------------------------------
				-- Select Item:
				--------------------------------------------------------------------------------
				libraries:selectClip(clip)

				--------------------------------------------------------------------------------
				-- Trigger Export:
				--------------------------------------------------------------------------------
				if not selectShare(destinationPreset) then
					dialog.displayErrorMessage("Could not trigger Share Menu Item.")
					return -1
				end

				--------------------------------------------------------------------------------
				-- Wait for Export Dialog to open:
				--------------------------------------------------------------------------------
				local exportDialog = fcp.app():exportDialog()
				if not just.doUntil(function() return exportDialog:isShowing() end) then
					dialog.displayErrorMessage("Failed to open the 'Export' window.")
					return -2
				end
				exportDialog:pressNext()

				--------------------------------------------------------------------------------
				-- Click 'Save' on the save sheet:
				--------------------------------------------------------------------------------
				local saveSheet = exportDialog:saveSheet()
				if not just.doUntil(function() return saveSheet:isShowing() end) then
					dialog.displayErrorMessage("Failed to open the 'Save' window.")
					return -3
				end

				--------------------------------------------------------------------------------
				-- Set Custom Export Path (or Default to Desktop):
				--------------------------------------------------------------------------------
				if firstTime then
					saveSheet:setPath(exportPath)
					firstTime = false
				end
				saveSheet:pressSave()

				--------------------------------------------------------------------------------
				-- Make sure Save Window is closed:
				--------------------------------------------------------------------------------
				if saveSheet:isShowing() then
					local replaceAlert = saveSheet:replaceAlert()
					if batchExportReplaceExistingFiles and replaceAlert:isShowing() then
						replaceAlert:pressReplace()
					else
						replaceAlert:pressCancel()
						failedExports = failedExports + 1
					end
					saveSheet:pressCancel()
					exportDialog:pressCancel()
				end
			end
			return failedExports
		end

		--------------------------------------------------------------------------------
		-- Trigger Export:
		--------------------------------------------------------------------------------
		function selectShare(destinationPreset)
			return fcp.app():menuBar():selectMenu("File", "Share", function(menuItem)
				if destinationPreset == nil then
					return menuItem:attributeValue("AXMenuItemCmdChar") ~= nil
				else
					local title = menuItem:attributeValue("AXTitle")
					return title and string.find(title, destinationPreset) ~= nil
				end
			end)

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
		local mailer = sharing.newShare("com.apple.share.Mail.compose"):subject("[FCPX Hacks " .. fcpxhacks.scriptVersion .. "] Bug Report"):recipients({fcpxhacks.bugReportEmail})
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
		--------------------------------------------------------------------------------
		-- Delete FCPX Browser Highlight:
		--------------------------------------------------------------------------------
		if mod.browserHighlight then
			mod.browserHighlight:delete()
			if mod.browserHighlightTimer then
				mod.browserHighlightTimer:stop()
			end
		end
	end

	--------------------------------------------------------------------------------
	-- CHECK FOR FCPX HACKS UPDATES:
	--------------------------------------------------------------------------------
	function checkForUpdates()

		local enableCheckForUpdates = settings.get("fcpxHacks.enableCheckForUpdates")
		if enableCheckForUpdates then
			debugMessage("Checking for updates.")
			latestScriptVersion = nil
			updateResponse, updateBody, updateHeader = http.get(fcpxhacks.checkUpdateURL, nil)
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
						if latestScriptVersion > fcpxhacks.scriptVersion then
							updateNotification = notify.new(function() getScriptUpdate() end):setIdImage(image.imageFromPath(fcpxhacks.iconPath))
																:title("FCPX Hacks Update Available")
																:subTitle("Version " .. latestScriptVersion)
																:informativeText("Do you wish to install?")
																:hasActionButton(true)
																:actionButtonTitle("Install")
																:otherButtonTitle("Not Yet")
																:send()
							mod.shownUpdateNotification = true
						end
					end

					--------------------------------------------------------------------------------
					-- Refresh Menubar:
					--------------------------------------------------------------------------------
					refreshMenuBar()
				end
			end
		end

	end

--------------------------------------------------------------------------------
-- TOUCH BAR:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- SHOW TOUCH BAR:
	--------------------------------------------------------------------------------
	function showTouchbar()
		--------------------------------------------------------------------------------
		-- Check if we need to show the Touch Bar:
		--------------------------------------------------------------------------------
		if touchBarSupported then
			local displayTouchBar = settings.get("fcpxHacks.displayTouchBar") or false
			if displayTouchBar then mod.touchBarWindow:show() end
		end
	end

	--------------------------------------------------------------------------------
	-- HIDE TOUCH BAR:
	--------------------------------------------------------------------------------
	function hideTouchbar()
		--------------------------------------------------------------------------------
		-- Hide the Touch Bar:
		--------------------------------------------------------------------------------
		if touchBarSupported then mod.touchBarWindow:hide() end
	end

	--------------------------------------------------------------------------------
	-- SET TOUCH BAR LOCATION:
	--------------------------------------------------------------------------------
	function setTouchBarLocation()

		--------------------------------------------------------------------------------
		-- Get Settings:
		--------------------------------------------------------------------------------
		local displayTouchBarLocation = settings.get("fcpxHacks.displayTouchBarLocation") or "Mouse"

		--------------------------------------------------------------------------------
		-- Show Touch Bar at Top Centre of Timeline:
		--------------------------------------------------------------------------------
		if displayTouchBarLocation == "TimelineTopCentre" then

			--------------------------------------------------------------------------------
			-- Position Touch Bar to Top Centre of Final Cut Pro Timeline:
			--------------------------------------------------------------------------------
			local timelineScrollArea = fcp.getTimelineScrollArea()
			if timelineScrollArea == nil then
				displayTouchBarLocation = "Mouse"
			else
				local timelineScrollAreaPosition = {}
				timelineScrollAreaPosition['x'] = timelineScrollArea:attributeValue("AXPosition")['x'] + (timelineScrollArea:attributeValue("AXSize")['w'] / 2) - (mod.touchBarWindow:getFrame()['w'] / 2)
				timelineScrollAreaPosition['y'] = timelineScrollArea:attributeValue("AXPosition")['y'] + 20
				mod.touchBarWindow:topLeft(timelineScrollAreaPosition)
			end

		end

		--------------------------------------------------------------------------------
		-- Show Touch Bar at Mouse Pointer Position:
		--------------------------------------------------------------------------------
		if displayTouchBarLocation == "Mouse" then

			--------------------------------------------------------------------------------
			-- Position Touch Bar to Mouse Pointer Location:
			--------------------------------------------------------------------------------
			mod.touchBarWindow:atMousePosition()

		end

		--------------------------------------------------------------------------------
		-- Save last Touch Bar Location to Settings:
		--------------------------------------------------------------------------------
		settings.set("fcpxHacks.lastTouchBarLocation", mod.touchBarWindow:topLeft())

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
				local fcpx = fcp.application()
				local fcpxElements = ax.applicationElement(fcpx)
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
	fcp.app():commandEditor():watch({
		show = function(commandEditor)
			--------------------------------------------------------------------------------
			-- Disable Hotkeys:
			--------------------------------------------------------------------------------
			if hotkeys ~= nil then -- For the rare case when Command Editor is open on load.
				debugMessage("Disabling Hotkeys")
				hotkeys:exit()
			end
			--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Hide the Touch Bar:
			--------------------------------------------------------------------------------
			hideTouchbar()

			--------------------------------------------------------------------------------
			-- Hide the HUD:
			--------------------------------------------------------------------------------
			hackshud.hide()
		end,
		hide = function(commandEditor)
			--------------------------------------------------------------------------------
			-- Check if we need to show the Touch Bar:
			--------------------------------------------------------------------------------
			showTouchbar()
			--------------------------------------------------------------------------------

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

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window Moved:
	--------------------------------------------------------------------------------
	finalCutProWindowFilter = windowfilter.new{"Final Cut Pro"}

	finalCutProWindowFilter:subscribe(windowfilter.windowMoved, function()
		debugMessage("Final Cut Pro Window Resized")
		if touchBarSupported then
			local displayTouchBar = settings.get("fcpxHacks.displayTouchBar") or false
			if displayTouchBar then setTouchBarLocation() end
		end
	end, true)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window Not On Screen:
	--------------------------------------------------------------------------------
	finalCutProWindowFilter:subscribe(windowfilter.windowNotOnScreen, function()
		if not fcp.frontmost() then
			finalCutProNotActive()
		end
	end, true)

	--------------------------------------------------------------------------------
	-- Final Cut Pro Window On Screen:
	--------------------------------------------------------------------------------
	finalCutProWindowFilter:subscribe(windowfilter.windowOnScreen, function()
		finalCutProActive()
	end, true)

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
		-- Don't trigger until after FCPX Hacks has loaded:
		--------------------------------------------------------------------------------
		if not mod.hacksLoaded then
			mod.isFinalCutProActive = false
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
		-- Check if we need to show the Touch Bar:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			showTouchbar()
		end)

		--------------------------------------------------------------------------------
		-- Full Screen Keyboard Watcher:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			if settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") == true then
				fullscreenKeyboardWatcherUp:start()
				fullscreenKeyboardWatcherDown:start()
			end
		end)

		--------------------------------------------------------------------------------
		-- Enable Scrolling Timeline Watcher:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			if settings.get("fcpxHacks.scrollingTimelineActive") == true then
				if mod.scrollingTimelineWatcherDown ~= nil then
					mod.scrollingTimelineWatcherDown:start()
				end
			end
		end)

		--------------------------------------------------------------------------------
		-- Enable Lock Timeline Playhead:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			local lockTimelinePlayhead = settings.get("fcpxHacks.lockTimelinePlayhead") or false
			if lockTimelinePlayhead then
				fcp.app():timeline():lockPlayhead()
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
		-- Update Menubar:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			refreshMenuBar()
		end)

		--------------------------------------------------------------------------------
		-- Update Current Language:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function()
			fcp.currentLanguage(true)
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
		-- Don't trigger until after FCPX Hacks has loaded:
		--------------------------------------------------------------------------------
		if not mod.hacksLoaded then return end

		--------------------------------------------------------------------------------
		-- Full Screen Keyboard Watcher:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") == true then
			fullscreenKeyboardWatcherUp:stop()
			fullscreenKeyboardWatcherDown:stop()
		end

		--------------------------------------------------------------------------------
		-- Disable Scrolling Timeline Watcher:
		--------------------------------------------------------------------------------
		if settings.get("fcpxHacks.scrollingTimelineActive") == true then
			if mod.scrollingTimelineWatcherDown ~= nil then
				mod.scrollingTimelineWatcherDown:stop()
			end
		end

		--------------------------------------------------------------------------------
		-- Disable Lock Timeline Playhead:
		--------------------------------------------------------------------------------
		local lockTimelinePlayhead = settings.get("fcpxHacks.lockTimelinePlayhead") or false
		if lockTimelinePlayhead then
			fcp.app():timeline():unlockPlayhead()
		end

		--------------------------------------------------------------------------------
		-- Check if we need to hide the Touch Bar:
		--------------------------------------------------------------------------------
		hideTouchbar()

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

		--------------------------------------------------------------------------------
		-- Disable Menubar Items:
		--------------------------------------------------------------------------------
		timer.doAfter(0.0000000000001, function() refreshMenuBar() end)
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
    	if mod.lastCommandSet ~= fcp.getActiveCommandSetPath() then
    		if not fcp.app():commandEditor():isShowing() then
	    		timer.doAfter(0.0000000000001, function() bindKeyboardShortcuts() end)
			end
		end

    	--------------------------------------------------------------------------------
    	-- Refresh Menubar:
    	--------------------------------------------------------------------------------
    	timer.doAfter(0.0000000000001, function() refreshMenuBar(true) end)

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
-- ENABLE SHORTCUTS DURING FCPX FULLSCREEN PLAYBACK:
--------------------------------------------------------------------------------
function fullscreenKeyboardWatcher()
	fullscreenKeyboardWatcherWorking = false
	fullscreenKeyboardWatcherUp = eventtap.new({ eventtap.event.types.keyUp }, function(event)
		fullscreenKeyboardWatcherWorking = false
	end)
	fullscreenKeyboardWatcherDown = eventtap.new({ eventtap.event.types.keyDown }, function(event)

		--------------------------------------------------------------------------------
		-- Don't repeat if key is held down:
		--------------------------------------------------------------------------------
		if fullscreenKeyboardWatcherWorking then return false end
		fullscreenKeyboardWatcherWorking = true

		--------------------------------------------------------------------------------
		-- Define Final Cut Pro:
		--------------------------------------------------------------------------------
		local fcpx = fcp.application()
		local fcpxElements = ax.applicationElement(fcpx)

		--------------------------------------------------------------------------------
		-- Only Continue if in Full Screen Playback Mode:
		--------------------------------------------------------------------------------
		if fcpxElements[1][1] ~= nil then
			if fcpxElements[1][1]:attributeValue("AXIdentifier") == "_NS:523" then

				--------------------------------------------------------------------------------
				-- Debug:
				--------------------------------------------------------------------------------
				debugMessage("Key Pressed whilst in Full Screen Mode.")

				--------------------------------------------------------------------------------
				-- Get keypress information:
				--------------------------------------------------------------------------------
				local whichKey = event:getKeyCode()			-- EXAMPLE: fcp.keyCodeTranslator(whichKey) == "c"
				local whichModifier = event:getFlags()		-- EXAMPLE: whichFlags['cmd']

				--------------------------------------------------------------------------------
				-- Check all of these shortcut keys for presses:
				--------------------------------------------------------------------------------
				local fullscreenKeys = {"SetSelectionStart", "SetSelectionEnd", "AnchorWithSelectedMedia", "AnchorWithSelectedMediaAudioBacktimed", "InsertMedia", "AppendWithSelectedMedia" }

				for x, whichShortcutKey in pairs(fullscreenKeys) do
					if mod.finalCutProShortcutKey[whichShortcutKey] ~= nil then
						if mod.finalCutProShortcutKey[whichShortcutKey]['characterString'] ~= nil then
							if mod.finalCutProShortcutKey[whichShortcutKey]['characterString'] ~= "" then
								if whichKey == mod.finalCutProShortcutKey[whichShortcutKey]['characterString'] and tools.modifierMatch(whichModifier, mod.finalCutProShortcutKey[whichShortcutKey]['modifiers']) then
									eventtap.keyStroke({""}, "escape")
									eventtap.keyStroke(mod.finalCutProShortcutKey["ToggleEventLibraryBrowser"]['modifiers'], keycodes.map[mod.finalCutProShortcutKey["ToggleEventLibraryBrowser"]['characterString']])
									eventtap.keyStroke(mod.finalCutProShortcutKey[whichShortcutKey]['modifiers'], keycodes.map[mod.finalCutProShortcutKey[whichShortcutKey]['characterString']])
									eventtap.keyStroke(mod.finalCutProShortcutKey["PlayFullscreen"]['modifiers'], keycodes.map[mod.finalCutProShortcutKey["PlayFullscreen"]['characterString']])
									return true
								end
							end
						end
					end
				end
			end
			--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Fullscreen with playback controls:
			--------------------------------------------------------------------------------
			if fcpxElements[1][1][1] ~= nil then
				if fcpxElements[1][1][1][1] ~= nil then
					if fcpxElements[1][1][1][1]:attributeValue("AXIdentifier") == "_NS:51" then

						--------------------------------------------------------------------------------
						-- Get keypress information:
						--------------------------------------------------------------------------------
						local whichKey = event:getKeyCode()			-- EXAMPLE: fcp.keyCodeTranslator(whichKey) == "c"
						local whichModifier = event:getFlags()		-- EXAMPLE: whichFlags['cmd']

						--------------------------------------------------------------------------------
						-- Check all of these shortcut keys for presses:
						--------------------------------------------------------------------------------
						local fullscreenKeys = {"SetSelectionStart", "SetSelectionEnd", "AnchorWithSelectedMedia", "AnchorWithSelectedMediaAudioBacktimed", "InsertMedia", "AppendWithSelectedMedia" }
						for x, whichShortcutKey in pairs(fullscreenKeys) do
							if mod.finalCutProShortcutKey[whichShortcutKey] ~= nil then
								if mod.finalCutProShortcutKey[whichShortcutKey]['characterString'] ~= nil then
									if mod.finalCutProShortcutKey[whichShortcutKey]['characterString'] ~= "" then
										if whichKey == mod.finalCutProShortcutKey[whichShortcutKey]['characterString'] and tools.modifierMatch(whichModifier, mod.finalCutProShortcutKey[whichShortcutKey]['modifiers']) then
											eventtap.keyStroke({""}, "escape")
											eventtap.keyStroke(mod.finalCutProShortcutKey["ToggleEventLibraryBrowser"]['modifiers'], keycodes.map[mod.finalCutProShortcutKey["ToggleEventLibraryBrowser"]['characterString']])
											eventtap.keyStroke(mod.finalCutProShortcutKey[whichShortcutKey]['modifiers'], keycodes.map[mod.finalCutProShortcutKey[whichShortcutKey]['characterString']])
											eventtap.keyStroke(mod.finalCutProShortcutKey["PlayFullscreen"]['modifiers'], keycodes.map[mod.finalCutProShortcutKey["PlayFullscreen"]['characterString']])
											return true
										end
									end
								end
							end
						end
					end
				end
			end
			--------------------------------------------------------------------------------

		end
	end)
end

--------------------------------------------------------------------------------
-- MEDIA IMPORT WINDOW WATCHER:
--------------------------------------------------------------------------------
function mediaImportWatcher()
	debugMessage("Watching for new media...")
	mod.newDeviceMounted = fs.volume.new(function(event, table)
		if event == fs.volume.didMount then

			debugMessage("Media Inserted.")

			local mediaImportCount = 0
			local stopMediaImportTimer = false
			local currentApplication = application.frontmostApplication()
			debugMessage("Currently using '"..currentApplication:name().."'")

			local fcpx = fcp.application()
			local fcpxHidden = true
			if fcpx ~= nil then fcpxHidden = fcpx:isHidden() end

			mediaImportTimer = timer.doUntil(
				function()
					return stopMediaImportTimer
				end,
				function()
					if not fcp.running() then
						debugMessage("FCPX is not running. Stop watching.")
						stopMediaImportTimer = true
					else
						local fcpx = fcp.application()
						local fcpxElements = ax.applicationElement(fcpx)
						if fcpxElements[1] ~= nil then
							if fcpxElements[1]:attributeValue("AXTitle") == fcp.getTranslation("Media Import") then
								if mediaImportCount ~= 0 then
									--------------------------------------------------------------------------------
									-- Media Import Window was not open:
									--------------------------------------------------------------------------------
									fcpxElements[1][11]:performAction("AXPress")
									if fcpxHidden then fcpx:hide() end
									application.launchOrFocus(currentApplication:name())
									debugMessage("Hid FCPX and returned to '"..currentApplication:name().."'.")
								end
								stopMediaImportTimer = true
							end
						end
						mediaImportCount = mediaImportCount + 1
						if mediaImportCount == 500 then
							debugMessage("Gave up watching for the Media Import window after 5 seconds.")
							stopMediaImportTimer = true
						end
					end
				end,
				0.01
			)
		end
	end)
	mod.newDeviceMounted:start()
end

--------------------------------------------------------------------------------
-- SCROLLING TIMELINE WATCHER:
--------------------------------------------------------------------------------
function scrollingTimelineWatcher()

	local timeline = fcp.app():timeline()

	--------------------------------------------------------------------------------
	-- Key Press Down Watcher:
	--------------------------------------------------------------------------------
	mod.scrollingTimelineWatcherDown = eventtap.new({ eventtap.event.types.keyDown }, function(event)

		--------------------------------------------------------------------------------
		-- Don't do anything if we're already locked.
		--------------------------------------------------------------------------------
		if timeline:isLockedPlayhead() then
			return false
		elseif event:getKeyCode() == 49 and next(event:getFlags()) == nil then
			--------------------------------------------------------------------------------
			-- Spacebar Pressed:
			--------------------------------------------------------------------------------
			checkScrollingTimeline()
		end
	end)
end

	--------------------------------------------------------------------------------
	-- CHECK TO SEE IF WE SHOULD ACTUALLY TURN ON THE SCROLLING TIMELINE:
	--------------------------------------------------------------------------------
	function checkScrollingTimeline()

		--------------------------------------------------------------------------------
		-- Make sure the Command Editor and hacks console are closed:
		--------------------------------------------------------------------------------
		if fcp.app():commandEditor():isShowing() or hacksconsole.active then
			debugMessage("Spacebar pressed while other windows are visible.")
			return "Stop"
		end

		--------------------------------------------------------------------------------
		-- Don't activate scrollbar in fullscreen mode:
		--------------------------------------------------------------------------------
		if fcp.app():fullScreenWindow():isShowing() then
			debugMessage("Spacebar pressed in fullscreen mode whilst watching for scrolling timeline.")
			return "Stop"
		end

		local timeline = fcp.app():timeline()

		--------------------------------------------------------------------------------
		-- Get Timeline Scroll Area:
		--------------------------------------------------------------------------------
		if not timeline:isShowing() then
			writeToConsole("ERROR: Could not find Timeline Scroll Area.")
			return "Stop"
		end

		--------------------------------------------------------------------------------
		-- Check mouse is in timeline area:
		--------------------------------------------------------------------------------
		local mouseLocation = geometry.point(mouse.getAbsolutePosition())
		local viewFrame = geometry.rect(timeline:content():viewFrame())
		if mouseLocation:inside(viewFrame) then

			--------------------------------------------------------------------------------
			-- Mouse is in the timeline area when spacebar pressed so LET'S DO IT!
			--------------------------------------------------------------------------------
			debugMessage("Mouse inside Timeline Area.")
			timeline:lockPlayhead(true)
		else
			debugMessage("Mouse outside of Timeline Area.")
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

		local prowlAPIKey = settings.get("fcpxHacks.prowlAPIKey") or nil
		if prowlAPIKey ~= nil then

			local prowlApplication = http.encodeForQuery("FINAL CUT PRO")
			local prowlEvent = http.encodeForQuery("")
			local prowlDescription = nil

			if name == "uploadSuccess" then prowlDescription = http.encodeForQuery("Share Successful") end
			if name == "ProTranscoderDidFailNotification" then prowlDescription = http.encodeForQuery("Share Failed") end

			local prowlAction = "https://api.prowlapp.com/publicapi/add?apikey=" .. prowlAPIKey .. "&application=" .. prowlApplication .. "&event=" .. prowlEvent .. "&description=" .. prowlDescription
			httpResponse, httpBody, httpHeader = http.get(prowlAction, nil)

			if not string.match(httpBody, "success") then
				local xml = slaxdom:dom(tostring(httpBody))
				local errorMessage = xml['root']['el'][1]['kids'][1]['value'] or nil
				if errorMessage ~= nil then writeToConsole("PROWL ERROR: " .. tools.trim(tostring(errorMessage))) end
			end
		end

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
		refreshMenuBar(true)
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
					sharedXMLNotification = notify.new(function() fcp.importXML(file) end)
						:setIdImage(image.imageFromPath(fcpxhacks.iconPath))
						:title("New XML Recieved")
						:subTitle(file:sub(string.len(xmlSharingPath) + 1 + string.len(editorName) + 1, -8))
						:informativeText("FCPX Hacks has recieved a new XML file.")
						:hasActionButton(true)
						:actionButtonTitle("Import XML")
						:send()

				end
			end
        end
    end

	refreshMenuBar()
end

--------------------------------------------------------------------------------
-- TOUCH BAR WATCHER:
--------------------------------------------------------------------------------
function touchbarWatcher(obj, message)

	if message == "didEnter" then
        mod.mouseInsideTouchbar = true
    elseif message == "didExit" then
        mod.mouseInsideTouchbar = false

        --------------------------------------------------------------------------------
	    -- Just in case we got here before the eventtap returned the Touch Bar to normal:
	    --------------------------------------------------------------------------------
        mod.touchBarWindow:movable(false)
        mod.touchBarWindow:acceptsMouseEvents(true)
		settings.set("fcpxHacks.lastTouchBarLocation", mod.touchBarWindow:topLeft())

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