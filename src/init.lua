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
--  Please be aware that I'm a filmmaker, not a coder, so... apologies!
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
--  FCPX HACKS LOGO DESIGNED BY:
--------------------------------------------------------------------------------
--
--  > Sam Woodhall (https://twitter.com/SWDoctor)
--
--------------------------------------------------------------------------------
--  USING SNIPPETS OF CODE FROM:
--------------------------------------------------------------------------------
--
--  > http://www.hammerspoon.org/go/
--  > https://github.com/asmagill/hs._asm.axuielement
--  > https://github.com/Hammerspoon/hammerspoon/issues/272
--  > https://github.com/Hammerspoon/hammerspoon/issues/1021#issuecomment-251827969
--  > https://github.com/Hammerspoon/hammerspoon/issues/1027#issuecomment-252024969
--
--------------------------------------------------------------------------------
--  HUGE SPECIAL THANKS TO THESE AMAZING DEVELOPERS FOR ALL THEIR HELP:
--------------------------------------------------------------------------------
--
--  > Aaron Magill (https://github.com/asmagill)
--  > Chris Jones (https://github.com/cmsj)
--  > Bill Cheeseman (http://pfiddlesoft.com)
--  > Yvan Koenig (http://macscripter.net/viewtopic.php?id=45148)
--  > Tim Webb (https://twitter.com/_timwebb_)
--
--------------------------------------------------------------------------------
--  VERY SPECIAL THANKS TO THESE AWESOME TESTERS & SUPPORTERS:
--------------------------------------------------------------------------------
--
--  > The always incredible Karen Hocking!
--  > Daniel Daperis & David Hocking
--  > Андрей Смирнов
--  > FCPX Editors InSync Facebook Group
--  > Alex Gollner (http://alex4d.com)
--  > Scott Simmons (http://www.scottsimmons.tv)
--  > Isaac J. Terronez (https://twitter.com/ijterronez)
--  > Shahin Shokoui, Ilyas Akhmedov & Tim Webb
--
--------------------------------------------------------------------------------
--  FEATURE WISH LIST:
--------------------------------------------------------------------------------
--
--  > Add Audio Fade Handles Shortcut
--  > Remember Last Project & Layout when restarting FCPX
--  > Shortcut to go to full screen mode without playing
--  > Transitions, Titles, Generators & Themes Shortcuts
--  > Timeline Index HUD on Mouseover
--  > Watch Folders for Compressor
--  > Favourites folder for Effects, Transitions, Titles, Generators & Themes
--  > Mouse Rewind History (as someone suggested on FCPX Grill)
--  > Automatically add markers based on music beats (suggested by Ilyas Akhmedov)
--
--------------------------------------------------------------------------------
--  HIGH PRIORITY LIST:
--------------------------------------------------------------------------------
--
--  > "Activate all audio tracks on all selected multicam clips" shortcut.
--  > Move Storyline Up & Down Shortcut
--
--------------------------------------------------------------------------------
--  LOW PRIORITY LIST:
--------------------------------------------------------------------------------
--
--  > Re-write findMenuItem code so works in multiple languages
--  > clipboardWatcher() needs better way to find clipboard label
--  > updateEffectsList() needs to be faster
--  > translateKeyboardCharacters() could be done better
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





-------------------------------------------------------------------------------
-- SCRIPT VERSION:
-------------------------------------------------------------------------------
local scriptVersion = "0.47"
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
-- ENABLE DEBUG MODE:
--------------------------------------------------------------------------------
local debugMode = false
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   T H E    M A I N    S C R I P T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CLEAR THE CONSOLE:
--------------------------------------------------------------------------------
hs.console.clearConsole()

--------------------------------------------------------------------------------
-- DISPLAY WELCOME MESSAGE IN THE CONSOLE:
--------------------------------------------------------------------------------
print("====================================================")
print("                  FCPX Hacks v" .. scriptVersion     )
print("====================================================")
print("    If you have any problems with this script,      ")
print("  please email a screenshot of your entire screen   ")
print(" with this console open to: chris@latenitefilms.com ")
print("====================================================")

--------------------------------------------------------------------------------
-- LOAD EXTENSIONS:
--------------------------------------------------------------------------------

-- BUILT-IN:

	fs							= require("hs.fs")
	host						= require("hs.host")
	settings					= require("hs.settings")
	http						= require("hs.http")
	menubar						= require("hs.menubar")
	eventtap					= require("hs.eventtap")
	window						= require("hs.window")
	window.filter				= require("hs.window.filter")
	pathwatcher					= require("hs.pathwatcher")
	alert 						= require("hs.alert")
	hotkey 						= require("hs.hotkey")
	application 				= require("hs.application")
	uielement 					= require("hs.uielement")
	appfinder 					= require("hs.appfinder")
	osascript 					= require("hs.osascript")
	drawing 					= require("hs.drawing")
	fnutils 					= require("hs.fnutils")
	keycodes					= require("hs.keycodes")
	json  						= require("hs.json")
	base64 						= require("hs.base64")
	distributednotifications	= require("hs.distributednotifications")
	utf8						= require("hs.utf8")
	http						= require("hs.http")


-- THIRD PARTY:

	ax 							= require("hs._asm.axuielement")
	slaxml 						= require("hs.slaxml")
	slaxdom 					= require("hs.slaxml.slaxdom")


-- PASTEBOARD ONLY CURRENTLY WORKS ON MACOS 10.11 AND ABOVE:

	local disablePasteboard = true
	if tonumber(hs.host.operatingSystemVersion()["minor"]) >= 11 then
		pasteboard 					= require("hs.pasteboard")
		disablePasteboard = false
	end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
-- LOCAL VARIABLES:
--------------------------------------------------------------------------------
local clock 									= os.clock										-- Used for sleep()

local browserHighlight 							= nil											-- Used for Highlight Browser Playhead
local browserHighlightTimer 					= nil											-- Used for Highlight Browser Playhead

local scrollingTimelineSpacebarPressed   		= false											-- Was spacebar pressed?
local scrollingTimelineWatcherWorking 			= false											-- Is Scrolling Timeline Spacebar Held Down?

local scrollingTimelineTimer					= nil											-- Scrolling Timeline Timer
local scrollingTimelineScrollbarTimer			= nil											-- Scrolling Timeline Scrollbar Timer

local scrollingTimelineSplitGroupCache 			= nil											-- Scrolling Timeline Split Group Cache
local scrollingTimelineGroupCache 				= nil											-- Scrolling Timeline Group Cache

local finalCutProShortcutKey 					= nil											-- Table of all Final Cut Pro Shortcuts
local finalCutProShortcutKeyPlaceholders 		= nil											-- Table of all needed Final Cut Pro Shortcuts

local isCommandEditorOpen 						= false 										-- Is Command Editor Open?

local colorBoardSelectPuckSplitGroupCache 		= nil											-- Color Board Select Puck Split Group Cache
local colorBoardSelectPuckGroupCache 			= nil											-- Color Board Select Puck Group Cache

local releaseColorBoardDown						= false											-- Color Board Shortcut Currently Being Pressed

local changeTimelineClipHeightAlreadyInProgress = false											-- Change Timeline Clip Height Already In Progress
local releaseChangeTimelineClipHeightDown		= false											-- Change Timeline Clip Height Currently Being Pressed
local changeAppearanceButtonLocation 			= {}											-- Change Timeline Appearance Button Location
local changeTimelineClipHeightSplitGroupCache 	= nil											-- Change Timeline Clip Height Split Group Cache
local changeTimelineClipHeightGroupCache 		= nil											-- Change Timeline Clip Height Group Cache

local clipboardTimer							= nil											-- Clipboard Watcher Timer
local clipboardLastChange 						= pasteboard.changeCount() 						-- Displays how many times the pasteboard owner has changed (indicates a new copy has been made)
local clipboardHistory							= {}											-- Clipboard History
local finalCutProClipboardUTI 					= "com.apple.flexo.proFFPasteboardUTI"			-- Final Cut Pro Pasteboard UTI

local clipboardWatcherFrequency 				= 0.5											-- Clipboard Watcher Update Frequency
local clipboardHistoryMaximumSize 				= 5												-- Maximum Size of Clipboard History

local selectSecondaryStorylineSplitGroupCache 	= nil											-- Select Secondary Storyline Split Group Cache
local selectSecondaryStorylineGroupCache 		= nil											-- Select Secondary Storyline Group Cache

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
-- LOAD SCRIPT:
--------------------------------------------------------------------------------
function loadScript()

	--------------------------------------------------------------------------------
	-- Need Accessibility Activated:
	--------------------------------------------------------------------------------
	hs.accessibilityState(true)

	--------------------------------------------------------------------------------
	-- Limit Error Messages for a clean console:
	--------------------------------------------------------------------------------
	hotkey.setLogLevel("warning")
	hs.window.filter.setLogLevel(1)
	hs.window.filter.ignoreAlways['System Events'] = true

	--------------------------------------------------------------------------------
	-- Is Final Cut Pro Installed:
	--------------------------------------------------------------------------------
	if isFinalCutProInstalled() then

		--------------------------------------------------------------------------------
		-- Settings Defaults:
		--------------------------------------------------------------------------------
		if hs.settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") == nil then hs.settings.set("fcpxHacks.enableShortcutsDuringFullscreenPlayback", false) end
		if hs.settings.get("fcpxHacks.scrollingTimelineActive") == nil then hs.settings.set("fcpxHacks.scrollingTimelineActive", false) end
		if hs.settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro") == nil then hs.settings.set("fcpxHacks.enableHacksShortcutsInFinalCutPro", false) end

		--------------------------------------------------------------------------------
		-- Useful Debugging Information:
		--------------------------------------------------------------------------------
		if macOSVersion() ~= nil then print("[FCPX Hacks] macOS Version: " .. tostring(macOSVersion())) end
		if finalCutProVersion() ~= nil then	print("[FCPX Hacks] Final Cut Pro Version: " .. tostring(finalCutProVersion()))	end
		if hs.keycodes.currentLayout() ~= nil then print("[FCPX Hacks] Current keyboard layout: " .. tostring(hs.keycodes.currentLayout())) end
		local settingsDebug1 = hs.settings.get("fcpxHacks.effectsShortcutThree") or ""
		local settingsDebug2 = hs.settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro") or ""
		local settingsDebug3 = hs.settings.get("fcpxHacks.allEffects") or ""
		local settingsDebug4 = hs.settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") or ""
		local settingsDebug5 = hs.settings.get("fcpxHacks.effectsListUpdated") or ""
		local settingsDebug6 = hs.settings.get("fcpxHacks.displayHighlightShape") or ""
		local settingsDebug7 = hs.settings.get("fcpxHacks.displayHighlightColour") or ""
		local settingsDebug8 = hs.settings.get("fcpxHacks.displayMenubarAsIcon") or ""
		local settingsDebug9 = hs.settings.get("fcpxHacks.effectsShortcutOne") or ""
		local settingsDebug10 = hs.settings.get("fcpxHacks.effectsShortcutTwo") or ""
		local settingsDebug11 = hs.settings.get("fcpxHacks.effectsShortcutThree") or ""
		local settingsDebug12 = hs.settings.get("fcpxHacks.effectsShortcutFour") or ""
		local settingsDebug13 = hs.settings.get("fcpxHacks.effectsShortcutFive") or ""
		local settingsDebug14 = hs.settings.get("fcpxHacks.enableProxyMenuIcon") or ""
		local settingsDebug15 = hs.settings.get("fcpxHacks.scrollingTimelineActive") or ""
		local settingsDebug16 = hs.settings.get("fcpxHacks.lastVersion") or ""
		local settingsDebug17 = hs.settings.get("fcpxHacks.enableClipboardHistory") or ""
		local settingsDebug18 = hs.settings.get("fcpxHacks.clipboardHistory") or ""
		local settingsDebug19 = hs.settings.get("fcpxHacks.prowlAPIKey") or ""
		local settingsDebug20 = hs.settings.get("fcpxHacks.enableMobileNotifications") or ""
		print("[FCPX Hacks] Settings: " .. tostring(settingsDebug1) .. ";" .. tostring(settingsDebug2) .. ";"  .. tostring(settingsDebug3) .. ";"  .. tostring(settingsDebug4) .. ";"  .. tostring(settingsDebug5) .. ";"  .. tostring(settingsDebug6) .. ";"  .. tostring(settingsDebug7) .. ";"  .. tostring(settingsDebug8) .. ";"  .. tostring(settingsDebug9) .. ";"  .. tostring(settingsDebug10) .. ";"  .. tostring(settingsDebug11) .. ";"  .. tostring(settingsDebug12) .. ";"  .. tostring(settingsDebug13) .. ";"  .. tostring(settingsDebug14) .. ";"  .. tostring(settingsDebug15) .. ";"  .. tostring(settingsDebug16) .. ";" .. tostring(settingsDebug17) .. ";" .. tostring(settingsDebug18) .. ";" .. tostring(settingsDebug19) .. ";" .. tostring(settingsDebug20) .. ".")

		-------------------------------------------------------------------------------
		-- Common Error Messages:
		-------------------------------------------------------------------------------
		commonErrorMessageStart = "I'm sorry, but the following error has occurred:\n\n"
		commonErrorMessageEnd = "\n\nmacOS Version: " .. macOSVersion() .. "\nFCPX Version: " .. finalCutProVersion() .. "\nScript Version: " .. scriptVersion .. "\n\nPlease take a screenshot of your entire screen and email it to the below address so that we can try and come up with a fix:\n\nchris@latenitefilms.com\n\nThank you for testing!"
		commonErrorMessageAppleScript = 'set fcpxIcon to (((POSIX path of ((path to home folder as Unicode text) & ".hammerspoon:hs:fcpx:assets:fcpxhacks.icns")) as Unicode text) as POSIX file)\n\nset commonErrorMessageStart to "' .. commonErrorMessageStart .. '"\nset commonErrorMessageEnd to "' .. commonErrorMessageEnd .. '"\n'

		-------------------------------------------------------------------------------
		-- Check Final Cut Pro Version Compatibility:
		-------------------------------------------------------------------------------
		if finalCutProVersion() ~= "10.2.3" then displayMessage("Please be aware that FCPX Hacks has ONLY been tested on Final Cut Pro 10.2.3 and MAY not work correctly on other versions.\n\nWe strongly recommend you do NOT use FCPX on newer versions of Final Cut Pro.") end

		--------------------------------------------------------------------------------
		-- Check if we need to update the Final Cut Pro Shortcut Files:
		--------------------------------------------------------------------------------
		if hs.settings.get("fcpxHacks.lastVersion") == nil then
			hs.settings.set("fcpxHacks.lastVersion", scriptVersion)
			hs.settings.set("fcpxHacks.enableHacksShortcutsInFinalCutPro", false)
		else
			if tonumber(hs.settings.get("fcpxHacks.lastVersion")) < tonumber(scriptVersion) then
				if hs.settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro") then
					local finalCutProRunning = isFinalCutProRunning()
					if finalCutProRunning then
						displayMessage("This latest version of FCPX Hacks may contain new keyboard shortcuts.\n\nFor these shortcuts to appear in the Final Cut Pro Command Editor, we'll need to update the shortcut files.\n\nYou will need to enter your Administrator password and restart Final Cut Pro.")
						updateKeyboardShortcuts()
						if not restartFinalCutPro() then
							--------------------------------------------------------------------------------
							-- Failed to restart Final Cut Pro:
							--------------------------------------------------------------------------------
							displayErrorMessage("Failed to restart Final Cut Pro. You will need to restart manually.")
							return "Failed"
						end
					else
						displayMessage("This latest version of FCPX Hacks may contain new keyboard shortcuts.\n\nFor these shortcuts to appear in the Final Cut Pro Command Editor, we'll need to update the shortcut files.\n\nYou will need to enter your Administrator password.")
						updateKeyboardShortcuts()
					end
				end
			end
			hs.settings.set("fcpxHacks.lastVersion", scriptVersion)
		end

		--------------------------------------------------------------------------------
		-- Check for Script Updates:
		--------------------------------------------------------------------------------
		latestScriptVersion = nil
		updateResponse, updateBody, updateHeader = hs.http.get("https://latenitefilms.com/downloads/fcpx-hammerspoon-version.html", nil)
		if updateResponse == 200 then
			if updateBody:sub(1,8) == "LATEST: " then
				latestScriptVersion = updateBody:sub(9,12)
			end
		end

		--------------------------------------------------------------------------------
		-- Setup Watches:
		--------------------------------------------------------------------------------

			--------------------------------------------------------------------------------
			-- Create and start the application event watcher:
			--------------------------------------------------------------------------------
			watcher = hs.application.watcher.new(finalCutProWatcher)
			watcher:start()

			--------------------------------------------------------------------------------
			-- Watch For Hammerspoon Script Updates:
			--------------------------------------------------------------------------------
			hammerspoonWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

			--------------------------------------------------------------------------------
			-- Watch for Final Cut Pro plist changes:
			--------------------------------------------------------------------------------
			preferencesWatcher = hs.pathwatcher.new("~/Library/Preferences/", finalCutProSettingsPlistChanged):start()

			--------------------------------------------------------------------------------
			-- Full Screen Keyboard Watcher:
			--------------------------------------------------------------------------------
			fullscreenKeyboardWatcher()

			--------------------------------------------------------------------------------
			-- Command Editor Watcher:
			--------------------------------------------------------------------------------
			commandEditorWatcher()

			--------------------------------------------------------------------------------
			-- Scrolling Timeline Watcher:
			--------------------------------------------------------------------------------
			scrollingTimelineWatcher()

			--------------------------------------------------------------------------------
			-- Clipboard Watcher:
			--------------------------------------------------------------------------------
			local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false
			if enableClipboardHistory then clipboardWatcher() end

			--------------------------------------------------------------------------------
			-- Notification Watcher:
			--------------------------------------------------------------------------------
			local enableMobileNotifications = settings.get("fcpxHacks.enableMobileNotifications") or false
			if enableMobileNotifications then notificationWatcher() end

		--------------------------------------------------------------------------------
		-- Bind Keyboard Shortcuts:
		--------------------------------------------------------------------------------
		bindKeyboardShortcuts()

		--------------------------------------------------------------------------------
		-- Activate the correct modal state:
		--------------------------------------------------------------------------------
		if isFinalCutProFrontmost() then

			--------------------------------------------------------------------------------
			-- Enable Final Cut Pro Shortcut Keys:
			--------------------------------------------------------------------------------
			hotkeys:enter()

			--------------------------------------------------------------------------------
			-- Enable Fullscreen Playback Shortcut Keys:
			--------------------------------------------------------------------------------
			if hs.settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") then
				fullscreenKeyboardWatcherUp:start()
				fullscreenKeyboardWatcherDown:start()
			end

			--------------------------------------------------------------------------------
			-- Enable Scrolling Timeline:
			--------------------------------------------------------------------------------
			if hs.settings.get("fcpxHacks.scrollingTimelineActive") then
				scrollingTimelineWatcherUp:start()
				scrollingTimelineWatcherDown:start()
			end

		else
			--------------------------------------------------------------------------------
			-- Disable Final Cut Pro Shortcut Keys:
			--------------------------------------------------------------------------------
			hotkeys:exit()

			--------------------------------------------------------------------------------
			-- Disable Fullscreen Playback Shortcut Keys:
			--------------------------------------------------------------------------------
			fullscreenKeyboardWatcherUp:stop()
			fullscreenKeyboardWatcherDown:stop()

			--------------------------------------------------------------------------------
			-- Disable Scrolling Timeline:
			--------------------------------------------------------------------------------
			if scrollingTimelineWatcherUp ~= nil then
				scrollingTimelineWatcherUp:stop()
				scrollingTimelineWatcherDown:stop()
			end
		end

		--------------------------------------------------------------------------------
		-- Set up Menubar:
		--------------------------------------------------------------------------------
		fcpxMenubar = hs.menubar.newWithPriority(1)

			--------------------------------------------------------------------------------
			-- Set Tool Tip:
			--------------------------------------------------------------------------------
			fcpxMenubar:setTooltip("FCPX Hacks Version " .. scriptVersion)

			--------------------------------------------------------------------------------
			-- Work out Menubar Display Mode:
			--------------------------------------------------------------------------------
			updateMenubarIcon()

			--------------------------------------------------------------------------------
			-- Populate the Menubar for the first time:
			--------------------------------------------------------------------------------
			refreshMenuBar(true)

		--------------------------------------------------------------------------------
		-- All loaded!
		--------------------------------------------------------------------------------
		print("[FCPX Hacks] Successfully loaded.")
		hs.alert.show("FCPX Hacks (v" .. scriptVersion .. ") has loaded.")

	else
    	--------------------------------------------------------------------------------
    	-- Final Cut Pro couldn't be found so giving up:
    	--------------------------------------------------------------------------------
    	displayAlertMessage("Opps! Unfortunately we couldn't find Final Cut Pro installed on this system.\n\nPlease make sure it's installed in the Applications folder and hasn't been renamed.\n\nIf it is installed, please contact chris@lateniefilms.com to troubleshoot.\n\nThanks for testing!")
		print("[FCPX Hacks] ERROR: Final Cut Pro could not be found so giving up.")
	end
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

	-- Clear Console During Development:
	hs.console.clearConsole()

	selectSecondaryStoryline(1)

end

--------------------------------------------------------------------------------
-- HIGHLIGHT BROWSER PLAYHEAD EXPERIMENT:
--------------------------------------------------------------------------------
function highlightFCPXBrowserPlayheadTest()

    sw = ax.windowElement(hs.application("Final Cut Pro"):mainWindow())

    persistentPlayhead = sw:searchPath({
        { role = "AXWindow", Title = "Final Cut Pro"},
        { role = "AXSplitGroup", AXRoleDescription = "split group" },
        { role = "AXGroup", },
        { role = "AXSplitGroup", Identifier = "_NS:11" },
        { role = "AXScrollArea", Description = "organizer" },
        { role = "AXGroup", Identifier = "_NS:9"},
        { role = "AXValueIndicator", Description = "persistent playhead" },
    }, 1)

    persistentPlayheadPosition = persistentPlayhead:attributeValue("AXPosition")
    persistentPlayheadSize = persistentPlayhead:attributeValue("AXSize")

    mouseHighlight(persistentPlayheadPosition["x"], persistentPlayheadPosition["y"], persistentPlayheadSize["w"], persistentPlayheadSize["h"])

	hs.logger.printHistory()

end

--------------------------------------------------------------------------------
-- GET UI ELEMENT CURRENTLY UNDER MOUSE:
--------------------------------------------------------------------------------
function getElementUnderMouse()
	underMouse = ax.systemElementAtPosition(hs.mouse.getAbsolutePosition())
	--print_r(underMouse:path())
	for i=1, #underMouse:attributeNames() do
		--print(underMouse:attributeNames()[i] .. ": " .. underMouse:attributeValue(underMouse:attributeNames()[i]))
		local description = tostring(underMouse:attributeNames()[i])
		local result = tostring(underMouse:attributeValue(underMouse:attributeNames()[i]))
		print(description .. ": " .. result)

	end

end

--------------------------------------------------------------------------------
-- GET FINAL CUT PRO APPLICATION UI TREE:
--------------------------------------------------------------------------------
function getFinalCutProApplicationTree()

	ax = require("hs._asm.axuielement")
	inspect = require("hs.inspect")
	timestamp = function(date)
	    date = date or require"hs.timer".secondsSinceEpoch()
	    return os.date("%F %T" .. ((tostring(date):match("(%.%d+)$")) or ""), math.floor(date))
    end

    print(timestamp())
	s = ax.applicationElement(hs.application("Final Cut Pro"))
	print(inspect(s:buildTree()))
	print(timestamp())

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    K E Y B O A R D     S H O R T C U T S                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- BIND KEYBOARD SHORTCUTS:
--------------------------------------------------------------------------------
function bindKeyboardShortcuts()

	--------------------------------------------------------------------------------
	-- Get Enable Hacks Shortcuts in Final Cut Pro from Settings:
	--------------------------------------------------------------------------------
	local enableHacksShortcutsInFinalCutPro = hs.settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro")
	if enableHacksShortcutsInFinalCutPro == nil then enableHacksShortcutsInFinalCutPro = false end

	--------------------------------------------------------------------------------
	-- Table of built-in FCPX Shortcuts we'll use for various things:
	--------------------------------------------------------------------------------
	local requiredBuiltInShortcuts = {
			["ColorBoard-NudgePuckUp"]									= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["ColorBoard-NudgePuckDown"]								= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["ColorBoard-NudgePuckLeft"]								= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["ColorBoard-NudgePuckRight"]								= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["SetSelectionStart"]										= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["SetSelectionEnd"]											= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["AnchorWithSelectedMedia"]									= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["AnchorWithSelectedMediaBacktimed"]						= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["InsertMedia"]												= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["AppendWithSelectedMedia"]									= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["GoToOrganizer"]											= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["PlayFullscreen"]											= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["ShowTimecodeEntryPlayhead"]								= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["ShareDefaultDestination"]									= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
			["Paste"]													= { characterString = "", modifiers = {}, fn = nil, releasedFn = nil, repeatFn = nil },
	}

	if enableHacksShortcutsInFinalCutPro then
		--------------------------------------------------------------------------------
		-- Get Shortcut Keys from plist:
		--------------------------------------------------------------------------------
		finalCutProShortcutKey = nil
		finalCutProShortcutKey = {}
		finalCutProShortcutKeyPlaceholders = nil
		finalCutProShortcutKeyPlaceholders =
		{
			FCPXHackLaunchFinalCutPro 									= { characterString = "", 							modifiers = {}, 									fn = function() launchFinalCutPro() end, 							releasedFn = nil, 														repeatFn = nil, 		global = true },
			FCPXHackShowListOfShortcutKeys 								= { characterString = "", 							modifiers = {}, 									fn = function() displayShortcutList() end, 							releasedFn = nil, 														repeatFn = nil, 		global = true },
			FCPXHackHighlightBrowserPlayhead 							= { characterString = "", 							modifiers = {}, 									fn = function() highlightFCPXBrowserPlayhead() end, 				releasedFn = nil, 														repeatFn = nil },
			FCPXHackRevealInBrowserAndHighlight 						= { characterString = "", 							modifiers = {}, 									fn = function() matchFrameThenHighlightFCPXBrowserPlayhead() end, 	releasedFn = nil, 														repeatFn = nil },
			FCPXHackSingleMatchFrameAndHighlight 						= { characterString = "", 							modifiers = {}, 									fn = function() singleMatchFrame() end, 							releasedFn = nil, 														repeatFn = nil },
			FCPXHackRevealMulticamClipInBrowserAndHighlight 			= { characterString = "", 							modifiers = {}, 									fn = function() multicamMatchFrame(true) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackRevealMulticamClipInAngleEditorAndHighlight 		= { characterString = "", 							modifiers = {}, 									fn = function() multicamMatchFrame(false) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackBatchExportFromBrowser 								= { characterString = "", 							modifiers = {}, 									fn = function() batchExportToCompressor() end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackChangeBackupInterval 								= { characterString = "", 							modifiers = {}, 									fn = function() changeBackupInterval() end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackToggleTimecodeOverlays 								= { characterString = "", 							modifiers = {}, 									fn = function() toggleTimecodeOverlay() end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackToggleMovingMarkers 								= { characterString = "", 							modifiers = {}, 									fn = function() toggleMovingMarkers() end, 							releasedFn = nil, 														repeatFn = nil },
			FCPXHackAllowTasksDuringPlayback 							= { characterString = "", 							modifiers = {}, 									fn = function() togglePerformTasksDuringPlayback() end, 			releasedFn = nil, 														repeatFn = nil },

			FCPXHackSelectColorBoardPuckOne 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectColorBoardPuckTwo 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectColorBoardPuckThree 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectColorBoardPuckFour 							= { characterString = "", 							modifiers = {},									 	fn = function() colorBoardSelectPuck(4) end, 						releasedFn = nil, 														repeatFn = nil },

			FCPXHackRestoreKeywordPresetOne 							= { characterString = "", 							modifiers = {}, 									fn = function() fcpxRestoreKeywordSearches(1) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetTwo 							= { characterString = "", 							modifiers = {}, 									fn = function() fcpxRestoreKeywordSearches(2) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetThree 							= { characterString = "", 							modifiers = {}, 									fn = function() fcpxRestoreKeywordSearches(3) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetFour 							= { characterString = "", 							modifiers = {}, 									fn = function() fcpxRestoreKeywordSearches(4) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetFive 							= { characterString = "", 							modifiers = {}, 									fn = function() fcpxRestoreKeywordSearches(5) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetSix 							= { characterString = "", 							modifiers = {}, 									fn = function() fcpxRestoreKeywordSearches(6) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetSeven 							= { characterString = "", 							modifiers = {}, 									fn = function() fcpxRestoreKeywordSearches(7) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetEight 							= { characterString = "", 							modifiers = {}, 									fn = function() fcpxRestoreKeywordSearches(8) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetNine 							= { characterString = "", 							modifiers = {}, 									fn = function() fcpxRestoreKeywordSearches(9) end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackSaveKeywordPresetOne 								= { characterString = "", 							modifiers = {}, 									fn = function() fcpxSaveKeywordSearches(1) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetTwo 								= { characterString = "", 							modifiers = {}, 									fn = function() fcpxSaveKeywordSearches(2) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetThree 								= { characterString = "", 							modifiers = {}, 									fn = function() fcpxSaveKeywordSearches(3) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetFour 								= { characterString = "", 							modifiers = {}, 									fn = function() fcpxSaveKeywordSearches(4) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetFive 								= { characterString = "", 							modifiers = {}, 									fn = function() fcpxSaveKeywordSearches(5) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetSix 								= { characterString = "", 							modifiers = {}, 									fn = function() fcpxSaveKeywordSearches(6) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetSeven 								= { characterString = "", 							modifiers = {}, 									fn = function() fcpxSaveKeywordSearches(7) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetEight 								= { characterString = "", 							modifiers = {}, 									fn = function() fcpxSaveKeywordSearches(8) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetNine 								= { characterString = "", 							modifiers = {}, 									fn = function() fcpxSaveKeywordSearches(9) end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackEffectsOne			 								= { characterString = "", 							modifiers = {}, 									fn = function() effectsShortcut(1) end, 							releasedFn = nil, 														repeatFn = nil },
			FCPXHackEffectsTwo			 								= { characterString = "", 							modifiers = {}, 									fn = function() effectsShortcut(2) end, 							releasedFn = nil, 														repeatFn = nil },
			FCPXHackEffectsThree			 							= { characterString = "", 							modifiers = {}, 									fn = function() effectsShortcut(3) end, 							releasedFn = nil, 														repeatFn = nil },
			FCPXHackEffectsFour			 								= { characterString = "", 							modifiers = {}, 									fn = function() effectsShortcut(4) end, 							releasedFn = nil, 														repeatFn = nil },
			FCPXHackEffectsFive			 								= { characterString = "", 							modifiers = {}, 									fn = function() effectsShortcut(5) end, 							releasedFn = nil, 														repeatFn = nil },

			FCPXHackScrollingTimeline	 								= { characterString = "", 							modifiers = {}, 									fn = function() toggleScrollingTimeline() end, 						releasedFn = nil, 														repeatFn = nil },

			FCPXHackColorPuckOne			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 1) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackColorPuckTwo			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 1) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackColorPuckThree			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 1) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackColorPuckFour			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 1) end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackSaturationPuckOne			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 2) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaturationPuckTwo			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 2) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaturationPuckThree			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 2) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaturationPuckFour			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 2) end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackExposurePuckOne			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 3) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackExposurePuckTwo			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 3) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackExposurePuckThree			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 3) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackExposurePuckFour			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 3) end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackColorPuckOneUp			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 1, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckTwoUp			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 1, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckThreeUp		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 1, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckFourUp		 								= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 1, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackColorPuckOneDown		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 1, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckTwoDown		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 1, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckThreeDown		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 1, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckFourDown	 								= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 1, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackColorPuckOneLeft		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 1, "left") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckTwoLeft		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 1, "left") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckThreeLeft		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 1, "left") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckFourLeft	 								= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 1, "left") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackColorPuckOneRight		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 1, "right") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckTwoRight		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 1, "right") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckThreeRight		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 1, "right") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckFourRight	 								= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 1, "right") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackSaturationPuckOneUp			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 2, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackSaturationPuckTwoUp			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 2, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackSaturationPuckThreeUp		 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 2, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackSaturationPuckFourUp		 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 2, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackSaturationPuckOneDown		 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 2, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackSaturationPuckTwoDown		 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 2, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackSaturationPuckThreeDown		 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 2, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackSaturationPuckFourDown	 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 2, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackExposurePuckOneUp			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 3, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackExposurePuckTwoUp			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 3, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackExposurePuckThreeUp		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 3, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackExposurePuckFourUp		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 3, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackExposurePuckOneDown		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 3, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackExposurePuckTwoDown		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 3, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackExposurePuckThreeDown		 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 3, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackExposurePuckFourDown	 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 3, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackChangeTimelineClipHeightUp 							= { characterString = "", 							modifiers = {}, 									fn = function() changeTimelineClipHeight("up") end, 				releasedFn = function() changeTimelineClipHeightRelease() end, 			repeatFn = nil },
			FCPXHackChangeTimelineClipHeightDown						= { characterString = "", 							modifiers = {}, 									fn = function() changeTimelineClipHeight("down") end, 				releasedFn = function() changeTimelineClipHeightRelease() end, 			repeatFn = nil },

			FCPXHackCreateOptimizedMediaOn								= { characterString = "", 							modifiers = {}, 									fn = function() toggleCreateOptimizedMedia(true) end, 				releasedFn = nil, 														repeatFn = nil },
			FCPXHackCreateOptimizedMediaOff								= { characterString = "", 							modifiers = {}, 									fn = function() toggleCreateOptimizedMedia(false) end, 				releasedFn = nil, 														repeatFn = nil },
			FCPXHackCreateMulticamOptimizedMediaOn						= { characterString = "", 							modifiers = {}, 									fn = function() toggleCreateMulticamOptimizedMedia(true) end, 		releasedFn = nil, 														repeatFn = nil },
			FCPXHackCreateMulticamOptimizedMediaOff						= { characterString = "", 							modifiers = {}, 									fn = function() toggleCreateMulticamOptimizedMedia(false) end, 		releasedFn = nil, 														repeatFn = nil },
			FCPXHackCreateProxyMediaOn									= { characterString = "", 							modifiers = {}, 									fn = function() toggleCreateProxyMedia(true) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackCreateProxyMediaOff									= { characterString = "", 							modifiers = {}, 									fn = function() toggleCreateProxyMedia(false) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackLeaveInPlaceOn										= { characterString = "", 							modifiers = {}, 									fn = function() toggleLeaveInPlace(true) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackLeaveInPlaceOff										= { characterString = "", 							modifiers = {}, 									fn = function() toggleLeaveInPlace(false) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackBackgroundRenderOn									= { characterString = "", 							modifiers = {}, 									fn = function() toggleBackgroundRender(true) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackBackgroundRenderOff									= { characterString = "", 							modifiers = {}, 									fn = function() toggleBackgroundRender(false) end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackChangeSmartCollectionsLabel							= { characterString = "", 							modifiers = {}, 									fn = function() changeSmartCollectionsLabel() end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackSelectSecondaryStorylineClipOne						= { characterString = "", 							modifiers = {}, 									fn = function() selectSecondaryStoryline(1) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectSecondaryStorylineClipTwo						= { characterString = "", 							modifiers = {}, 									fn = function() selectSecondaryStoryline(2) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectSecondaryStorylineClipThree					= { characterString = "", 							modifiers = {}, 									fn = function() selectSecondaryStoryline(3) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectSecondaryStorylineClipFour					= { characterString = "", 							modifiers = {}, 									fn = function() selectSecondaryStoryline(4) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectSecondaryStorylineClipFive					= { characterString = "", 							modifiers = {}, 									fn = function() selectSecondaryStoryline(5) end, 					releasedFn = nil, 														repeatFn = nil },

		}

		--------------------------------------------------------------------------------
		-- Merge Above Table with Built-in Final Cut Pro Shortcuts Table:
		--------------------------------------------------------------------------------
		for k, v in pairs(requiredBuiltInShortcuts) do
			finalCutProShortcutKeyPlaceholders[k] = requiredBuiltInShortcuts[k]
		end

		if readShortcutKeysFromPlist() ~= "Done" then
			displayMessage("Something went wrong when we were reading your custom keyboard shortcuts. As a fail-safe, we are going back to use using the default keyboard shortcuts, sorry!")
			print("[FCPX Hacks] ERROR: Something went wrong during the plist reading process. Falling back to default shortcut keys.")
			enableHacksShortcutsInFinalCutPro = false
		end
	end

	if not enableHacksShortcutsInFinalCutPro then
		--------------------------------------------------------------------------------
		-- Use Default Shortcuts Keys:
		--------------------------------------------------------------------------------
		finalCutProShortcutKey = nil
		finalCutProShortcutKey =
		{
			FCPXHackLaunchFinalCutPro 									= { characterString = keyCodeTranslator("l"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() launchFinalCutPro() end, 				 			releasedFn = nil,														repeatFn = nil, 		global = true },
			FCPXHackShowListOfShortcutKeys 								= { characterString = keyCodeTranslator("f1"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() displayShortcutList() end, 							releasedFn = nil, 														repeatFn = nil, 		global = true },

			FCPXHackHighlightBrowserPlayhead 							= { characterString = keyCodeTranslator("h"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() highlightFCPXBrowserPlayhead() end, 				releasedFn = nil, 														repeatFn = nil },
			FCPXHackRevealInBrowserAndHighlight 						= { characterString = keyCodeTranslator("f"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() matchFrameThenHighlightFCPXBrowserPlayhead() end, 	releasedFn = nil, 														repeatFn = nil },
			FCPXHackSingleMatchFrameAndHighlight 						= { characterString = keyCodeTranslator("s"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() singleMatchFrame() end, 							releasedFn = nil, 														repeatFn = nil },
			FCPXHackRevealMulticamClipInBrowserAndHighlight 			= { characterString = keyCodeTranslator("d"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() multicamMatchFrame(true) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackRevealMulticamClipInAngleEditorAndHighlight 		= { characterString = keyCodeTranslator("g"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() multicamMatchFrame(false) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackBatchExportFromBrowser 								= { characterString = keyCodeTranslator("e"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() batchExportToCompressor() end, 						releasedFn = nil,														repeatFn = nil },
			FCPXHackChangeBackupInterval 								= { characterString = keyCodeTranslator("b"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() changeBackupInterval() end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackToggleTimecodeOverlays 								= { characterString = keyCodeTranslator("t"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() toggleTimecodeOverlay() end,						releasedFn = nil, 														repeatFn = nil },
			FCPXHackToggleMovingMarkers 								= { characterString = keyCodeTranslator("y"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() toggleMovingMarkers() end, 							releasedFn = nil, 														repeatFn = nil },
			FCPXHackAllowTasksDuringPlayback 							= { characterString = keyCodeTranslator("p"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() togglePerformTasksDuringPlayback() end, 			releasedFn = nil, 														repeatFn = nil },

			FCPXHackSelectColorBoardPuckOne 							= { characterString = keyCodeTranslator("m"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() colorBoardSelectPuck(1) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectColorBoardPuckTwo 							= { characterString = keyCodeTranslator(","), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() colorBoardSelectPuck(2) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectColorBoardPuckThree 							= { characterString = keyCodeTranslator("."), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() colorBoardSelectPuck(3) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectColorBoardPuckFour 							= { characterString = keyCodeTranslator("/"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() colorBoardSelectPuck(4) end, 						releasedFn = nil, 														repeatFn = nil },

			FCPXHackRestoreKeywordPresetOne 							= { characterString = keyCodeTranslator("1"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() fcpxRestoreKeywordSearches(1) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetTwo 							= { characterString = keyCodeTranslator("2"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() fcpxRestoreKeywordSearches(2) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetThree 							= { characterString = keyCodeTranslator("3"),		modifiers = {"ctrl", "option", "command"}, 			fn = function() fcpxRestoreKeywordSearches(3) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetFour 							= { characterString = keyCodeTranslator("4"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() fcpxRestoreKeywordSearches(4) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetFive 							= { characterString = keyCodeTranslator("5"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() fcpxRestoreKeywordSearches(5) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetSix 							= { characterString = keyCodeTranslator("6"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() fcpxRestoreKeywordSearches(6) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetSeven 							= { characterString = keyCodeTranslator("7"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() fcpxRestoreKeywordSearches(7) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetEight 							= { characterString = keyCodeTranslator("8"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() fcpxRestoreKeywordSearches(8) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackRestoreKeywordPresetNine 							= { characterString = keyCodeTranslator("9"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() fcpxRestoreKeywordSearches(9) end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackSaveKeywordPresetOne 								= { characterString = keyCodeTranslator("1"), 		modifiers = {"ctrl", "option", "command", "shift"}, fn = function() fcpxSaveKeywordSearches(1) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetTwo 								= { characterString = keyCodeTranslator("2"), 		modifiers = {"ctrl", "option", "command", "shift"}, fn = function() fcpxSaveKeywordSearches(2) end,						releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetThree 								= { characterString = keyCodeTranslator("3"), 		modifiers = {"ctrl", "option", "command", "shift"}, fn = function() fcpxSaveKeywordSearches(3) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetFour 								= { characterString = keyCodeTranslator("4"), 		modifiers = {"ctrl", "option", "command", "shift"}, fn = function() fcpxSaveKeywordSearches(4) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetFive 								= { characterString = keyCodeTranslator("5"), 		modifiers = {"ctrl", "option", "command", "shift"}, fn = function() fcpxSaveKeywordSearches(5) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetSix 								= { characterString = keyCodeTranslator("6"), 		modifiers = {"ctrl", "option", "command", "shift"}, fn = function() fcpxSaveKeywordSearches(6) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetSeven 								= { characterString = keyCodeTranslator("7"), 		modifiers = {"ctrl", "option", "command", "shift"}, fn = function() fcpxSaveKeywordSearches(7) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetEight 								= { characterString = keyCodeTranslator("8"), 		modifiers = {"ctrl", "option", "command", "shift"}, fn = function() fcpxSaveKeywordSearches(8) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaveKeywordPresetNine 								= { characterString = keyCodeTranslator("9"), 		modifiers = {"ctrl", "option", "command", "shift"}, fn = function() fcpxSaveKeywordSearches(9) end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackEffectsOne			 								= { characterString = keyCodeTranslator("1"), 		modifiers = {"ctrl", "shift"}, 						fn = function() effectsShortcut(1) end, 							releasedFn = nil, 														repeatFn = nil },
			FCPXHackEffectsTwo			 								= { characterString = keyCodeTranslator("2"), 		modifiers = {"ctrl", "shift"}, 						fn = function() effectsShortcut(2) end, 							releasedFn = nil, 														repeatFn = nil },
			FCPXHackEffectsThree			 							= { characterString = keyCodeTranslator("3"), 		modifiers = {"ctrl", "shift"}, 						fn = function() effectsShortcut(3) end, 							releasedFn = nil, 														repeatFn = nil },
			FCPXHackEffectsFour			 								= { characterString = keyCodeTranslator("4"), 		modifiers = {"ctrl", "shift"}, 						fn = function() effectsShortcut(4) end, 							releasedFn = nil, 														repeatFn = nil },
			FCPXHackEffectsFive			 								= { characterString = keyCodeTranslator("5"), 		modifiers = {"ctrl", "shift"}, 						fn = function() effectsShortcut(5) end, 							releasedFn = nil, 														repeatFn = nil },

			FCPXHackScrollingTimeline	 								= { characterString = keyCodeTranslator("w"), 		modifiers = {"ctrl", "option", "command"}, 			fn = function() toggleScrollingTimeline() end, 						releasedFn = nil, 														repeatFn = nil },

			FCPXHackColorPuckOne			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 1) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackColorPuckTwo			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 1) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackColorPuckThree			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 1) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackColorPuckFour			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 1) end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackSaturationPuckOne			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 2) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaturationPuckTwo			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 2) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaturationPuckThree			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 2) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSaturationPuckFour			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 2) end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackExposurePuckOne			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 3) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackExposurePuckTwo			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 3) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackExposurePuckThree			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 3) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackExposurePuckFour			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 3) end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackColorPuckOneUp			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 1, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckTwoUp			 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 1, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckThreeUp		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 1, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckFourUp		 								= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 1, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackColorPuckOneDown		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 1, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckTwoDown		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 1, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckThreeDown		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 1, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckFourDown	 								= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 1, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackColorPuckOneLeft		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 1, "left") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckTwoLeft		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 1, "left") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckThreeLeft		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 1, "left") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckFourLeft	 								= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 1, "left") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackColorPuckOneRight		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 1, "right") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckTwoRight		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 1, "right") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckThreeRight		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 1, "right") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackColorPuckFourRight	 								= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 1, "right") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackSaturationPuckOneUp			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 2, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackSaturationPuckTwoUp			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 2, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackSaturationPuckThreeUp		 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 2, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackSaturationPuckFourUp		 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 2, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackSaturationPuckOneDown		 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 2, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackSaturationPuckTwoDown		 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 2, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackSaturationPuckThreeDown		 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 2, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackSaturationPuckFourDown	 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 2, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackExposurePuckOneUp			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 3, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackExposurePuckTwoUp			 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 3, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackExposurePuckThreeUp		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 3, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackExposurePuckFourUp		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 3, "up") end, 				releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackExposurePuckOneDown		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(1, 3, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackExposurePuckTwoDown		 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(2, 3, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackExposurePuckThreeDown		 						= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(3, 3, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },
			FCPXHackExposurePuckFourDown	 							= { characterString = "", 							modifiers = {}, 									fn = function() colorBoardSelectPuck(4, 3, "down") end, 			releasedFn = function() colorBoardSelectPuckRelease() end, 				repeatFn = nil },

			FCPXHackChangeTimelineClipHeightUp 							= { characterString = keyCodeTranslator("+"),		modifiers = {"ctrl", "option", "command"}, 			fn = function() changeTimelineClipHeight("up") end, 				releasedFn = function() changeTimelineClipHeightRelease() end, 			repeatFn = nil },
			FCPXHackChangeTimelineClipHeightDown						= { characterString = keyCodeTranslator("-"),		modifiers = {"ctrl", "option", "command"}, 			fn = function() changeTimelineClipHeight("down") end, 				releasedFn = function() changeTimelineClipHeightRelease() end, 			repeatFn = nil },

			FCPXHackCreateOptimizedMediaOn								= { characterString = "", 							modifiers = {}, 									fn = function() toggleCreateOptimizedMedia(true) end, 				releasedFn = nil, 														repeatFn = nil },
			FCPXHackCreateOptimizedMediaOff								= { characterString = "", 							modifiers = {}, 									fn = function() toggleCreateOptimizedMedia(false) end, 				releasedFn = nil, 														repeatFn = nil },
			FCPXHackCreateMulticamOptimizedMediaOn						= { characterString = "", 							modifiers = {}, 									fn = function() toggleCreateMulticamOptimizedMedia(true) end, 		releasedFn = nil, 														repeatFn = nil },
			FCPXHackCreateMulticamOptimizedMediaOff						= { characterString = "", 							modifiers = {}, 									fn = function() toggleCreateMulticamOptimizedMedia(false) end, 		releasedFn = nil, 														repeatFn = nil },
			FCPXHackCreateProxyMediaOn									= { characterString = "", 							modifiers = {}, 									fn = function() toggleCreateProxyMedia(true) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackCreateProxyMediaOff									= { characterString = "", 							modifiers = {}, 									fn = function() toggleCreateProxyMedia(false) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackLeaveInPlaceOn										= { characterString = "", 							modifiers = {}, 									fn = function() toggleLeaveInPlace(true) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackLeaveInPlaceOff										= { characterString = "", 							modifiers = {}, 									fn = function() toggleLeaveInPlace(false) end, 						releasedFn = nil, 														repeatFn = nil },
			FCPXHackBackgroundRenderOn									= { characterString = "", 							modifiers = {}, 									fn = function() toggleBackgroundRender(true) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackBackgroundRenderOff									= { characterString = "", 							modifiers = {}, 									fn = function() toggleBackgroundRender(false) end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackChangeSmartCollectionsLabel							= { characterString = "", 							modifiers = {}, 									fn = function() changeSmartCollectionsLabel() end, 					releasedFn = nil, 														repeatFn = nil },

			FCPXHackSelectSecondaryStorylineClipOne						= { characterString = "", 							modifiers = {}, 									fn = function() selectSecondaryStoryline(1) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectSecondaryStorylineClipTwo						= { characterString = "", 							modifiers = {}, 									fn = function() selectSecondaryStoryline(2) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectSecondaryStorylineClipThree					= { characterString = "", 							modifiers = {}, 									fn = function() selectSecondaryStoryline(3) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectSecondaryStorylineClipFour					= { characterString = "", 							modifiers = {}, 									fn = function() selectSecondaryStoryline(4) end, 					releasedFn = nil, 														repeatFn = nil },
			FCPXHackSelectSecondaryStorylineClipFive					= { characterString = "", 							modifiers = {}, 									fn = function() selectSecondaryStoryline(5) end, 					releasedFn = nil, 														repeatFn = nil },

		}

		--------------------------------------------------------------------------------
		-- Get Values of Shortcuts built into Final Cut Pro:
		--------------------------------------------------------------------------------
		finalCutProShortcutKeyPlaceholders = requiredBuiltInShortcuts
		readShortcutKeysFromPlist()

	end

	--------------------------------------------------------------------------------
	-- Reset Modal Hotkey for Final Cut Pro Commands:
	--------------------------------------------------------------------------------
	hotkeys = nil

	--------------------------------------------------------------------------------
	-- Reset Global Hotkeys:
	--------------------------------------------------------------------------------
	local currentHotkeys = hs.hotkey.getHotkeys()
	for i=1, #currentHotkeys do
		result = currentHotkeys[i]:delete()
	end

	--------------------------------------------------------------------------------
	-- Create a modal hotkey object with an absurd triggering hotkey:
	--------------------------------------------------------------------------------
	hotkeys = hs.hotkey.modal.new({"command", "shift", "alt", "control"}, "F19")

	--------------------------------------------------------------------------------
	-- Enable Hotkeys Loop:
	--------------------------------------------------------------------------------
	for k, v in pairs(finalCutProShortcutKey) do
		if finalCutProShortcutKey[k]['characterString'] ~= "" and finalCutProShortcutKey[k]['fn'] ~= nil then
			if finalCutProShortcutKey[k]['global'] == true then
				--------------------------------------------------------------------------------
				-- Global Shortcut:
				--------------------------------------------------------------------------------
				hs.hotkey.bind(finalCutProShortcutKey[k]['modifiers'], finalCutProShortcutKey[k]['characterString'], finalCutProShortcutKey[k]['fn'])
			else
				--------------------------------------------------------------------------------
				-- Final Cut Pro Specific Shortcut:
				--------------------------------------------------------------------------------
				hotkeys:bind(finalCutProShortcutKey[k]['modifiers'], finalCutProShortcutKey[k]['characterString'], finalCutProShortcutKey[k]['fn'], finalCutProShortcutKey[k]['releasedFn'], finalCutProShortcutKey[k]['repeatFn'])
			end
		end
	end

	--------------------------------------------------------------------------------
	-- Development Shortcut:
	--------------------------------------------------------------------------------
	if debugMode then
		hs.hotkey.bind({"ctrl", "option", "command"}, "q", function() testingGround() end)
	end

	--------------------------------------------------------------------------------
	-- Enable Hotkeys:
	--------------------------------------------------------------------------------
	hotkeys:enter()

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     M E N U B A R    F E A T U R E S                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- REFRESH MENUBAR:
--------------------------------------------------------------------------------
function refreshMenuBar(refreshPlistValues)

	--------------------------------------------------------------------------------
	-- Local Variables:
	--------------------------------------------------------------------------------
	local FFImportCreateProxyMedia 					= false
	local allowMovingMarkers 						= false
	local FFPeriodicBackupInterval 					= "15"
	local FFSuspendBGOpsDuringPlay 					= false
	local FFEnableGuards 							= false
	local FFCreateOptimizedMediaForMulticamClips 	= true
	local FFAutoStartBGRender 						= true
	local FFAutoRenderDelay 						= "0.3"
	local FFImportCopyToMediaFolder 				= true
	local FFImportCreateOptimizeMedia 				= false

	--------------------------------------------------------------------------------
	-- Assume FCPX is closed if not told otherwise:
	--------------------------------------------------------------------------------
	local fcpxActive = isFinalCutProFrontmost()

	--------------------------------------------------------------------------------
	-- We only refresh plist's if necessary as they take time:
	--------------------------------------------------------------------------------
	if refreshPlistValues == nil then refreshPlistValues = false end
	if refreshPlistValues == true then

		--------------------------------------------------------------------------------
		-- Get plist values for Allow Moving Markers:
		--------------------------------------------------------------------------------
		local executeResult,executeStatus = hs.execute("/usr/libexec/PlistBuddy -c \"Print :TLKMarkerHandler:Configuration:'Allow Moving Markers'\" '/Applications/Final Cut Pro.app/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist'")
		if trim(executeResult) == "true" then allowMovingMarkers = true end

		--------------------------------------------------------------------------------
		-- Get plist values for FFPeriodicBackupInterval:
		--------------------------------------------------------------------------------
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFPeriodicBackupInterval")
		if trim(executeResult) ~= "" then FFPeriodicBackupInterval = executeResult end

		--------------------------------------------------------------------------------
		-- Get plist values for FFSuspendBGOpsDuringPlay:
		--------------------------------------------------------------------------------
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFSuspendBGOpsDuringPlay")
		if trim(executeResult) == "1" then FFSuspendBGOpsDuringPlay = true end

		--------------------------------------------------------------------------------
		-- Get plist values for FFEnableGuards:
		--------------------------------------------------------------------------------
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFEnableGuards")
		if trim(executeResult) == "1" then FFEnableGuards = true end

		--------------------------------------------------------------------------------
		-- Get plist values for FFCreateOptimizedMediaForMulticamClips:
		--------------------------------------------------------------------------------
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFCreateOptimizedMediaForMulticamClips")
		if trim(executeResult) == "0" then FFCreateOptimizedMediaForMulticamClips = false end

		--------------------------------------------------------------------------------
		-- Get plist values for FFAutoStartBGRender:
		--------------------------------------------------------------------------------
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFAutoStartBGRender")
		if trim(executeResult) == "0" then FFAutoStartBGRender = false end

		--------------------------------------------------------------------------------
		-- Get plist values for FFAutoRenderDelay:
		--------------------------------------------------------------------------------
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFAutoRenderDelay")
		if executeStatus == true then FFAutoRenderDelay = trim(executeResult) end

		--------------------------------------------------------------------------------
		-- Get plist values for FFImportCopyToMediaFolder:
		--------------------------------------------------------------------------------
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFImportCopyToMediaFolder")
		if trim(executeResult) == "0" then FFImportCopyToMediaFolder = false end

		--------------------------------------------------------------------------------
		-- Get plist values for FFImportCreateOptimizeMedia:
		--------------------------------------------------------------------------------
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFImportCreateOptimizeMedia")
		if trim(executeResult) == "1" then FFImportCreateOptimizeMedia = true end

		--------------------------------------------------------------------------------
		-- Get plist values for FFImportCreateProxyMedia:
		--------------------------------------------------------------------------------
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFImportCreateProxyMedia")
		if trim(executeResult) == "1" then FFImportCreateProxyMedia = true end

	end

	--------------------------------------------------------------------------------
	-- Get Menubar Display Mode from Settings:
	--------------------------------------------------------------------------------
	local displayMenubarAsIcon = hs.settings.get("fcpxHacks.displayMenubarAsIcon") or false

	--------------------------------------------------------------------------------
	-- Get Sizing Preferences:
	--------------------------------------------------------------------------------
	local displayHighlightShape = nil
	displayHighlightShape = hs.settings.get("fcpxHacks.displayHighlightShape")
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
	displayHighlightColour = hs.settings.get("fcpxHacks.displayHighlightColour")
	local displayHighlightColourRed = false
	local displayHighlightColourBlue = false
	local displayHighlightColourGreen = false
	local displayHighlightColourYellow = false
	if displayHighlightColour == nil then 		displayHighlightColourRed 		= true 		end
	if displayHighlightColour == "Red" then 	displayHighlightColourRed 		= true 		end
	if displayHighlightColour == "Blue" then 	displayHighlightColourBlue 		= true 		end
	if displayHighlightColour == "Green" then 	displayHighlightColourGreen 	= true 		end
	if displayHighlightColour == "Yellow" then 	displayHighlightColourYellow	= true 		end

	--------------------------------------------------------------------------------
	-- Get Enable Shortcuts During Fullscreen Playback from Settings:
	--------------------------------------------------------------------------------
	local enableShortcutsDuringFullscreenPlayback = hs.settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") or false

	--------------------------------------------------------------------------------
	-- Get Enable Hacks Shortcuts in Final Cut Pro from Settings:
	--------------------------------------------------------------------------------
	local enableHacksShortcutsInFinalCutPro = hs.settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro") or false

	--------------------------------------------------------------------------------
	-- Get Effects List Updated from Settings:
	--------------------------------------------------------------------------------
	local effectsListUpdated = hs.settings.get("fcpxHacks.effectsListUpdated") or false

	--------------------------------------------------------------------------------
	-- Get Enable Proxy Menu Item:
	--------------------------------------------------------------------------------
	local enableProxyMenuIcon = hs.settings.get("fcpxHacks.enableProxyMenuIcon") or false

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
	scrollingTimelineActive = hs.settings.get("fcpxHacks.scrollingTimelineActive") or false

	--------------------------------------------------------------------------------
	-- Enable Clipboard History:
	--------------------------------------------------------------------------------
	enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false

	--------------------------------------------------------------------------------
	-- Enable Mobile Notifications:
	--------------------------------------------------------------------------------
	enableMobileNotifications = settings.get("fcpxHacks.enableMobileNotifications") or false

	--------------------------------------------------------------------------------
	-- Clipboard History Menu:
	--------------------------------------------------------------------------------
	local settingsClipboardHistoryTable = {}
	if enableClipboardHistory then
		if clipboardHistory ~= nil then
			if #clipboardHistory ~= 0 then
				for i=#clipboardHistory, 1, -1 do
					table.insert(settingsClipboardHistoryTable, {title = clipboardHistory[i][2], fn = function() finalCutProPasteFromClipboardHistory(clipboardHistory[i][1]) end, disabled = not fcpxActive})
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
	-- Setup Menu:
	--------------------------------------------------------------------------------
	local settingsShapeMenuTable = {
	   	{ title = "Rectangle", 																		fn = function() changeHighlightShape("Rectangle") end,				checked = displayHighlightShapeRectangle	},
	   	{ title = "Circle", 																		fn = function() changeHighlightShape("Circle") end, 				checked = displayHighlightShapeCircle		},
	   	{ title = "Diamond", 																		fn = function() changeHighlightShape("Diamond") end, 				checked = displayHighlightShapeDiamond		},
	}
	local settingsColourMenuTable = {
	   	{ title = "Red", 																			fn = function() changeHighlightColour("Red") end, 					checked = displayHighlightColourRed		},
	   	{ title = "Blue", 																			fn = function() changeHighlightColour("Blue") end, 					checked = displayHighlightColourBlue	},
	   	{ title = "Green", 																			fn = function() changeHighlightColour("Green") end, 				checked = displayHighlightColourGreen	},
	   	{ title = "Yellow", 																		fn = function() changeHighlightColour("Yellow") end, 				checked = displayHighlightColourYellow	},
	}
	local settingsHammerspoonSettings = {
		{ title = "Console...", 																	fn = openHammerspoonConsole },
		{ title = "-" },
		{ title = "-" },
		{ title = "Show Dock Icon", 																fn = toggleHammerspoonDockIcon, 									checked = hammerspoonDockIcon		},
		{ title = "Show Menu Icon", 																fn = toggleHammerspoonMenuIcon, 									checked = hammerspoonMenuIcon		},
		{ title = "-" },
	   	{ title = "Launch at Startup", 																fn = toggleLaunchHammerspoonOnStartup, 								checked = startHammerspoonOnLaunch		},
	   	{ title = "Check for Updates", 																fn = toggleCheckforHammerspoonUpdates, 								checked = hammerspoonCheckForUpdates	},
	}
	local settingsMenuTable = {
		{ title = "Enable Hacks Shortcuts in Final Cut Pro", 										fn = toggleEnableHacksShortcutsInFinalCutPro, 						checked = enableHacksShortcutsInFinalCutPro},
	   	{ title = "Enable Shortcuts During Fullscreen Playback", 									fn = toggleEnableShortcutsDuringFullscreenPlayback, 				checked = enableShortcutsDuringFullscreenPlayback},
	   	{ title = "Enable Clipboard History", 														fn = toggleEnableClipboardHistory, 									checked = enableClipboardHistory, 							disabled = disablePasteboard},
	   	{ title = "Enable Mobile Notifications", 													fn = toggleEnableMobileNotifications, 								checked = enableMobileNotifications},
	   	{ title = "-" },
	   	{ title = "Highlight Playhead Colour", 														menu = settingsColourMenuTable},
	   	{ title = "Highlight Playhead Shape", 														menu = settingsShapeMenuTable},
       	{ title = "-" },
	   	{ title = "Display Proxy/Original Icon", 													fn = toggleEnableProxyMenuIcon, 									checked = enableProxyMenuIcon},
	   	{ title = "Display This Menu As Icon", 														fn = toggleMenubarDisplayMode, 										checked = displayMenubarAsIcon},
      	{ title = "-" },
		{ title = "Trash FCPX Hacks Preferences", 													fn = resetSettings },
    	{ title = "-" },
    	{ title = "Created by LateNite Films", 														fn = gotoLateNiteSite },
  	    { title = "Script Version " .. scriptVersion, 																																												disabled = true },
	}
	local settingsEffectsShortcutsTable = {
		{ title = "Update Effects List", 															fn = updateEffectsList, 																										disabled = not fcpxActive },
		{ title = "-" },
		{ title = "Assign Effects Shortcut 1", 														fn = function() assignEffectsShortcut(1) end, 																					disabled = not effectsListUpdated },
		{ title = "Assign Effects Shortcut 2", 														fn = function() assignEffectsShortcut(2) end, 																					disabled = not effectsListUpdated },
		{ title = "Assign Effects Shortcut 3", 														fn = function() assignEffectsShortcut(3) end, 																					disabled = not effectsListUpdated },
		{ title = "Assign Effects Shortcut 4", 														fn = function() assignEffectsShortcut(4) end, 																					disabled = not effectsListUpdated },
		{ title = "Assign Effects Shortcut 5", 														fn = function() assignEffectsShortcut(5) end, 																					disabled = not effectsListUpdated },
	}
	local menuTable = {
	   	{ title = "Open Final Cut Pro", 															fn = launchFinalCutPro },
		{ title = "-" },
   	    { title = "SHORTCUTS:", 																																																	disabled = true },
	    { title = "Create Optimized Media", 														fn = toggleCreateOptimizedMedia, 									checked = FFImportCreateOptimizeMedia, 						disabled = not fcpxActive },
	    { title = "Create Multicam Optimized Media", 												fn = toggleCreateMulticamOptimizedMedia, 							checked = FFCreateOptimizedMediaForMulticamClips, 			disabled = not fcpxActive },
	    { title = "Create Proxy Media", 															fn = toggleCreateProxyMedia, 										checked = FFImportCreateProxyMedia, 						disabled = not fcpxActive },
	    { title = "Leave Files In Place On Import", 												fn = toggleLeaveInPlace, 											checked = not FFImportCopyToMediaFolder, 					disabled = not fcpxActive },
	    { title = "Enable Background Render (" .. FFAutoRenderDelay .. " secs)", 					fn = toggleBackgroundRender, 										checked = FFAutoStartBGRender, 								disabled = not fcpxActive },
   	    { title = "-" },
 	    { title = "AUTOMATION:", 																																																	disabled = true },
   	    { title = "Enable Scrolling Timeline", 														fn = toggleScrollingTimeline, 										checked = scrollingTimelineActive },
   	    { title = "Effects Shortcuts", 																menu = settingsEffectsShortcutsTable },
      	{ title = "-" },
   	    { title = "TOOLS:", 																																																		disabled = true },
      	{ title = "Paste from Clipboard History", 													menu = settingsClipboardHistoryTable },
      	{ title = "-" },
   	    { title = "HACKS:", 																																																		disabled = true },
   	    { title = "Enable Timecode Overlay", 														fn = toggleTimecodeOverlay, 										checked = FFEnableGuards },
	   	{ title = "Enable Moving Markers", 															fn = toggleMovingMarkers, 											checked = allowMovingMarkers },
       	{ title = "Enable Rendering During Playback", 												fn = togglePerformTasksDuringPlayback, 								checked = not FFSuspendBGOpsDuringPlay },
        { title = "Change Backup Interval (" .. tostring(FFPeriodicBackupInterval) .. " mins)", 	fn = changeBackupInterval },
   	   	{ title = "Change Smart Collections Label", 												fn = changeSmartCollectionsLabel },
        { title = "-" },
      	{ title = "FCPX Hacks Settings", 															menu = settingsMenuTable },
      	{ title = "Hammerspoon Settings", 															menu = settingsHammerspoonSettings},
   	    { title = "-" },
      	{ title = "Show Keyboard Shortcuts", 														fn = displayShortcutList },
    	{ title = "-" },
    	{ title = "Quit FCPX Hacks", 																fn = quitFCPXHacks},
	}

	--------------------------------------------------------------------------------
	-- Check for Updates:
	--------------------------------------------------------------------------------
	if latestScriptVersion == nil then
		-- Do Nothing.
	else
		if latestScriptVersion > scriptVersion then
			table.insert(menuTable, 1, { title = "UPDATE AVAILABLE (Version " .. latestScriptVersion .. ")", fn = getScriptUpdate})
			table.insert(menuTable, 2, { title = "-" })
		end
	end

	--------------------------------------------------------------------------------
	-- Set the Menu:
	--------------------------------------------------------------------------------
	fcpxMenubar:setMenu(menuTable)
end

--------------------------------------------------------------------------------
-- DISPLAY A LIST OF ALL SHORTCUTS:
--------------------------------------------------------------------------------
function displayShortcutList()

	local enableHacksShortcutsInFinalCutPro = hs.settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro")
	if enableHacksShortcutsInFinalCutPro == nil then enableHacksShortcutsInFinalCutPro = false end

	if enableHacksShortcutsInFinalCutPro then
		displayMessage("As you have enabled Hacks Shortcuts within the settings, you can refer to the Command Editor within Final Cut Pro review and change the shortcut selections.")
	else
		local whatMessage = [[The default FCPX Hacks Shortcut Keys are:

---------------------------------
CONTROL+OPTION+COMMAND:
---------------------------------
L = Launch Final Cut Pro (System Wide)

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

		displayMessage(whatMessage)
	end
end

--------------------------------------------------------------------------------
-- TOGGLE CLIPBOARD HISTORY:
--------------------------------------------------------------------------------
function toggleEnableClipboardHistory()
	local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false
	if not enableClipboardHistory then
		clipboardWatcher()
	else
		clipboardTimer:stop()
	end
	settings.set("fcpxHacks.enableClipboardHistory", not enableClipboardHistory)
	refreshMenuBar()
end

--------------------------------------------------------------------------------
-- TOGGLE MOBILE NOTIFICATIONS:
--------------------------------------------------------------------------------
function toggleEnableMobileNotifications()
	local enableMobileNotifications 	= settings.get("fcpxHacks.enableMobileNotifications") or false
	local prowlAPIKey 					= settings.get("fcpxHacks.prowlAPIKey") or ""

	if not enableMobileNotifications then

		local returnToFinalCutPro = isFinalCutProFrontmost()
		::retryProwlAPIKeyEntry::
		local appleScriptA = 'set defaultAnswer to "' .. prowlAPIKey .. '"' .. '\n\n'
		local appleScriptB = [[
			set allowedLetters to characters of (do shell script "printf \"%c\" {a..z}")
			set allowedNumbers to characters of (do shell script "printf \"%c\" {0..9}")
			set allowedAll to allowedLetters & allowedNumbers

			repeat
				try
					tell me to activate
					set response to text returned of (display dialog "Please enter your Prowl API key below.\n\nIf you don't have one you can register for free at prowlapp.com." default answer defaultAnswer buttons {"OK", "Cancel"} default button 1 with icon fcpxIcon)
				on error
					-- Cancel Pressed:
					return false
				end try
				try
					set invalidCharacters to false
					repeat with aCharacter in response
						if (aCharacter as text) is not in allowedAll then
							set invalidCharacters to true
						end if
					end repeat
					if length of response is 0 then
						set invalidCharacters to true
					end if
					if invalidCharacters is false then
						exit repeat
					end
				end try
				display dialog "The Prowl API Key you entered is not valid.\n\nPlease try again." buttons {"OK"} with icon fcpxIcon
			end repeat
			return response
		]]
		a,result = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB)
		if result == false then
			return "Cancel"
		end
		local prowlAPIKeyValidResult, prowlAPIKeyValidError = prowlAPIKeyValid(result)
		if prowlAPIKeyValidResult then
			if returnToFinalCutPro then launchFinalCutPro() end
			settings.set("fcpxHacks.prowlAPIKey", result)
			notificationWatcher()
			settings.set("fcpxHacks.enableMobileNotifications", not enableMobileNotifications)
		else
			displayMessage("The Prowl API Key failed to validate due to the following error: " .. prowlAPIKeyValidError .. ".\n\nPlease try again.")
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
-- UPDATE KEYBOARD SHORTCUTS:
--------------------------------------------------------------------------------
function updateKeyboardShortcuts()
	--------------------------------------------------------------------------------
	-- Revert back to default keyboard layout:
	--------------------------------------------------------------------------------
	local executeResult,executeStatus = hs.execute("defaults write ~/Library/Preferences/com.apple.FinalCut.plist 'Active Command Set' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset'")

	--------------------------------------------------------------------------------
	-- Update Keyboard Settings:
	--------------------------------------------------------------------------------
	local appleScriptA = [[
		--------------------------------------------------------------------------------
		-- Replace Files:
		--------------------------------------------------------------------------------
		try
			tell me to activate
			do shell script "cp -f ~/.hammerspoon/hs/fcpx/new/NSProCommandGroups.plist '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist'" with administrator privileges
		on error
			display dialog commonErrorMessageStart & "Failed to replace NSProCommandGroups.plist." & commonErrorMessageEnd buttons {"Close"} with icon caution
			return "Failed"
		end try
		try
			do shell script "cp -f ~/.hammerspoon/hs/fcpx/new/NSProCommands.plist '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommands.plist'" with administrator privileges
		on error
			display dialog commonErrorMessageStart & "Failed to replace NSProCommands.plist." & commonErrorMessageEnd buttons {"Close"} with icon caution
			return "Failed"
		end try
		try
			do shell script "cp -f ~/.hammerspoon/hs/fcpx/new/en.lproj/Default.commandset '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset'" with administrator privileges
		on error
			display dialog commonErrorMessageStart & "Failed to replace Default.commandset." & commonErrorMessageEnd buttons {"Close"} with icon caution
			return "Failed"
		end try
		try
			do shell script "cp -f ~/.hammerspoon/hs/fcpx/new/en.lproj/NSProCommandDescriptions.strings '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings'" with administrator privileges
		on error
			display dialog commonErrorMessageStart & "Failed to replace NSProCommandDescriptions.strings." & commonErrorMessageEnd buttons {"Close"} with icon caution
			return "Failed"
		end try
		try
			do shell script "cp -f ~/.hammerspoon/hs/fcpx/new/en.lproj/NSProCommandNames.strings '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings'" with administrator privileges
		on error
			display dialog commonErrorMessageStart & "Failed to replace NSProCommandNames.strings." & commonErrorMessageEnd buttons {"Close"} with icon caution
			return "Failed"
		end try

		return "Done"
	]]
	ok,toggleEnableHacksShortcutsInFinalCutProResult = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA)
	return toggleEnableHacksShortcutsInFinalCutProResult
end

--------------------------------------------------------------------------------
-- QUIT FCPX HACKS:
--------------------------------------------------------------------------------
function quitFCPXHacks()
	hs.application("Hammerspoon"):kill()
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
-- OPEN HAMMERSPOON CONSOLE:
--------------------------------------------------------------------------------
function openHammerspoonConsole()
	hs.openConsole()
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
-- RESET SETTINGS:
--------------------------------------------------------------------------------
function resetSettings()

	local finalCutProRunning = isFinalCutProRunning()

	local resetMessage = "Are you sure you want to trash the FCPX Hacks Preferences?"
	if finalCutProRunning then
		resetMessage = resetMessage .. "\n\nThis will require your Administrator password and require Final Cut Pro to restart."
	else
		resetMessage = resetMessage .. "\n\nThis will require your Administrator password."
	end

	if displayYesNoQuestion(resetMessage) then

		--------------------------------------------------------------------------------
		-- Remove Hacks Shortcut in Final Cut Pro:
		--------------------------------------------------------------------------------
		local removeHacksResult = true
		local appleScriptA = [[
			--------------------------------------------------------------------------------
			-- Replace Files:
			--------------------------------------------------------------------------------
			try
				tell me to activate
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/old/NSProCommandGroups.plist '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist'" with administrator privileges
			on error
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/old/NSProCommands.plist '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommands.plist'" with administrator privileges
			on error
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/old/en.lproj/Default.commandset '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset'" with administrator privileges
			on error
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/old/en.lproj/NSProCommandDescriptions.strings '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings'" with administrator privileges
			on error
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/old/en.lproj/NSProCommandNames.strings '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings'" with administrator privileges
			on error
				return "Failed"
			end try

			return "Done"
		]]
		ok,toggleEnableHacksShortcutsInFinalCutProResult = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA)
		if toggleEnableHacksShortcutsInFinalCutProResult ~= "Done" then
			displayErrorMessage("Failed to restore keyboard layouts. Something has gone wrong! Aborting reset.")
		else
			removeHacksResult = true
		end

		if removeHacksResult then

			--------------------------------------------------------------------------------
			-- Trash all FCPX Hacks Settings:
			--------------------------------------------------------------------------------
			for i, v in ipairs(hs.settings.getKeys()) do
				if (v:sub(1,10)) == "fcpxHacks." then
					hs.settings.set(v, nil)
				end
			end

			--------------------------------------------------------------------------------
			-- Restart Final Cut Pro if running:
			--------------------------------------------------------------------------------
			if finalCutProRunning then
				if not restartFinalCutPro() then
					--------------------------------------------------------------------------------
					-- Failed to restart Final Cut Pro:
					--------------------------------------------------------------------------------
					displayMessage("We weren't able to restart Final Cut Pro.\n\nPlease restart Final Cut Pro manually.")
				end
			end

			--------------------------------------------------------------------------------
			-- Reload Hammerspoon:
			--------------------------------------------------------------------------------
			hs.reload()

		end --removeHacksResult
	end -- displayYesNoQuestion(resetMessage)
end

--------------------------------------------------------------------------------
-- GET LIST OF EFFECTS:
--------------------------------------------------------------------------------
function updateEffectsList()

	--------------------------------------------------------------------------------
	-- Warning message:
	--------------------------------------------------------------------------------
	displayMessage("Depending on how many effects you have installed this might take a while.\n\nPlease do not use your mouse or keyboard until you're notified that this process is complete.")

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	sw = ax.windowElement(hs.application("Final Cut Pro"):mainWindow())

	--------------------------------------------------------------------------------
	-- Make sure Video Effects panel is open:
	--------------------------------------------------------------------------------
	-- PATH:
	-- AXApplication "Final Cut Pro"
	-- AXWindow "Final Cut Pro" (window 1)
	-- AXSplitGroup (splitter group 1)
	-- AXGroup (group 3)
	-- AXRadioGroup (radio group 3)
	-- AXRadioButton (radio button 1)
	-- AXHelp = "Show or hide the Effects Browser - ⌘5"
	effectsBrowserButton = sw:searchPath({
		{ role = "AXWindow"},
		{ role = "AXSplitGroup" },
		{ role = "AXGroup", },
		{ role = "AXRadioGroup" },
		{ role = "AXRadioButton", Help = "Show or hide the Effects Browser - ⌘5"}
	}, 1)
	if effectsBrowserButton ~= nil then
		if effectsBrowserButton:attributeValue("AXValue") == 0 then
			local presseffectsBrowserButtonResult = effectsBrowserButton:performAction("AXPress")
			if presseffectsBrowserButtonResult == nil then
				displayErrorMessage("Unable to press Video Effects icon.")
				return "Fail"
			end
		end
	else
		displayErrorMessage("Unable to activate Video Effects Panel.")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	-- AXApplication "Final Cut Pro"
	-- AXWindow "Final Cut Pro" (window 1)
	-- AXSplitGroup (splitter group 1)
	-- AXGroup (group 1)
	-- AXGroup (group 1)
	-- AXTextField (text field 1)
	-- AXButton (button 2)
	effectsSearchCancelButton = sw:searchPath({
		{ role = "AXWindow", title = "Final Cut Pro"},
		{ role = "AXSplitGroup" },
		{ role = "AXGroup", },
		{ role = "AXGroup", },
		{ role = "AXTextField", Description = "Effect Library Search Field" },
		{ role = "AXButton", Description = "cancel"},
	}, 1)
	if effectsSearchCancelButton ~= nil then
		effectsSearchCancelButtonResult = effectsSearchCancelButton:performAction("AXPress")
		if effectsSearchCancelButtonResult == nil then
			displayErrorMessage("Unable to cancel effects search.")
			return "Fail"
		end
	end

	--------------------------------------------------------------------------------
	-- Make sure scroll bar is all the way to the top:
	--------------------------------------------------------------------------------
	-- PATH:
	-- AXApplication "Final Cut Pro"
	-- AXWindow "Final Cut Pro" (window 1)
	-- AXSplitGroup (splitter group 1)
	-- AXGroup (group 1)
	-- AXGroup (group 1)
	-- AXSplitGroup (splitter group 1)
	-- AXScrollArea (scroll area 1)
	-- AXScrollBar (scroll bar 1)
	-- AXValueIndicator (value indicator 1)
	effectsScrollbar = sw:searchPath({
		{ role = "AXWindow", title = "Final Cut Pro"},
		{ role = "AXSplitGroup" },
		{ role = "AXGroup" },
		{ role = "AXGroup", _id=1},
		{ role = "AXSplitGroup", Identifier = "_NS:11" },
		{ role = "AXScrollArea", Identifier = "_NS:19" },
		{ role = "AXScrollBar" },
		{ role = "AXValueIndicator" }
	}, 1)
	if effectsScrollbar ~= nil then
		effectsScrollbarResult = effectsScrollbar:setAttributeValue("AXValue", 0)
	end

	--------------------------------------------------------------------------------
	-- Click 'All Video & Audio':
	--------------------------------------------------------------------------------
	-- PATH:
	-- AXApplication "Final Cut Pro"
	-- AXWindow "Final Cut Pro" (window 1)
	-- AXSplitGroup (splitter group 1)
	-- AXGroup (group 1)
	-- AXGroup (group 1)
	-- AXSplitGroup (splitter group 1)
	-- AXScrollArea (scroll area 1)
	-- AXOutline (outline 1)
	-- AXRow (row 31)
	-- AXStaticText (static text 1)
	-- AXDescription = All Video & Audio
	allVideoAndAudioText = sw:searchPath({
		{ role = "AXWindow", title = "Final Cut Pro"},
		{ role = "AXSplitGroup" },
		{ role = "AXGroup", },
		{ role = "AXGroup", _id=1},
		{ role = "AXSplitGroup", Identifier = "_NS:11" },
		{ role = "AXScrollArea", Identifier = "_NS:19" },
		{ role = "AXOutline", Description = "outline"},
		{ role = "AXRow", Description = "All Video & Audio" }
	}, 1)
	if allVideoAndAudioText ~= nil then

		local originalMousePoint = hs.mouse.getAbsolutePosition()
		local allVideoAndAudioTextPosition = allVideoAndAudioText:attributeValue("AXPosition")
		local allVideoAndAudioTextSize = allVideoAndAudioText:attributeValue("AXSize")

		allVideoAndAudioTextPosition['x'] = allVideoAndAudioTextPosition['x'] + (allVideoAndAudioTextSize['w']/2)
		allVideoAndAudioTextPosition['y'] = allVideoAndAudioTextPosition['y'] + (allVideoAndAudioTextSize['h']/2)

		--------------------------------------------------------------------------------
		-- Click twice:
		--------------------------------------------------------------------------------
		hs.eventtap.leftClick(allVideoAndAudioTextPosition)
		hs.eventtap.leftClick(allVideoAndAudioTextPosition)

		--------------------------------------------------------------------------------
		-- Move mouse back as if nothing ever happened:
		--------------------------------------------------------------------------------
		hs.mouse.setAbsolutePosition(originalMousePoint)


	else
	--------------------------------------------------------------------------------
	-- Left Panel might not be visible:
	--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Make sure scroll bar is all the way to the top:
		--------------------------------------------------------------------------------
		-- PATH:
		-- AXApplication "Final Cut Pro"
		-- AXWindow "Final Cut Pro" (window 1)
		-- AXSplitGroup (splitter group 1)
		-- AXGroup (group 1)
		-- AXGroup (group 1)
		-- AXSplitGroup (splitter group 1)
		-- AXScrollArea (scroll area 1)
		-- AXScrollBar (scroll bar 1)
		-- AXValueIndicator (value indicator 1)
		effectsScrollbar = sw:searchPath({
			{ role = "AXWindow", title = "Final Cut Pro"},
			{ role = "AXSplitGroup" },
			{ role = "AXGroup" },
			{ role = "AXGroup", _id=1},
			{ role = "AXSplitGroup", Identifier = "_NS:11" },
			{ role = "AXScrollArea", Identifier = "_NS:19" },
			{ role = "AXScrollBar" },
			{ role = "AXValueIndicator" }
		}, 1)
		if effectsScrollbar ~= nil then
			effectsScrollbarResult = effectsScrollbar:setAttributeValue("AXValue", 0)
		end

		--------------------------------------------------------------------------------
		-- Left Panel might not be visible:
		--------------------------------------------------------------------------------
		-- PATH:
		-- AXApplication "Final Cut Pro"
		-- AXWindow "Final Cut Pro" (window 1)
		-- AXSplitGroup (splitter group 1)
		-- AXGroup (group 1)
		-- AXGroup (group 1)
		-- AXGroup (group 1)
		-- AXButton (button 1)
		leftPanelButton = sw:searchPath({
			{ role = "AXWindow", title = "Final Cut Pro"},
			{ role = "AXSplitGroup" },
			{ role = "AXGroup", },
			{ role = "AXGroup", _id=1},
			{ role = "AXGroup", },
			{ role = "AXButton", Help = "Show/Hide" }
		}, 1)
		if leftPanelButton ~= nil then
			leftPanelButton:performAction("AXPress")
		end

		--------------------------------------------------------------------------------
		-- Click 'All Video & Audio':
		--------------------------------------------------------------------------------
		allVideoAndAudioText = sw:searchPath({
			{ role = "AXWindow", title = "Final Cut Pro"},
			{ role = "AXSplitGroup" },
			{ role = "AXGroup", },
			{ role = "AXGroup", _id=1},
			{ role = "AXSplitGroup", Identifier = "_NS:11" },
			{ role = "AXScrollArea", Identifier = "_NS:19" },
			{ role = "AXOutline", Description = "outline"},
			{ role = "AXRow", Description = "All Video & Audio" }
		}, 1)
		if allVideoAndAudioText ~= nil then
			local originalMousePoint = hs.mouse.getAbsolutePosition()
			local allVideoAndAudioTextPosition = allVideoAndAudioText:attributeValue("AXPosition")

			allVideoAndAudioTextPosition['x'] = allVideoAndAudioTextPosition['x'] + 5
			allVideoAndAudioTextPosition['y'] = allVideoAndAudioTextPosition['y'] + 5

			hs.eventtap.leftClick(allVideoAndAudioTextPosition)
			hs.mouse.setAbsolutePosition(originalMousePoint)
		else
			displayErrorMessage("Unable to select All Video & Audio.")
			return "Fail"
		end
	end

	--------------------------------------------------------------------------------
	-- Get list of all effects:
	--------------------------------------------------------------------------------
	-- VIDEO EFFECTS PATH:
	-- AXApplication "Final Cut Pro"
	-- AXWindow "Final Cut Pro" (window 1)
	-- AXSplitGroup (splitter group 1)
	-- AXGroup (group 1)
	-- AXGroup (group 1)
	-- AXSplitGroup (splitter group 1)
	-- AXScrollArea (scroll area 2)
	-- AXGrid (UI element 1)
	-- AXImage "Color Correction" (image 2)
	effectsList = sw:searchPath({
		{ role = "AXWindow"},
		{ role = "AXSplitGroup" },
		{ role = "AXGroup", },
		{ role = "AXGroup", },
		{ role = "AXSplitGroup" },
		{ role = "AXScrollArea" },
		{ role = "AXGrid" },
	}, 1)
	local allEffects = {}
	if effectsList ~= nil then
		for i=1, #effectsList:attributeValue("AXChildren") do
			allEffects[i] = effectsList:attributeValue("AXChildren")[i]:attributeValue("AXTitle")
		end
	else
		displayErrorMessage("Unable to get list of all effects.")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- All done!
	--------------------------------------------------------------------------------
	if #allEffects == 0 then
		displayErrorMessage("Unfortunately the Effects List was not successfully updated.\n\nPlease try again.")
		return "Fail"
	else
		--------------------------------------------------------------------------------
		-- Save Results to Settings:
		--------------------------------------------------------------------------------
		hs.settings.set("fcpxHacks.allEffects", allEffects)
		hs.settings.set("fcpxHacks.effectsListUpdated", true)

		--------------------------------------------------------------------------------
		-- Refresh Menubar:
		--------------------------------------------------------------------------------
		refreshMenuBar()

		--------------------------------------------------------------------------------
		-- Let the user know everything's good:
		--------------------------------------------------------------------------------
		displayMessage("Effects List updated successfully.")
	end

end

--------------------------------------------------------------------------------
-- ASSIGN EFFECTS SHORTCUT:
--------------------------------------------------------------------------------
function assignEffectsShortcut(whichShortcut)

	--------------------------------------------------------------------------------
	-- Just in case...
	--------------------------------------------------------------------------------
	local effectsListUpdated = hs.settings.get("fcpxHacks.effectsListUpdated")
	local allEffects = hs.settings.get("fcpxHacks.allEffects")

	if not effectsListUpdated then
		displayErrorMessage("The Effects List doesn't appear to be up-to-date.\n\nPlease update the Effects List and try again.")
		return "Failed"
	end
	if allEffects == nil then
		displayErrorMessage("The Effects List doesn't appear to be up-to-date.\n\nPlease update the Effects List and try again.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Display List:
	--------------------------------------------------------------------------------
	local appleScriptA = "set allEffects to {"
	for i=1, #allEffects do
		if i == #allEffects then
			appleScriptA = appleScriptA .. '"' .. tostring(allEffects[i]) .. '"}\n'
		else
			appleScriptA = appleScriptA .. '"' .. tostring(allEffects[i]) .. '", '
		end
	end

	local appleScriptB = [[
		tell me to activate
		set listResult to (choose from list allEffects with prompt "Which effect would you like to assign?")
		return listResult
	]]
	local ok,dialogBoxResult = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB)

	--------------------------------------------------------------------------------
	-- Save the selection:
	--------------------------------------------------------------------------------
	if dialogBoxResult ~= false then
		if whichShortcut == 1 then hs.settings.set("fcpxHacks.effectsShortcutOne", 		dialogBoxResult[1]) end
		if whichShortcut == 2 then hs.settings.set("fcpxHacks.effectsShortcutTwo", 		dialogBoxResult[1]) end
		if whichShortcut == 3 then hs.settings.set("fcpxHacks.effectsShortcutThree", 	dialogBoxResult[1]) end
		if whichShortcut == 4 then hs.settings.set("fcpxHacks.effectsShortcutFour", 	dialogBoxResult[1]) end
		if whichShortcut == 5 then hs.settings.set("fcpxHacks.effectsShortcutFive", 	dialogBoxResult[1]) end
	end

end

--------------------------------------------------------------------------------
-- TOGGLE ENABLE PROXY MENU ICON:
--------------------------------------------------------------------------------
function toggleEnableProxyMenuIcon()
	local enableProxyMenuIcon = hs.settings.get("fcpxHacks.enableProxyMenuIcon")
	if enableProxyMenuIcon == nil then
		hs.settings.set("fcpxHacks.enableProxyMenuIcon", true)
		enableProxyMenuIcon = true
	else
		hs.settings.set("fcpxHacks.enableProxyMenuIcon", not enableProxyMenuIcon)
	end

	updateMenubarIcon()
	refreshMenuBar()

end

--------------------------------------------------------------------------------
-- UPDATE MENUBAR ICON:
--------------------------------------------------------------------------------
function updateMenubarIcon()

	local fcpxHacksIcon = hs.image.imageFromPath("~/.hammerspoon/hs/fcpx/assets/fcpxhacks.png")
	local fcpxHacksIconSmall = fcpxHacksIcon:setSize({w=18,h=18})
	local displayMenubarAsIcon = hs.settings.get("fcpxHacks.displayMenubarAsIcon")
	local enableProxyMenuIcon = hs.settings.get("fcpxHacks.enableProxyMenuIcon")
	local proxyMenuIcon = ""
	local proxyStatusIcon = getProxyStatusIcon()

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
-- ENABLE HACKS SHORTCUTS IN FINAL CUT PRO:
--------------------------------------------------------------------------------
function toggleEnableHacksShortcutsInFinalCutPro()

	--------------------------------------------------------------------------------
	-- Get current value from settings:
	--------------------------------------------------------------------------------
	local enableHacksShortcutsInFinalCutPro = hs.settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro")
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
	local restartFinalCutProStatus = false
	if isFinalCutProRunning() then
		if displayYesNoQuestion(enableOrDisableText .. " Hacks Shortcuts in Final Cut Pro requires your Administrator password and also needs Final Cut Pro to restart before it can take affect.\n\nDo you want to continue?") then
			restartFinalCutProStatus = true
		else
			return "Done"
		end
	else
		if not displayYesNoQuestion(enableOrDisableText .. " Hacks Shortcuts in Final Cut Pro requires your Administrator password.\n\nDo you want to continue?") then
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
		local executeResult,executeStatus = hs.execute("defaults write ~/Library/Preferences/com.apple.FinalCut.plist 'Active Command Set' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset'")

		--------------------------------------------------------------------------------
		-- Disable Hacks Shortcut in Final Cut Pro:
		--------------------------------------------------------------------------------
		local appleScriptA = [[
			--------------------------------------------------------------------------------
			-- Replace Files:
			--------------------------------------------------------------------------------
			try
				tell me to activate
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/old/NSProCommandGroups.plist '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to restore NSProCommandGroups.plist." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/old/NSProCommands.plist '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommands.plist'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to restore NSProCommands.plist." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/old/en.lproj/Default.commandset '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to restore Default.commandset." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/old/en.lproj/NSProCommandDescriptions.strings '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to restore NSProCommandDescriptions.strings." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/old/en.lproj/NSProCommandNames.strings '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to restore NSProCommandNames.strings." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try

			return "Done"
		]]
		ok,toggleEnableHacksShortcutsInFinalCutProResult = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA)
		if toggleEnableHacksShortcutsInFinalCutProResult == "Done" then saveSettings = true end
	else
		--------------------------------------------------------------------------------
		-- Revert back to default keyboard layout:
		--------------------------------------------------------------------------------
		local executeResult,executeStatus = hs.execute("defaults write ~/Library/Preferences/com.apple.FinalCut.plist 'Active Command Set' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset'")

		--------------------------------------------------------------------------------
		-- Enable Hacks Shortcut in Final Cut Pro:
		--------------------------------------------------------------------------------
		local appleScriptA = [[
			--------------------------------------------------------------------------------
			-- Replace Files:
			--------------------------------------------------------------------------------
			try
				tell me to activate
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/new/NSProCommandGroups.plist '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to replace NSProCommandGroups.plist." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/new/NSProCommands.plist '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommands.plist'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to replace NSProCommands.plist." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/new/en.lproj/Default.commandset '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to replace Default.commandset." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/new/en.lproj/NSProCommandDescriptions.strings '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to replace NSProCommandDescriptions.strings." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/new/en.lproj/NSProCommandNames.strings '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to replace NSProCommandNames.strings." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try

			return "Done"
		]]
		ok,toggleEnableHacksShortcutsInFinalCutProResult = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA)
		if toggleEnableHacksShortcutsInFinalCutProResult == "Done" then saveSettings = true end
	end

	--------------------------------------------------------------------------------
	-- If all is good then...
	--------------------------------------------------------------------------------
	if saveSettings then
		--------------------------------------------------------------------------------
		-- Save new value to settings:
		--------------------------------------------------------------------------------
		hs.settings.set("fcpxHacks.enableHacksShortcutsInFinalCutPro", not enableHacksShortcutsInFinalCutPro)

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartFinalCutProStatus then
			if not restartFinalCutPro() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				displayErrorMessage("Failed to restart Final Cut Pro. You will need to restart manually.")
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

end

--------------------------------------------------------------------------------
-- TOGGLE ENABLE SHORTCUTS DURING FULLSCREEN PLAYBACK:
--------------------------------------------------------------------------------
function toggleEnableShortcutsDuringFullscreenPlayback()

	local enableShortcutsDuringFullscreenPlayback = hs.settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback")
	if enableShortcutsDuringFullscreenPlayback == nil then enableShortcutsDuringFullscreenPlayback = false end
	hs.settings.set("fcpxHacks.enableShortcutsDuringFullscreenPlayback", not enableShortcutsDuringFullscreenPlayback)

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
-- GET SCRIPT UPDATE:
--------------------------------------------------------------------------------
function getScriptUpdate()
	os.execute('open "https://latenitefilms.com/blog/final-cut-pro-hacks/"')
end

--------------------------------------------------------------------------------
-- GO TO LATENITE FILMS SITE:
--------------------------------------------------------------------------------
function gotoLateNiteSite()
	os.execute('open "https://latenitefilms.com"')
end

--------------------------------------------------------------------------------
-- CHANGE HIGHLIGHT SHAPE:
--------------------------------------------------------------------------------
function changeHighlightShape(value)
	hs.settings.set("fcpxHacks.displayHighlightShape", value)
	refreshMenuBar()
end

--------------------------------------------------------------------------------
-- CHANGE HIGHLIGHT COLOUR:
--------------------------------------------------------------------------------
function changeHighlightColour(value)
	hs.settings.set("fcpxHacks.displayHighlightColour", value)
	refreshMenuBar()
end

--------------------------------------------------------------------------------
-- TOGGLE MENUBAR DISPLAY MODE:
--------------------------------------------------------------------------------
function toggleMenubarDisplayMode()

	local displayMenubarAsIcon = hs.settings.get("fcpxHacks.displayMenubarAsIcon")


	if displayMenubarAsIcon == nil then
		 hs.settings.set("fcpxHacks.displayMenubarAsIcon", true)
	else
		if displayMenubarAsIcon then
			hs.settings.set("fcpxHacks.displayMenubarAsIcon", false)
		else
			hs.settings.set("fcpxHacks.displayMenubarAsIcon", true)
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
	-- If we're setting rather than toggling...
	--------------------------------------------------------------------------------
	if optionalValue ~= nil then

		--------------------------------------------------------------------------------
		-- Get plist values for FFCreateOptimizedMediaForMulticamClips:
		--------------------------------------------------------------------------------
		local FFCreateOptimizedMediaForMulticamClips = true
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFCreateOptimizedMediaForMulticamClips")
		if trim(executeResult) == "0" then FFCreateOptimizedMediaForMulticamClips = false end

		if optionalValue == FFCreateOptimizedMediaForMulticamClips then return end

	end

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	local fcpx = hs.application("Final Cut Pro")

	--------------------------------------------------------------------------------
	-- Open Preferences:
	--------------------------------------------------------------------------------
	local activatePreferencesResult = fcpx:selectMenuItem({"Final Cut Pro", "Preferences…"})
	if activatePreferencesResult == nil then
		displayErrorMessage("Failed to open Preferences Panel.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Toolbar:
	--------------------------------------------------------------------------------
	local timeoutCount = 0
	local whichToolbar = nil
	::tryToolbarAgain::
	fcpxElements = ax.applicationElement(fcpx)[1]
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
		if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXToolbar" then
			whichToolbar = i
			goto foundToolbar
		end
	end
	if whichToolbar == nil then
		timeoutCount = timeoutCount + 1
		if timeoutCount == 10 then
			displayErrorMessage("Unable to locate Preferences Toolbar.")
			return "Failed"
		end
		sleep(0.2)
		goto tryToolbarAgain
	end
	::foundToolbar::

	--------------------------------------------------------------------------------
	-- Goto Playback Preferences:
	--------------------------------------------------------------------------------
	local pressPlaybackButton = fcpxElements[whichToolbar][3]:performAction("AXPress")
	if pressPlaybackButton == nil then
		displayErrorMessage("Failed to open Import Preferences.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Group:
	--------------------------------------------------------------------------------
	local whichGroup = nil
	for i=1, (fcpxElements:attributeValueCount("AXChildren")) do
		if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
			whichGroup = i
			goto foundGroup
		end
	end
	if whichGroup == nil then
		displayErrorMessage("Unable to locate Group.")
		return "Failed"
	end
	::foundGroup::

	--------------------------------------------------------------------------------
	-- Toggle Create Optimized Media:
	--------------------------------------------------------------------------------
	fcpxElements[whichGroup][1][18]:performAction("AXPress")

	--------------------------------------------------------------------------------
	-- Close Preferences:
	--------------------------------------------------------------------------------
	local buttonResult = fcpxElements[1]:performAction("AXPress")
	if buttonResult == nil then
		displayErrorMessage("Unable to close Preferences window.")
		return "Failed"
	end

end

--------------------------------------------------------------------------------
-- TOGGLE CREATE PROXY MEDIA:
--------------------------------------------------------------------------------
function toggleCreateProxyMedia(optionalValue)

	--------------------------------------------------------------------------------
	-- If we're setting rather than toggling...
	--------------------------------------------------------------------------------
	if optionalValue ~= nil then

		--------------------------------------------------------------------------------
		-- Get plist values for FFImportCreateProxyMedia:
		--------------------------------------------------------------------------------
		local FFImportCreateProxyMedia = false
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFImportCreateProxyMedia")
		if trim(executeResult) == "1" then FFImportCreateProxyMedia = true end

		if optionalValue == FFImportCreateProxyMedia then return end

	end

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	local fcpx = hs.application("Final Cut Pro")

	--------------------------------------------------------------------------------
	-- Open Preferences:
	--------------------------------------------------------------------------------
	local activatePreferencesResult = fcpx:selectMenuItem({"Final Cut Pro", "Preferences…"})
	if activatePreferencesResult == nil then
		displayErrorMessage("Failed to open Preferences Panel.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Toolbar:
	--------------------------------------------------------------------------------
	local timeoutCount = 0
	local whichToolbar = nil
	::tryToolbarAgain::
	fcpxElements = ax.applicationElement(fcpx)[1]
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
		if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXToolbar" then
			whichToolbar = i
			goto foundToolbar
		end
	end
	if whichToolbar == nil then
		timeoutCount = timeoutCount + 1
		if timeoutCount == 10 then
			displayErrorMessage("Unable to locate Preferences Toolbar.")
			return "Failed"
		end
		sleep(0.2)
		goto tryToolbarAgain
	end
	::foundToolbar::

	--------------------------------------------------------------------------------
	-- Goto Playback Preferences:
	--------------------------------------------------------------------------------
	local pressPlaybackButton = fcpxElements[whichToolbar][4]:performAction("AXPress")
	if pressPlaybackButton == nil then
		displayErrorMessage("Failed to open Import Preferences.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Group:
	--------------------------------------------------------------------------------
	local whichGroup = nil
	for i=1, (fcpxElements:attributeValueCount("AXChildren")) do
		if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
			whichGroup = i
			goto foundGroup
		end
	end
	if whichGroup == nil then
		displayErrorMessage("Unable to locate Group.")
		return "Failed"
	end
	::foundGroup::

	--------------------------------------------------------------------------------
	-- Toggle Create Proxy Media:
	--------------------------------------------------------------------------------
	fcpxElements[whichGroup][1][1]:performAction("AXPress")

	--------------------------------------------------------------------------------
	-- Close Preferences:
	--------------------------------------------------------------------------------
	local buttonResult = fcpxElements[1]:performAction("AXPress")
	if buttonResult == nil then
		displayErrorMessage("Unable to close Preferences window.")
		return "Failed"
	end

end

--------------------------------------------------------------------------------
-- TOGGLE CREATE OPTIMIZED MEDIA:
--------------------------------------------------------------------------------
function toggleCreateOptimizedMedia(optionalValue)

	--------------------------------------------------------------------------------
	-- If we're setting rather than toggling...
	--------------------------------------------------------------------------------
	if optionalValue ~= nil then

		--------------------------------------------------------------------------------
		-- Get plist values for FFImportCreateOptimizeMedia:
		--------------------------------------------------------------------------------
		local FFImportCreateOptimizeMedia = false
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFImportCreateOptimizeMedia")
		if trim(executeResult) == "1" then FFImportCreateOptimizeMedia = true end

		if optionalValue == FFImportCreateOptimizeMedia then return end

	end

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	local fcpx = hs.application("Final Cut Pro")

	--------------------------------------------------------------------------------
	-- Open Preferences:
	--------------------------------------------------------------------------------
	local activatePreferencesResult = fcpx:selectMenuItem({"Final Cut Pro", "Preferences…"})
	if activatePreferencesResult == nil then
		displayErrorMessage("Failed to open Preferences Panel.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Toolbar:
	--------------------------------------------------------------------------------
	local timeoutCount = 0
	local whichToolbar = nil
	::tryToolbarAgain::
	fcpxElements = ax.applicationElement(fcpx)[1]
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
		if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXToolbar" then
			whichToolbar = i
			goto foundToolbar
		end
	end
	if whichToolbar == nil then
		timeoutCount = timeoutCount + 1
		if timeoutCount == 10 then
			displayErrorMessage("Unable to locate Preferences Toolbar.")
			return "Failed"
		end
		sleep(0.2)
		goto tryToolbarAgain
	end
	::foundToolbar::

	--------------------------------------------------------------------------------
	-- Goto Playback Preferences:
	--------------------------------------------------------------------------------
	local pressPlaybackButton = fcpxElements[whichToolbar][4]:performAction("AXPress")
	if pressPlaybackButton == nil then
		displayErrorMessage("Failed to open Import Preferences.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Group:
	--------------------------------------------------------------------------------
	local whichGroup = nil
	for i=1, (fcpxElements:attributeValueCount("AXChildren")) do
		if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
			whichGroup = i
			goto foundGroup
		end
	end
	if whichGroup == nil then
		displayErrorMessage("Unable to locate Group.")
		return "Failed"
	end
	::foundGroup::

	--------------------------------------------------------------------------------
	-- Toggle Create Optimized Media:
	--------------------------------------------------------------------------------
	fcpxElements[whichGroup][1][4]:performAction("AXPress")

	--------------------------------------------------------------------------------
	-- Close Preferences:
	--------------------------------------------------------------------------------
	local buttonResult = fcpxElements[1]:performAction("AXPress")
	if buttonResult == nil then
		displayErrorMessage("Unable to close Preferences window.")
		return "Failed"
	end

end

--------------------------------------------------------------------------------
-- TOGGLE LEAVE IN PLACE ON IMPORT:
--------------------------------------------------------------------------------
function toggleLeaveInPlace(optionalValue)

	--------------------------------------------------------------------------------
	-- If we're setting rather than toggling...
	--------------------------------------------------------------------------------
	if optionalValue ~= nil then

		--------------------------------------------------------------------------------
		-- Get plist values for FFImportCopyToMediaFolder:
		--------------------------------------------------------------------------------
		local FFImportCopyToMediaFolder = true
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFImportCopyToMediaFolder")
		if trim(executeResult) == "0" then FFImportCopyToMediaFolder = false end

		if optionalValue == not FFImportCopyToMediaFolder then return end

	end

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	local fcpx = hs.application("Final Cut Pro")

	--------------------------------------------------------------------------------
	-- Open Preferences:
	--------------------------------------------------------------------------------
	local activatePreferencesResult = fcpx:selectMenuItem({"Final Cut Pro", "Preferences…"})
	if activatePreferencesResult == nil then
		displayErrorMessage("Failed to open Preferences Panel.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Toolbar:
	--------------------------------------------------------------------------------
	local timeoutCount = 0
	local whichToolbar = nil
	::tryToolbarAgain::
	fcpxElements = ax.applicationElement(fcpx)[1]
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
		if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXToolbar" then
			whichToolbar = i
			goto foundToolbar
		end
	end
	if whichToolbar == nil then
		timeoutCount = timeoutCount + 1
		if timeoutCount == 10 then
			displayErrorMessage("Unable to locate Preferences Toolbar.")
			return "Failed"
		end
		sleep(0.2)
		goto tryToolbarAgain
	end
	::foundToolbar::

	--------------------------------------------------------------------------------
	-- Goto Playback Preferences:
	--------------------------------------------------------------------------------
	local pressPlaybackButton = fcpxElements[whichToolbar][4]:performAction("AXPress")
	if pressPlaybackButton == nil then
		displayErrorMessage("Failed to open Import Preferences.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Group:
	--------------------------------------------------------------------------------
	local whichGroup = nil
	for i=1, (fcpxElements:attributeValueCount("AXChildren")) do
		if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
			whichGroup = i
			goto foundGroup
		end
	end
	if whichGroup == nil then
		displayErrorMessage("Unable to locate Group.")
		return "Failed"
	end
	::foundGroup::

	--------------------------------------------------------------------------------
	-- Toggle "AutoStart Background Render":
	--------------------------------------------------------------------------------
	if fcpxElements[whichGroup][1][17][1]:attributeValue("AXValue") == 0 then
		fcpxElements[whichGroup][1][17][1]:performAction("AXPress")
	else
		fcpxElements[whichGroup][1][17][2]:performAction("AXPress")
	end

	--------------------------------------------------------------------------------
	-- Close Preferences:
	--------------------------------------------------------------------------------
	local buttonResult = fcpxElements[1]:performAction("AXPress")
	if buttonResult == nil then
		displayErrorMessage("Unable to close Preferences window.")
		return "Failed"
	end

end

--------------------------------------------------------------------------------
-- TOGGLE BACKGROUND RENDER:
--------------------------------------------------------------------------------
function toggleBackgroundRender(optionalValue)

	--------------------------------------------------------------------------------
	-- If we're setting rather than toggling...
	--------------------------------------------------------------------------------
	if optionalValue ~= nil then

		--------------------------------------------------------------------------------
		-- Get plist values for FFAutoStartBGRender:
		--------------------------------------------------------------------------------
		local FFAutoStartBGRender = true
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFAutoStartBGRender")
		if trim(executeResult) == "0" then FFAutoStartBGRender = false end

		if optionalValue == FFAutoStartBGRender then return end

	end

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	local fcpx = hs.application("Final Cut Pro")

	--------------------------------------------------------------------------------
	-- Open Preferences:
	--------------------------------------------------------------------------------
	local activatePreferencesResult = fcpx:selectMenuItem({"Final Cut Pro", "Preferences…"})
	if activatePreferencesResult == nil then
		displayErrorMessage("Failed to open Preferences Panel.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Toolbar:
	--------------------------------------------------------------------------------
	local timeoutCount = 0
	local whichToolbar = nil
	::tryToolbarAgain::
	fcpxElements = ax.applicationElement(fcpx)[1]
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
		if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXToolbar" then
			whichToolbar = i
			goto foundToolbar
		end
	end
	if whichToolbar == nil then
		timeoutCount = timeoutCount + 1
		if timeoutCount == 10 then
			displayErrorMessage("Unable to locate Preferences Toolbar.")
			return "Failed"
		end
		sleep(0.2)
		goto tryToolbarAgain
	end
	::foundToolbar::

	--------------------------------------------------------------------------------
	-- Goto Playback Preferences:
	--------------------------------------------------------------------------------
	local pressPlaybackButton = fcpxElements[whichToolbar][3]:performAction("AXPress")
	if pressPlaybackButton == nil then
		displayErrorMessage("Failed to open Playback Preferences.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Group:
	--------------------------------------------------------------------------------
	local whichGroup = nil
	for i=1, (fcpxElements:attributeValueCount("AXChildren")) do
		if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
			whichGroup = i
			goto foundGroup
		end
	end
	if whichGroup == nil then
		displayErrorMessage("Unable to locate Group.")
		return "Failed"
	end
	::foundGroup::

	--------------------------------------------------------------------------------
	-- Toggle "AutoStart Background Render":
	--------------------------------------------------------------------------------
	local buttonResult = fcpxElements[whichGroup][1][1]:performAction("AXPress")
	if buttonResult == nil then
		displayErrorMessage("Unable to toggle Background Render option.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Close Preferences:
	--------------------------------------------------------------------------------
	local buttonResult = fcpxElements[1]:performAction("AXPress")
	if buttonResult == nil then
		displayErrorMessage("Unable to close Preferences window.")
		return "Failed"
	end

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
	FFPeriodicBackupInterval = 15
	local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFPeriodicBackupInterval")
	if trim(executeResult) ~= "" then FFPeriodicBackupInterval = executeResult end

	--------------------------------------------------------------------------------
	-- If Final Cut Pro is running...
	--------------------------------------------------------------------------------
	local restartFinalCutProStatus = false
	if isFinalCutProRunning() then
		if displayYesNoQuestion("Changing the Backup Interval requires Final Cut Pro to restart.\n\nDo you want to continue?") then
			restartFinalCutProStatus = true
		else
			return "Done"
		end
	end

	--------------------------------------------------------------------------------
	-- Ask user what to set the backup interval to:
	--------------------------------------------------------------------------------
	local userSelectedBackupInterval = displayNumberTextBoxMessage("What would you like to set your Final Cut Pro Backup Interval to (in minutes)?", "The backup interval you entered is not valid. Please enter a value in minutes.", FFPeriodicBackupInterval)
	if not userSelectedBackupInterval then
		return "Cancel"
	end

	--------------------------------------------------------------------------------
	-- Update plist:
	--------------------------------------------------------------------------------
	local executeResult,executeStatus = hs.execute("defaults write ~/Library/Preferences/com.apple.FinalCut.plist FFPeriodicBackupInterval -string '" .. userSelectedBackupInterval .. "'")
	if executeStatus == nil then
		displayErrorMessage("Failed to write to plist.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Restart Final Cut Pro:
	--------------------------------------------------------------------------------
	if restartFinalCutProStatus then
		if not restartFinalCutPro() then
			--------------------------------------------------------------------------------
			-- Failed to restart Final Cut Pro:
			--------------------------------------------------------------------------------
			displayErrorMessage("Failed to restart Final Cut Pro. You will need to restart manually.")
			return "Failed"
		end
	end

	--------------------------------------------------------------------------------
	-- Refresh Menu Bar:
	--------------------------------------------------------------------------------
	refreshMenuBar(true)

end

--------------------------------------------------------------------------------
-- FCPX TOGGLE MOVING MARKERS:
--------------------------------------------------------------------------------
function toggleMovingMarkers()

	--------------------------------------------------------------------------------
	-- Delete any pre-existing highlights:
	--------------------------------------------------------------------------------
	deleteAllHighlights()

	--------------------------------------------------------------------------------
	-- Get existing value:
	--------------------------------------------------------------------------------
	allowMovingMarkers = false
	local executeResult,executeStatus = hs.execute("/usr/libexec/PlistBuddy -c \"Print :TLKMarkerHandler:Configuration:'Allow Moving Markers'\" '/Applications/Final Cut Pro.app/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist'")
	if trim(executeResult) == "true" then allowMovingMarkers = true end

	--------------------------------------------------------------------------------
	-- If Final Cut Pro is running...
	--------------------------------------------------------------------------------
	local restartFinalCutProStatus = false
	if isFinalCutProRunning() then
		if displayYesNoQuestion("Toggling Moving Markers requires Final Cut Pro to restart.\n\nDo you want to continue?") then
			restartFinalCutProStatus = true
		else
			return "Done"
		end
	end

	--------------------------------------------------------------------------------
	-- Update plist:
	--------------------------------------------------------------------------------
	if allowMovingMarkers then
		local executeStatus = executeWithAdministratorPrivileges([[/usr/libexec/PlistBuddy -c \"Set :TLKMarkerHandler:Configuration:'Allow Moving Markers' false\" '/Applications/Final Cut Pro.app/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist']])
		if executeStatus == false then
			displayErrorMessage("Failed to write to plist.")
			return "Failed"
		end
	else
		local executeStatus = executeWithAdministratorPrivileges([[/usr/libexec/PlistBuddy -c \"Set :TLKMarkerHandler:Configuration:'Allow Moving Markers' true\" '/Applications/Final Cut Pro.app/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist']])
		if executeStatus == false then
			displayErrorMessage("Failed to write to plist.")
			return "Failed"
		end
	end

	--------------------------------------------------------------------------------
	-- Restart Final Cut Pro:
	--------------------------------------------------------------------------------
	if restartFinalCutProStatus then
		if not restartFinalCutPro() then
			--------------------------------------------------------------------------------
			-- Failed to restart Final Cut Pro:
			--------------------------------------------------------------------------------
			displayErrorMessage("Failed to restart Final Cut Pro. You will need to restart manually.")
			return "Failed"
		end
	end

	--------------------------------------------------------------------------------
	-- Refresh Menu Bar:
	--------------------------------------------------------------------------------
	refreshMenuBar(true)

end

--------------------------------------------------------------------------------
-- FCPX PERFORM TASKS DURING PLAYBACK:
--------------------------------------------------------------------------------
function togglePerformTasksDuringPlayback()

	--------------------------------------------------------------------------------
	-- Delete any pre-existing highlights:
	--------------------------------------------------------------------------------
	deleteAllHighlights()

	--------------------------------------------------------------------------------
	-- Get existing value:
	--------------------------------------------------------------------------------
	FFSuspendBGOpsDuringPlay = false
	local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFSuspendBGOpsDuringPlay")
	if trim(executeResult) == "1" then FFSuspendBGOpsDuringPlay = true end

	--------------------------------------------------------------------------------
	-- If Final Cut Pro is running...
	--------------------------------------------------------------------------------
	local restartFinalCutProStatus = false
	if isFinalCutProRunning() then
		if displayYesNoQuestion("Toggling the ability to perform Background Tasks during playback requires Final Cut Pro to restart.\n\nDo you want to continue?") then
			restartFinalCutProStatus = true
		else
			return "Done"
		end
	end

	--------------------------------------------------------------------------------
	-- Update plist:
	--------------------------------------------------------------------------------
	if FFSuspendBGOpsDuringPlay then
		local executeResult,executeStatus = hs.execute("defaults write ~/Library/Preferences/com.apple.FinalCut.plist FFSuspendBGOpsDuringPlay -bool false")
		if executeStatus == nil then
			displayErrorMessage("Failed to write to plist.")
			return "Failed"
		end
	else
		local executeResult,executeStatus = hs.execute("defaults write ~/Library/Preferences/com.apple.FinalCut.plist FFSuspendBGOpsDuringPlay -bool true")
		if executeStatus == nil then
			displayErrorMessage("Failed to write to plist.")
			return "Failed"
		end
	end

	--------------------------------------------------------------------------------
	-- Restart Final Cut Pro:
	--------------------------------------------------------------------------------
	if restartFinalCutProStatus then
		if not restartFinalCutPro() then
			--------------------------------------------------------------------------------
			-- Failed to restart Final Cut Pro:
			--------------------------------------------------------------------------------
			displayErrorMessage("Failed to restart Final Cut Pro. You will need to restart manually.")
			return "Failed"
		end
	end

	--------------------------------------------------------------------------------
	-- Refresh Menu Bar:
	--------------------------------------------------------------------------------
	refreshMenuBar(true)

end

--------------------------------------------------------------------------------
-- FCPX TIMECODE OVERLAY TOGGLE:
--------------------------------------------------------------------------------
function toggleTimecodeOverlay()

	--------------------------------------------------------------------------------
	-- Delete any pre-existing highlights:
	--------------------------------------------------------------------------------
	deleteAllHighlights()

	--------------------------------------------------------------------------------
	-- Get existing value:
	--------------------------------------------------------------------------------
	FFEnableGuards = false
	local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFEnableGuards")
	if trim(executeResult) == "1" then FFEnableGuards = true end

	--------------------------------------------------------------------------------
	-- If Final Cut Pro is running...
	--------------------------------------------------------------------------------
	local restartFinalCutProStatus = false
	if isFinalCutProRunning() then
		if displayYesNoQuestion("Toggling Timecode Overlays requires Final Cut Pro to restart.\n\nDo you want to continue?") then
			restartFinalCutProStatus = true
		else
			return "Done"
		end
	end

	--------------------------------------------------------------------------------
	-- Update plist:
	--------------------------------------------------------------------------------
	if FFEnableGuards then
		local executeResult,executeStatus = hs.execute("defaults write ~/Library/Preferences/com.apple.FinalCut.plist FFEnableGuards -bool false")
		if executeStatus == nil then
			displayErrorMessage("Failed to write to plist.")
			return "Failed"
		end
	else
		local executeResult,executeStatus = hs.execute("defaults write ~/Library/Preferences/com.apple.FinalCut.plist FFEnableGuards -bool true")
		if executeStatus == nil then
			displayErrorMessage("Failed to write to plist.")
			return "Failed"
		end
	end

	--------------------------------------------------------------------------------
	-- Restart Final Cut Pro:
	--------------------------------------------------------------------------------
	if restartFinalCutProStatus then
		if not restartFinalCutPro() then
			--------------------------------------------------------------------------------
			-- Failed to restart Final Cut Pro:
			--------------------------------------------------------------------------------
			displayErrorMessage("Failed to restart Final Cut Pro. You will need to restart manually.")
			return "Failed"
		end
	end

	--------------------------------------------------------------------------------
	-- Refresh Menu Bar:
	--------------------------------------------------------------------------------
	refreshMenuBar(true)

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
	FFPeriodicBackupInterval = 15
	local executeResult,executeStatus = hs.execute("/usr/libexec/PlistBuddy -c \"Print :FFOrganizerSmartCollections\" '/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Versions/A/Resources/en.lproj/FFLocalizable.strings'")
	if trim(executeResult) ~= "" then FFOrganizerSmartCollections = executeResult end

	--------------------------------------------------------------------------------
	-- If Final Cut Pro is running...
	--------------------------------------------------------------------------------
	local restartFinalCutProStatus = false
	if isFinalCutProRunning() then
		if displayYesNoQuestion("Changing the Smart Collections Label requires Final Cut Pro to restart.\n\nDo you want to continue?") then
			restartFinalCutProStatus = true
		else
			return "Done"
		end
	end

	--------------------------------------------------------------------------------
	-- Ask user what to set the backup interval to:
	--------------------------------------------------------------------------------
	local userSelectedSmartCollectionsLabel = displayTextBoxMessage("What would you like to set your Smart Collections Label to:", "The Smart Collections Label you entered is not valid.\n\nPlease only use standard characters and numbers.", trim(FFOrganizerSmartCollections))
	if not userSelectedSmartCollectionsLabel then
		return "Cancel"
	end

	--------------------------------------------------------------------------------
	-- Update plist:
	--------------------------------------------------------------------------------
	local executeResult,executeStatus = hs.execute("/usr/libexec/PlistBuddy -c \"Set :FFOrganizerSmartCollections " .. trim(userSelectedSmartCollectionsLabel) .. "\" '/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Versions/A/Resources/en.lproj/FFLocalizable.strings'")
	if executeStatus == nil then
		displayErrorMessage("Failed to write to plist.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Restart Final Cut Pro:
	--------------------------------------------------------------------------------
	if restartFinalCutProStatus then
		if not restartFinalCutPro() then
			--------------------------------------------------------------------------------
			-- Failed to restart Final Cut Pro:
			--------------------------------------------------------------------------------
			displayErrorMessage("Failed to restart Final Cut Pro. You will need to restart manually.")
			return "Failed"
		end
	end

end

--------------------------------------------------------------------------------
-- PASTE FROM CLIPBOARD HISTORY:
--------------------------------------------------------------------------------
function finalCutProPasteFromClipboardHistory(data)

	--------------------------------------------------------------------------------
	-- Write data back to Clipboard:
	--------------------------------------------------------------------------------
	clipboardTimer:stop()
	pasteboard.writePListForUTI(finalCutProClipboardUTI, data)
	clipboardCurrentChange = pasteboard.changeCount()
	clipboardTimer:start()

	--------------------------------------------------------------------------------
	-- Paste in FCPX:
	--------------------------------------------------------------------------------
	keyStrokeFromPlist("Paste")

end

--------------------------------------------------------------------------------
-- CLEAR CLIPBOARD HISTORY:
--------------------------------------------------------------------------------
function clearClipboardHistory()
	clipboardHistory = {}
	settings.set("fcpxHacks.clipboardHistory", clipboardHistory)
	clipboardCurrentChange = pasteboard.changeCount()
	refreshMenuBar()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   S H O R T C U T   F E A T U R E S                        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- SELECT SECONDARY STORYLINE:
--------------------------------------------------------------------------------
function selectSecondaryStoryline(whichStoryline)

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	local fcpx 				= hs.application("Final Cut Pro")

	--------------------------------------------------------------------------------
	-- Get all FCPX UI Elements:
	--------------------------------------------------------------------------------
	fcpxElements = ax.applicationElement(hs.application("Final Cut Pro"))[1]

	--------------------------------------------------------------------------------
	-- Variables:
	--------------------------------------------------------------------------------
	local whichSplitGroup 			= nil
	local whichGroup 				= nil
	local whichValueIndicator 		= nil

	--------------------------------------------------------------------------------
	-- Cache:
	--------------------------------------------------------------------------------
	local useCache = false
	if fcpxElements[selectSecondaryStorylineSplitGroupCache] ~= nil then
		if fcpxElements[selectSecondaryStorylineSplitGroupCache][selectSecondaryStorylineGroupCache] ~= nil then
			if fcpxElements[selectSecondaryStorylineSplitGroupCache][selectSecondaryStorylineGroupCache][1]:attributeValue("AXRole") == "AXSplitGroup" then
				if fcpxElements[selectSecondaryStorylineSplitGroupCache][selectSecondaryStorylineGroupCache][1]:attributeValue("AXIdentifier") == "_NS:11" then
					useCache = true
					whichSplitGroup = selectSecondaryStorylineSplitGroupCache
					whichGroup = selectSecondaryStorylineGroupCache
				end
			end
		end
	end

	--------------------------------------------------------------------------------
	-- If Cache didn't work:
	--------------------------------------------------------------------------------
	if not useCache then
		--------------------------------------------------------------------------------
		-- Which Split Group:
		--------------------------------------------------------------------------------

		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if whichSplitGroup == nil then
				if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
					whichSplitGroup = i
					goto selectSecondaryStorylineSplitGroupExit
				end
			end
		end
		if whichSplitGroup == nil then
			displayErrorMessage("Unable to locate Split Group.")
			return "Failed"
		end
		::selectSecondaryStorylineSplitGroupExit::
		selectSecondaryStorylineSplitGroupCache = whichSplitGroup

		--------------------------------------------------------------------------------
		-- Which Group:
		--------------------------------------------------------------------------------
		for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
			if whichGroup == nil then
				if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1] ~= nil then
					if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1]:attributeValue("AXRole") == "AXSplitGroup" then
						if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1]:attributeValue("AXIdentifier") == "_NS:11" then
							whichGroup = i
							goto selectSecondaryStorylineGroupExit
						end
					end
				end
			end
		end
		if whichGroup == nil then
			displayErrorMessage("Unable to locate Group.")
			return "Failed"
		end
		::selectSecondaryStorylineGroupExit::
		selectSecondaryStorylineGroupCache = whichGroup
	end

	--------------------------------------------------------------------------------
	-- Split Group = 1
	-- Scroll Area = 2
	-- Layout Area = 1
	--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- Which Value Indicator:
	--------------------------------------------------------------------------------
	for i=1, fcpxElements[whichSplitGroup][whichGroup][1][2][1]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup][whichGroup][1][2][1]:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "Playhead" then
			whichValueIndicator = i
			goto selectSecondaryStorylineValueIndicatorExit
		end
	end
	if whichValueIndicator == nil then
		displayErrorMessage("Unable to locate Value Indicator.")
		return "Failed"
	end
	::selectSecondaryStorylineValueIndicatorExit::

	--------------------------------------------------------------------------------
	-- Timeline Playhead Position:
	--------------------------------------------------------------------------------
	local timelinePlayheadXPosition = fcpxElements[whichSplitGroup][whichGroup][1][2][1][whichValueIndicator]:attributeValue("AXPosition")['x']

	--------------------------------------------------------------------------------
	-- Which Layout Items (Selected Timeline Clip):
	--------------------------------------------------------------------------------
	local whichLayoutItems = {}
	for i=1, fcpxElements[whichSplitGroup][whichGroup][1][2][1]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup][whichGroup][1][2][1]:attributeValue("AXChildren")[i] ~= nil then
			if fcpxElements[whichSplitGroup][whichGroup][1][2][1]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXLayoutItem" then

				local currentClipPositionMinX = fcpxElements[whichSplitGroup][whichGroup][1][2][1]:attributeValue("AXChildren")[i]:attributeValue("AXPosition")['x']
				local currentClipPositionMaxX = currentClipPositionMinX + fcpxElements[whichSplitGroup][whichGroup][1][2][1]:attributeValue("AXChildren")[i]:attributeValue("AXSize")['w']

				if timelinePlayheadXPosition >= currentClipPositionMinX and timelinePlayheadXPosition <= currentClipPositionMaxX then
					local currentClipPositionY = fcpxElements[whichSplitGroup][whichGroup][1][2][1]:attributeValue("AXChildren")[i]:attributeValue("AXPosition")['y']
					whichLayoutItems[#whichLayoutItems + 1] = { i, currentClipPositionY }
				end

			end
		end
	end

	local howManyClips = tableCount(whichLayoutItems)
	if next(whichLayoutItems) == nil or howManyClips == 1 or howManyClips <= whichStoryline then
		print("[FCPX Hacks] ERROR: We couldn't find any clips on the Secondary Storyline at your current playhead position.")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Sort the table:
	--------------------------------------------------------------------------------
	table.sort(whichLayoutItems, function(a, b) return a[2] > b[2] end)

	--------------------------------------------------------------------------------
	-- Which clip to we need:
	--------------------------------------------------------------------------------
	local whichClip = whichLayoutItems[whichStoryline + 1][1]

	--------------------------------------------------------------------------------
	-- Click the clip:
	--------------------------------------------------------------------------------
	local clipCentrePosition = {}
	local clipPosition = fcpxElements[whichSplitGroup][whichGroup][1][2][1][whichClip]:attributeValue("AXPosition")
	local clipSize = fcpxElements[whichSplitGroup][whichGroup][1][2][1][whichClip]:attributeValue("AXSize")

	clipCentrePosition['x'] = timelinePlayheadXPosition
	clipCentrePosition['y'] = clipPosition['y'] + ( clipSize['h'] / 2 )

	ninjaMouseClick(clipCentrePosition)

end

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
	-- Variables:
	--------------------------------------------------------------------------------
	local whichSplitGroup 					= nil
	local whichGroup 						= nil
	local whichSlider 						= nil
	local changeAppearanceButtonSize 		= nil
	local changeAppearanceButtonPosition	= nil

	--------------------------------------------------------------------------------
	-- Get all FCPX UI Elements:
	--------------------------------------------------------------------------------
	fcpx = hs.application("Final Cut Pro")
	fcpxElements = ax.applicationElement(fcpx)

	--------------------------------------------------------------------------------
	-- To Cache Or Not To Cache:
	--------------------------------------------------------------------------------
	local useCache = false
	if changeTimelineClipHeightSplitGroupCache ~= nil and changeTimelineClipHeightGroupCache ~= nil then
		useCache = true
		whichSplitGroup = changeTimelineClipHeightSplitGroupCache
		whichGroup = changeTimelineClipHeightGroupCache
	end

	if not useCache then
		--------------------------------------------------------------------------------
		-- Which Split Group:
		--------------------------------------------------------------------------------
		if fcpxElements[1] == nil or fcpxElements[1]:attributeValueCount("AXChildren") == nil then
			print("[FCPX Hacks] ERROR: Unable to locate changeTimelineClipHeight fcpxElements.")
			changeTimelineClipHeightAlreadyInProgress = false
			return "Failed"
		end
		for i=1, fcpxElements[1]:attributeValueCount("AXChildren") do
			if whichSplitGroup == nil then
				if fcpxElements[1]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
					whichSplitGroup = i
					goto changeTimelineClipHeightSplitGroupExit
				end
			end
		end
		if whichSplitGroup == nil then
			--------------------------------------------------------------------------------
			-- Maybe the window is already open, so try closing first:
			--------------------------------------------------------------------------------
			print("[FCPX Hacks] ERROR: Unable to locate changeTimelineClipHeight Split Group.")
			changeTimelineClipHeightAlreadyInProgress = false
			return "Failed"
		end
		::changeTimelineClipHeightSplitGroupExit::
		changeTimelineClipHeightSplitGroupCache = whichSplitGroup -- Cache!

		--------------------------------------------------------------------------------
		-- Which Group:
		--------------------------------------------------------------------------------
		for i=1, (fcpxElements[1][whichSplitGroup]:attributeValueCount("AXChildren")) do
			if fcpxElements[1][whichSplitGroup] ~= nil and fcpxElements[1][whichSplitGroup]:attributeValue("AXChildren")[i] ~= nil then
				if fcpxElements[1][whichSplitGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
					if fcpxElements[1][whichSplitGroup]:attributeValue("AXChildren")[i][1] ~= nil then
						if fcpxElements[1][whichSplitGroup]:attributeValue("AXChildren")[i][1]:attributeValue("AXHelp") == "Adjust the Timeline zoom level" then
							whichGroup = i
							goto changeTimelineClipHeightGroupExit
						end
					end
				end
			end
		end
		if whichGroup == nil then
			print("[FCPX Hacks] ERROR: Unable to locate changeTimelineClipHeight Group.")
			changeTimelineClipHeightAlreadyInProgress = false
			return "Failed"
		end
		::changeTimelineClipHeightGroupExit::
		changeTimelineClipHeightGroupCache = whichGroup -- Cache!
	end

	--------------------------------------------------------------------------------
	-- If the window is already open:
	--------------------------------------------------------------------------------
	local isWindowAlreadyOpen = false
	if fcpxElements[1] == nil then isWindowAlreadyOpen = true end
	if fcpxElements[1][whichSplitGroup] == nil then isWindowAlreadyOpen = true end
	if fcpxElements[1][whichSplitGroup][whichGroup] == nil then isWindowAlreadyOpen = true end
	if fcpxElements[1][whichSplitGroup][whichGroup][2] == nil then isWindowAlreadyOpen = true end
	if isWindowAlreadyOpen then

		--------------------------------------------------------------------------------
		-- Increase or decrease slider once:
		--------------------------------------------------------------------------------
		fcpxElements = ax.applicationElement(fcpx) -- Refresh fcpxElements
		if direction == "up" then
			if fcpxElements[1][1] ~= nil then
				fcpxElements[1][1]:performAction("AXIncrement")
			end
		else
			if fcpxElements[1][1] ~= nil then
				fcpxElements[1][1]:performAction("AXDecrement")
			end
		end

		--------------------------------------------------------------------------------
		-- If key is held down:
		--------------------------------------------------------------------------------
		if releaseChangeTimelineClipHeightDown then

			releaseChangeTimelineClipHeightDown = false
			hs.timer.doUntil(function() return releaseChangeTimelineClipHeightDown end, function()
				if direction == "up" then
					if fcpxElements[1][1] ~= nil then
						fcpxElements[1][1]:performAction("AXIncrement")
					end
				else
					if fcpxElements[1][1] ~= nil then
						fcpxElements[1][1]:performAction("AXDecrement")
					end
				end
			end, hs.eventtap.keyRepeatInterval())

			--------------------------------------------------------------------------------
			-- Close window:
			--------------------------------------------------------------------------------
		else
			ninjaMouseClick(changeAppearanceButtonLocation)
			changeTimelineClipHeightAlreadyInProgress = false
		end

	else

		--------------------------------------------------------------------------------
		-- Get Button Position for later:
		--------------------------------------------------------------------------------
		changeAppearanceButtonSize = fcpxElements[1][whichSplitGroup][whichGroup][2]:attributeValue("AXSize")
		changeAppearanceButtonPosition = fcpxElements[1][whichSplitGroup][whichGroup][2]:attributeValue("AXPosition")
		changeAppearanceButtonLocation['x'] = changeAppearanceButtonPosition['x'] + (changeAppearanceButtonSize['w'] / 2 )
		changeAppearanceButtonLocation['y'] = changeAppearanceButtonPosition['y'] + (changeAppearanceButtonSize['h'] / 2 )

		--------------------------------------------------------------------------------
		-- Press Button:
		--------------------------------------------------------------------------------
		fcpxElements[1][whichSplitGroup][whichGroup][2]:performAction("AXPress")

		--------------------------------------------------------------------------------
		-- Increase or decrease slider once:
		--------------------------------------------------------------------------------
		fcpxElements = ax.applicationElement(fcpx) -- Refresh fcpxElements
		if direction == "up" then
			if fcpxElements[1][1] ~= nil then
				fcpxElements[1][1]:performAction("AXIncrement")
			end
		else
			if fcpxElements[1][1] ~= nil then
				fcpxElements[1][1]:performAction("AXDecrement")
			end
		end

		--------------------------------------------------------------------------------
		-- If key is held down:
		--------------------------------------------------------------------------------
		if releaseChangeTimelineClipHeightDown then

			releaseChangeTimelineClipHeightDown = false
			hs.timer.doUntil(function() return releaseChangeTimelineClipHeightDown end, function()
				if direction == "up" then
					if fcpxElements[1][1] ~= nil then
						fcpxElements[1][1]:performAction("AXIncrement")
					end
				else
					if fcpxElements[1][1] ~= nil then
						fcpxElements[1][1]:performAction("AXDecrement")
					end
				end
			end, hs.eventtap.keyRepeatInterval())

			--------------------------------------------------------------------------------
			-- Close window:
			--------------------------------------------------------------------------------
		else
			ninjaMouseClick(changeAppearanceButtonLocation)
			changeTimelineClipHeightAlreadyInProgress = false
		end
	end
end
function changeTimelineClipHeightRelease()
	releaseChangeTimelineClipHeightDown = true
	ninjaMouseClick(changeAppearanceButtonLocation)
	changeTimelineClipHeightAlreadyInProgress = false
end

--------------------------------------------------------------------------------
-- ACTIVE SCROLLING TIMELINE WATCHER:
--------------------------------------------------------------------------------
function toggleScrollingTimeline()

	--------------------------------------------------------------------------------
	-- Toggle Scrolling Timeline:
	--------------------------------------------------------------------------------
	scrollingTimelineActivated = hs.settings.get("fcpxHacks.scrollingTimelineActive") or false
	if scrollingTimelineActivated then
		--------------------------------------------------------------------------------
		-- Update Settings:
		--------------------------------------------------------------------------------
		hs.settings.set("fcpxHacks.scrollingTimelineActive", false)

		--------------------------------------------------------------------------------
		-- Stop Watchers:
		--------------------------------------------------------------------------------
		scrollingTimelineWatcherUp:stop()
		scrollingTimelineWatcherDown:stop()

		--------------------------------------------------------------------------------
		-- Stop Scrolling Timeline Loops:
		--------------------------------------------------------------------------------
		if scrollingTimelineTimer ~= nil then scrollingTimelineTimer:stop() end
		if scrollingTimelineScrollbarTimer ~= nil then scrollingTimelineScrollbarTimer:stop() end

		--------------------------------------------------------------------------------
		-- Turn off variable:
		--------------------------------------------------------------------------------
		scrollingTimelineSpacebarPressed = false

		--------------------------------------------------------------------------------
		-- Display Notification:
		--------------------------------------------------------------------------------
		hs.alert.show("Scrolling Timeline Deactivated")
	else
		--------------------------------------------------------------------------------
		-- Update Settings:
		--------------------------------------------------------------------------------
		hs.settings.set("fcpxHacks.scrollingTimelineActive", true)

		--------------------------------------------------------------------------------
		-- Start Watchers:
		--------------------------------------------------------------------------------
		scrollingTimelineWatcherUp:start()
		scrollingTimelineWatcherDown:start()

		--------------------------------------------------------------------------------
		-- If activated whilst already playing, then turn on Scrolling Timeline:
		--------------------------------------------------------------------------------
		-- TO DO: it would be great to be able to do this if possible?
			-- scrollingTimelineSpacebarCheck = true
			-- hs.timer.waitUntil(function() return scrollingTimelineSpacebarCheck end, function() checkScrollingTimelinePress() end, 0.00000001)

		--------------------------------------------------------------------------------
		-- Display Notification:
		--------------------------------------------------------------------------------
		hs.alert.show("Scrolling Timeline Activated")
	end

	--------------------------------------------------------------------------------
	-- Refresh Menu Bar:
	--------------------------------------------------------------------------------
	refreshMenuBar()

end

--------------------------------------------------------------------------------
-- SCROLLING TIMELINE FUNCTION:
--------------------------------------------------------------------------------
function performScrollingTimelineLoops(whichSplitGroup, whichGroup, whichValueIndicator, initialPlayheadXPosition)

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	fcpx = hs.application("Final Cut Pro")

	--------------------------------------------------------------------------------
	-- Get all FCPX UI Elements:
	--------------------------------------------------------------------------------
	fcpxElements = ax.applicationElement(fcpx)[1]

	--------------------------------------------------------------------------------
	-- Define Scrollbar Check Timer:
	--------------------------------------------------------------------------------
	scrollingTimelineScrollbarTimer = hs.timer.new(0.001, function()
		if fcpxElements[whichSplitGroup][whichGroup][1][2][2] ~= nil then
			performScrollingTimelineLoops(whichSplitGroup, whichGroup)
			scrollbarSearchLoopActivated = false
		end
	end)

	--------------------------------------------------------------------------------
	-- Trigger Scrollbar Check Timer if No Scrollbar Visible:
	--------------------------------------------------------------------------------
	if fcpxElements[whichSplitGroup][whichGroup][1][2][2] == nil then
		scrollingTimelineScrollbarTimer:start()
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Make sure Playhead is actually visible:
	--------------------------------------------------------------------------------
	local scrollAreaX = fcpxElements[whichSplitGroup][whichGroup][1][2]:attributeValue("AXPosition")['x']
	local scrollAreaW = fcpxElements[whichSplitGroup][whichGroup][1][2]:attributeValue("AXSize")['w']
	local endOfTimelineXPosition = (scrollAreaX + scrollAreaW)
	if initialPlayheadXPosition > endOfTimelineXPosition or initialPlayheadXPosition < scrollAreaX then
		local timelineWidth = fcpxElements[whichSplitGroup][whichGroup][1][2]:attributeValue("AXSize")['w']
		initialPlayheadXPosition = (timelineWidth / 2)
	end

	--------------------------------------------------------------------------------
	-- Initial Scrollbar Value:
	--------------------------------------------------------------------------------
	local initialScrollbarValue = fcpxElements[whichSplitGroup][whichGroup][1][2][2][1]:attributeValue("AXValue")

	--------------------------------------------------------------------------------
	-- Define the Loop of Death:
	--------------------------------------------------------------------------------
	scrollingTimelineTimer = hs.timer.new(0.000001, function()

		--------------------------------------------------------------------------------
		-- Does the scrollbar still exist?
		--------------------------------------------------------------------------------
		if fcpxElements[whichSplitGroup][whichGroup][1][2][2] ~= nil then
			local scrollbarWidth = fcpxElements[whichSplitGroup][whichGroup][1][2][2][1]:attributeValue("AXSize")['w']
			local timelineWidth = fcpxElements[whichSplitGroup][whichGroup][1][2][1]:attributeValue("AXSize")['w']

			local howMuchBiggerTimelineIsThanScrollbar = scrollbarWidth / timelineWidth

			--------------------------------------------------------------------------------
			-- If you change the edit the location of the Value Indicator will change:
			--------------------------------------------------------------------------------
			if fcpxElements[whichSplitGroup][whichGroup][1][2][1][whichValueIndicator]:attributeValue("AXDescription") ~= "Playhead" then
				for i=1, fcpxElements[whichSplitGroup][whichGroup][1][2][1]:attributeValueCount("AXChildren") do
					if fcpxElements[whichSplitGroup][whichGroup][1][2][1]:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "Playhead" then
						whichValueIndicator = i
						goto performScrollingTimelineValueIndicatorExitX
					end
				end
				if whichValueIndicator == nil then
					displayErrorMessage("Unable to locate Value Indicator.")
					return "Failed"
				end
				::performScrollingTimelineValueIndicatorExitX::
			end

			local currentPlayheadXPosition = fcpxElements[whichSplitGroup][whichGroup][1][2][1][whichValueIndicator]:attributeValue("AXPosition")['x']

			initialPlayheadPecentage = initialPlayheadXPosition / scrollbarWidth
			currentPlayheadPecentage = currentPlayheadXPosition / scrollbarWidth

			x = initialPlayheadPecentage * howMuchBiggerTimelineIsThanScrollbar
			y = currentPlayheadPecentage * howMuchBiggerTimelineIsThanScrollbar

			scrollbarStep = y - x

			local currentScrollbarValue = fcpxElements[whichSplitGroup][whichGroup][1][2][2][1]:attributeValue("AXValue")
			fcpxElements[whichSplitGroup][whichGroup][1][2][2][1]:setAttributeValue("AXValue", currentScrollbarValue + scrollbarStep)
		end
	end)

	--------------------------------------------------------------------------------
	-- Begin the Loop of Death:
	--------------------------------------------------------------------------------
	scrollingTimelineTimer:start()

end

--------------------------------------------------------------------------------
-- EFFECTS SHORTCUT PRESSED:
--------------------------------------------------------------------------------
function effectsShortcut(whichShortcut)

	--------------------------------------------------------------------------------
	-- Get settings:
	--------------------------------------------------------------------------------
	local currentShortcut = nil
	if whichShortcut == 1 then currentShortcut = hs.settings.get("fcpxHacks.effectsShortcutOne") end
	if whichShortcut == 2 then currentShortcut = hs.settings.get("fcpxHacks.effectsShortcutTwo") end
	if whichShortcut == 3 then currentShortcut = hs.settings.get("fcpxHacks.effectsShortcutThree") end
	if whichShortcut == 4 then currentShortcut = hs.settings.get("fcpxHacks.effectsShortcutFour") end
	if whichShortcut == 5 then currentShortcut = hs.settings.get("fcpxHacks.effectsShortcutFive") end

	if currentShortcut == nil then
		displayMessage("There is no Effect assigned to this shortcut.\n\nYou can assign Effects Shortcuts via the FCPX Hacks menu bar.")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	local fcpx = hs.application("Final Cut Pro")
	sw = ax.windowElement(fcpx:mainWindow())

	--------------------------------------------------------------------------------
	-- Get all FCPX UI Elements:
	--------------------------------------------------------------------------------
	local fcpx = hs.application("Final Cut Pro")
	fcpxElements = ax.applicationElement(fcpx)[1]

	--------------------------------------------------------------------------------
	-- Which Split Group:
	--------------------------------------------------------------------------------
	local whichSplitGroup = nil
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
		if whichSplitGroup == nil then
			if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
				whichSplitGroup = i
				goto effectsShortcutSplitGroupExit
			end
		end
	end
	::effectsShortcutSplitGroupExit::
	if whichSplitGroup == nil then
		displayErrorMessage("Unable to locate Split Group.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Group One:
	--------------------------------------------------------------------------------
	local whichGroupOne = nil
	for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
			if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1] ~= nil then
				if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1]:attributeValue("AXIdentifier") == "_NS:382" then
					whichGroupOne = i
					goto effectsShortcutGroupOneExit
				end
			end
		end
	end
	::effectsShortcutGroupOneExit::
	if whichGroupOne == nil then
		displayErrorMessage("Unable to locate Group One.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Radio Group:
	--------------------------------------------------------------------------------
	local whichRadioGroup = nil
	for i=1, fcpxElements[whichSplitGroup][whichGroupOne]:attributeValueCount("AXChildren") do
		if whichRadioGroup == nil then
			if fcpxElements[whichSplitGroup][whichGroupOne]:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "Media Browser Palette" then
				whichRadioGroup = i
				goto effectsShortcutRadioGroupExit
			end
		end
	end
	::effectsShortcutRadioGroupExit::
	if whichRadioGroup == nil then
		displayErrorMessage("Unable to locate Radio Group.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- NOTE: AXRadioButton is 1
	--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- Make sure Video Effects panel is open:
	--------------------------------------------------------------------------------
	if fcpxElements[whichSplitGroup][whichGroupOne][whichRadioGroup][1] ~= nil then
		if fcpxElements[whichSplitGroup][whichGroupOne][whichRadioGroup][1]:attributeValue("AXValue") == 0 then
				local presseffectsBrowserButtonResult = fcpxElements[whichSplitGroup][whichGroupOne][whichRadioGroup][1]:performAction("AXPress")
				if presseffectsBrowserButtonResult == nil then
					displayErrorMessage("Unable to press Video Effects icon.")
					return "Fail"
				end
		end
	else
		displayErrorMessage("Unable to find Video Effects icon.")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Which Group Two:
	--------------------------------------------------------------------------------
	local whichGroupTwo = nil
	for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
			if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][2] ~= nil then
				if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][2][1] ~= nil then
					if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][2][1]:attributeValue("AXRole") == "AXButton" then
						if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][2][1]:attributeValue("AXIdentifier") == "_NS:63" then
							whichGroupTwo = i
							goto effectsShortcutGroupTwoExit
						end
					end
				end
			end
		end
	end
	::effectsShortcutGroupTwoExit::
	if whichGroupTwo == nil then
		displayErrorMessage("Unable to locate Group 2.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Group Three:
	--------------------------------------------------------------------------------
	local whichGroupThree = nil
	for i=1, fcpxElements[whichSplitGroup][whichGroupTwo]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup][whichGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
			if fcpxElements[whichSplitGroup][whichGroupTwo]:attributeValue("AXChildren")[i][1] ~= nil then
				if fcpxElements[whichSplitGroup][whichGroupTwo]:attributeValue("AXChildren")[i][1]:attributeValue("AXRole") == "AXStaticText" then
					if fcpxElements[whichSplitGroup][whichGroupTwo]:attributeValue("AXChildren")[i][1]:attributeValue("AXIdentifier") == "_NS:74" then
						whichGroupThree = i
						goto effectsShortcutGroupThreeExit
					end
				end
			end
		end
	end
	::effectsShortcutGroupThreeExit::
	if whichGroupThree == nil then
		displayErrorMessage("Unable to locate Group 3.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Split Group Two:
	--------------------------------------------------------------------------------
	local whichSplitGroupTwo = nil
	for i=1, fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
			whichSplitGroupTwo = i
			goto effectsShortcutSplitGroupTwo
		end
	end
	::effectsShortcutSplitGroupTwo::
	if whichSplitGroupTwo == nil then
		displayErrorMessage("Unable to locate Split Group 2.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Scroll Area:
	--------------------------------------------------------------------------------
	local whichScrollArea = nil
	for i=1, fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXScrollArea" then
			if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXIdentifier") == "_NS:19" then
				whichScrollArea = i
				goto effectsShortcutScrollArea
			end
		end
	end
	::effectsShortcutScrollArea::

	--------------------------------------------------------------------------------
	-- Left Panel May Be Hidden?
	--------------------------------------------------------------------------------
	if whichScrollArea == nil then

		--------------------------------------------------------------------------------
		-- Which Group Four:
		--------------------------------------------------------------------------------
		local whichGroupFour = nil
		for i=1, fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree]:attributeValueCount("AXChildren") do
			if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
				whichGroupFour = i
				goto effectsShortcutGroupFour
			end
		end
		::effectsShortcutGroupFour::
		if whichGroupFour == nil then
			displayErrorMessage("Unable to locate Group Four.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- NOTE: AXButton is 1
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Click Show/Hide:
		--------------------------------------------------------------------------------
		fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichGroupFour][1]:performAction("AXPress")

		--------------------------------------------------------------------------------
		-- Try Which Scroll Area Again:
		--------------------------------------------------------------------------------
		fcpxElements = ax.applicationElement(fcpx)[1] -- Reload
		whichScrollArea = nil -- Not local as we need it below.
		for i=1, fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo]:attributeValueCount("AXChildren") do
			if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXScrollArea" then
				if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXIdentifier") == "_NS:19" then
					whichScrollArea = i
					goto effectsShortcutScrollAreaTakeTwo
				end
			end
		end
		::effectsShortcutScrollAreaTakeTwo::
		if whichScrollArea == nil then
			displayErrorMessage("Unable to locate Scroll Area for a second time.")
			return "Failed"
		end
	end

	--------------------------------------------------------------------------------
	-- Which Scroll Bar:
	--------------------------------------------------------------------------------
	fcpxElements = ax.applicationElement(fcpx)[1] -- Reload
	local whichScrollBar = nil
	for i=1, fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][whichScrollArea]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][whichScrollArea]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXScrollBar" then
			whichScrollBar = i
			goto effectsShortcutScrollBar
		end
	end
	::effectsShortcutScrollBar::
	if whichScrollBar == nil then
		displayErrorMessage("Unable to locate Scroll Bar.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- NOTE: AXValueIndicator = 1
	--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- Make sure scroll bar is all the way to the top (if there is one):
	--------------------------------------------------------------------------------
	if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][whichScrollArea][whichScrollBar][1] ~= nil then
		effectsScrollbarResult = fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][whichScrollArea][whichScrollBar][1]:setAttributeValue("AXValue", 0)
		if effectsScrollbarResult == nil then
			displayErrorMessage("Failed to put scroll bar all the way to the top.")
			return "Failed"
		end
	end

	--------------------------------------------------------------------------------
	-- Search for the effect we need:
	--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- Which Search Text Field:
	--------------------------------------------------------------------------------
	local whichSearchTextField = nil
	for i=1, fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXTextField" then
			if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree]:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "Effect Library Search Field" then
				whichSearchTextField = i
				goto effectsShortcutSearchTextField
			end
		end
	end
	::effectsShortcutSearchTextField::

	--------------------------------------------------------------------------------
	-- Perform Search:
	--------------------------------------------------------------------------------
	enterSearchResult = fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSearchTextField]:setAttributeValue("AXValue", currentShortcut)
	if enterSearchResult == nil then
		displayErrorMessage("Unable to Effect Name into search box.")
		return "Fail"
	end
	pressSearchResult = fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSearchTextField][1]:performAction("AXPress")
	if pressSearchResult == nil then
		displayErrorMessage("Failed to press search button.")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Which Outline:
	--------------------------------------------------------------------------------
	local whichOutline = nil
	for i=1, fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][whichScrollArea]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][whichScrollArea]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXOutline" then
			whichOutline = i
			goto effectsShortcutOutlineExit
		end
	end
	::effectsShortcutOutlineExit::
	if whichOutline == nil then
		displayErrorMessage("Unable to locate Scroll Area.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Which Row:
	--------------------------------------------------------------------------------
	local whichRow = nil
	for i=1, fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][whichScrollArea][whichOutline]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][whichScrollArea][whichOutline]:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "All Video & Audio" then
			whichRow = i
			goto effectsShortcutRowExit
		end
	end
	::effectsShortcutRowExit::
	if whichRow == nil then
		displayErrorMessage("Unable to locate Row.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Click 'All Video & Audio':
	--------------------------------------------------------------------------------
	if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][whichScrollArea][whichOutline][whichRow] ~= nil then
		if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][whichScrollArea][whichOutline][whichRow]:attributeValue("AXSelected") == false then -- Only need to click if not already clicked!

			local originalMousePoint = hs.mouse.getAbsolutePosition()
			local allVideoAndAudioTextPosition = fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][whichScrollArea][whichOutline][whichRow]:attributeValue("AXPosition")
			local allVideoAndAudioTextSize = fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][whichScrollArea][whichOutline][whichRow]:attributeValue("AXSize")

			allVideoAndAudioTextPosition['x'] = allVideoAndAudioTextPosition['x'] + 30 --(allVideoAndAudioTextSize['w'] / 2)
			allVideoAndAudioTextPosition['y'] = allVideoAndAudioTextPosition['y'] + 10 --(allVideoAndAudioTextSize['h'] / 2)

			doubleLeftClick(allVideoAndAudioTextPosition)
			hs.mouse.setAbsolutePosition(originalMousePoint) -- Move mouse back.

			--------------------------------------------------------------------------------
			-- Wait for effects to load:
			--------------------------------------------------------------------------------
			for i=1, 500 do
				if ax.applicationElement(fcpx)[1][whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][whichScrollArea][whichOutline][whichRow]:attributeValue("AXSelected") == true then
					--------------------------------------------------------------------------------
					-- Loaded!
					--------------------------------------------------------------------------------
					goto exitClickAllAudioAndVideoLoop
				else
					--------------------------------------------------------------------------------
					-- Still Loading...
					--------------------------------------------------------------------------------
					sleep(0.01)
					hs.eventtap.leftClick(allVideoAndAudioTextPosition)
					hs.mouse.setAbsolutePosition(originalMousePoint) -- Move mouse back.
				end
			end

			--------------------------------------------------------------------------------
			-- If we get to here, something's gone wrong:
			--------------------------------------------------------------------------------
			displayErrorMessage("Failed to click 'All Video & Audio' After 5 seconds, so something must have gone wrong.")
			return "Failed"

		end
	else
		displayErrorMessage("Unable to find 'All Video & Audio' row.")
		return "Fail"
	end
	::exitClickAllAudioAndVideoLoop::

	--------------------------------------------------------------------------------
	-- Make sure the scroll bar is at the top (if it's visible):
	--------------------------------------------------------------------------------
	if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][3][2] ~= nil then
		scrollBarResult = fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][3][2][1]:setAttributeValue("AXValue", 0)
		if scrollBarResult == nil then
			displayErrorMessage("Failed to adjust Video Effects scroll bar.")
			return "Fail"
		end
	end

	--------------------------------------------------------------------------------
	-- Apply the effect by double clicking:
	--------------------------------------------------------------------------------
	if fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][3][1][1] == nil then
		displayErrorMessage("Failed to find effect.")
		return "Fail"
	else

		--------------------------------------------------------------------------------
		-- Locations:
		--------------------------------------------------------------------------------
		local originalMousePoint = hs.mouse.getAbsolutePosition()
		local effectPosition = fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][3][1][1]:attributeValue("AXPosition")
		local effectSize = fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSplitGroupTwo][3][1][1]:attributeValue("AXSize")

		--------------------------------------------------------------------------------
		-- Get centre of button:
		--------------------------------------------------------------------------------
		effectPosition['x'] = effectPosition['x'] + (effectSize['w'] / 2)
		effectPosition['y'] = effectPosition['y'] + (effectSize['h'] / 2)

		--------------------------------------------------------------------------------
		-- Double Click:
		--------------------------------------------------------------------------------
		doubleLeftClick(effectPosition)

		--------------------------------------------------------------------------------
		-- Put it back:
		--------------------------------------------------------------------------------
		hs.mouse.setAbsolutePosition(originalMousePoint)

	end

	--------------------------------------------------------------------------------
	-- Clear Search Field:
	--------------------------------------------------------------------------------
	hs.timer.doAfter(0.1, function() fcpxElements[whichSplitGroup][whichGroupTwo][whichGroupThree][whichSearchTextField][2]:performAction("AXPress") end )

end

--------------------------------------------------------------------------------
-- HIGHLIGHT FCPX BROWSER PLAYHEAD:
--------------------------------------------------------------------------------
function highlightFCPXBrowserPlayhead()

	--------------------------------------------------------------------------------
	-- Delete any pre-existing highlights:
	--------------------------------------------------------------------------------
	deleteAllHighlights()

	--------------------------------------------------------------------------------
	-- Filmstrip or List Mode?
	--------------------------------------------------------------------------------
	local fcpxBrowserMode = fcpxWhichBrowserMode()

	-- Error Checking:
	if (fcpxBrowserMode == "Failed") then
		displayErrorMessage("Unable to determine if Filmstrip or List Mode.")
		return
	end

	--------------------------------------------------------------------------------
	-- Get all FCPX UI Elements:
	--------------------------------------------------------------------------------
	fcpx = hs.application("Final Cut Pro")
	fcpxElements = ax.applicationElement(fcpx)[1]

	--------------------------------------------------------------------------------
	-- Which Split Group:
	--------------------------------------------------------------------------------
	local whichSplitGroup = nil
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
		if whichSplitGroup == nil then
			if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
				whichSplitGroup = i
			end
		end
	end
	if whichSplitGroup == nil then
		displayErrorMessage("Unable to locate Split Group.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- List Mode:
	--------------------------------------------------------------------------------
	if fcpxBrowserMode == "List" then

		--------------------------------------------------------------------------------
		-- Which Group contains the browser:
		--------------------------------------------------------------------------------
		local whichGroup = nil
		for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
			if whichGroupGroup == nil then
				if fcpxElements[whichSplitGroup][i]:attributeValue("AXRole") == "AXGroup" then
					--------------------------------------------------------------------------------
					-- We now have ALL of the groups, and need to work out which group we actually want:
					--------------------------------------------------------------------------------
					for x=1, fcpxElements[whichSplitGroup][i]:attributeValueCount("AXChildren") do
						if fcpxElements[whichSplitGroup][i][x]:attributeValue("AXRole") == "AXSplitGroup" then
							--------------------------------------------------------------------------------
							-- Which Split Group is it:
							--------------------------------------------------------------------------------
							for y=1, fcpxElements[whichSplitGroup][i][x]:attributeValueCount("AXChildren") do
								if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXRole") == "AXSplitGroup" then
									if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXIdentifier") == "_NS:231" then
										whichGroup = i
										goto listGroupDone
									end
								end
							end
						end
					end
				end
			end
		end
		::listGroupDone::
		if whichGroup == nil then
			displayErrorMessage("Unable to locate Group.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Split Group Two:
		--------------------------------------------------------------------------------
		local whichSplitGroupTwo = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup]:attributeValueCount("AXChildren")) do
			if whichSplitGroupTwo == nil then
				if fcpxElements[whichSplitGroup][whichGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
					whichSplitGroupTwo = i
					goto listSplitGroupTwo
				end
			end
		end
		::listSplitGroupTwo::
		if whichSplitGroupTwo == nil then
			displayErrorMessage("Unable to locate Split Group Two.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Split Group Three:
		--------------------------------------------------------------------------------
		local whichSplitGroupThree = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValueCount("AXChildren")) do
			if whichSplitGroupThree == nil then
				if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
					whichSplitGroupThree = i
					goto listSplitGroupThree
				end
			end
		end
		::listSplitGroupThree::
		if whichSplitGroupThree == nil then
			displayErrorMessage("Unable to locate Split Group Three.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Group Two:
		--------------------------------------------------------------------------------
		local whichGroupTwo = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
				whichGroupTwo = i
			end
		end
		if whichGroupTwo == nil then
			displayErrorMessage("Unable to locate Group Two.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which is Persistent Playhead?
		--------------------------------------------------------------------------------
		local whichPersistentPlayhead = (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichGroupTwo]:attributeValueCount("AXChildren")) - 1

		--------------------------------------------------------------------------------
		-- Let's highlight it at long last!
		--------------------------------------------------------------------------------
		if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichGroupTwo][whichPersistentPlayhead] == nil then
			displayErrorMessage("Unable to locate Persistent Playhead.")
			return "Failed"
		else
			persistentPlayheadPosition = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichGroupTwo][whichPersistentPlayhead]:attributeValue("AXPosition")
			persistentPlayheadSize = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichGroupTwo][whichPersistentPlayhead]:attributeValue("AXSize")
			mouseHighlight(persistentPlayheadPosition["x"], persistentPlayheadPosition["y"], persistentPlayheadSize["w"], persistentPlayheadSize["h"])
		end

	--------------------------------------------------------------------------------
	-- Filmstrip Mode:
	--------------------------------------------------------------------------------
	elseif fcpxBrowserMode == "Filmstrip" then

		--------------------------------------------------------------------------------
		-- Which Group contains the browser:
		--------------------------------------------------------------------------------
		local whichGroup = nil
		for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
			if whichGroupGroup == nil then
				if fcpxElements[whichSplitGroup][i]:attributeValue("AXRole") == "AXGroup" then
					--------------------------------------------------------------------------------
					-- We now have ALL of the groups, and need to work out which group we actually want:
					--------------------------------------------------------------------------------
					for x=1, fcpxElements[whichSplitGroup][i]:attributeValueCount("AXChildren") do
						if fcpxElements[whichSplitGroup][i][x]:attributeValue("AXRole") == "AXSplitGroup" then
							--------------------------------------------------------------------------------
							-- Which Split Group is it:
							--------------------------------------------------------------------------------
							for y=1, fcpxElements[whichSplitGroup][i][x]:attributeValueCount("AXChildren") do
								if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXRole") == "AXScrollArea" then
									if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXIdentifier") == "_NS:40" then
										whichGroup = i
										goto filmstripGroupDone
									end
								end
							end
						end
					end
				end
			end
		end
		::filmstripGroupDone::
		if whichGroup == nil then
			displayErrorMessage("Unable to locate Group.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Split Group Two:
		--------------------------------------------------------------------------------
		local whichSplitGroupTwo = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup]:attributeValueCount("AXChildren")) do
			if whichSplitGroupTwo == nil then
				if fcpxElements[whichSplitGroup][whichGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
					whichSplitGroupTwo = i
					goto filmstripSplitGroupTwoDone
				end
			end
		end
		::filmstripSplitGroupTwoDone::
		if whichSplitGroupTwo == nil then
			displayErrorMessage("Unable to locate Split Group Two.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Scroll Area:
		--------------------------------------------------------------------------------
		local whichScrollArea = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXScrollArea" then
				whichScrollArea = i
			end
		end
		if whichScrollArea == nil then
			displayErrorMessage("Unable to locate Scroll Area.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Group Two:
		--------------------------------------------------------------------------------
		local whichGroupTwo = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
				whichGroupTwo = i
			end
		end
		if whichGroupTwo == nil then
			displayErrorMessage("Unable to locate Group Two.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which is Persistent Playhead?
		--------------------------------------------------------------------------------
		local whichPersistentPlayhead = (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo]:attributeValueCount("AXChildren")) - 1

		--------------------------------------------------------------------------------
		-- Let's highlight it at long last!
		--------------------------------------------------------------------------------
		if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo][whichPersistentPlayhead] == nil then
			displayErrorMessage("Unable to locate Persistent Playhead.")
			return "Failed"
		else
			persistentPlayheadPosition = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo][whichPersistentPlayhead]:attributeValue("AXPosition")
			persistentPlayheadSize = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo][whichPersistentPlayhead]:attributeValue("AXSize")
			mouseHighlight(persistentPlayheadPosition["x"], persistentPlayheadPosition["y"], persistentPlayheadSize["w"], persistentPlayheadSize["h"])
		end
	end
end

--------------------------------------------------------------------------------
-- BATCH EXPORT FROM BROWSER:
--------------------------------------------------------------------------------
function batchExportToCompressor()

	--------------------------------------------------------------------------------
	-- Delete any pre-existing highlights:
	--------------------------------------------------------------------------------
	deleteAllHighlights()

	--------------------------------------------------------------------------------
	-- Check that there's a default destination:
	--------------------------------------------------------------------------------
	local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFShareDestinationsDefaultDestinationIndex")
	if executeStatus == nil then
		displayErrorMessage("Failed to access the Final Cut Pro preferences when trying to work out Default Share Destination.")
		return "Failed"
	end
	if tonumber(executeResult) > 10000 then
			local appleScriptA = [[
			activate application "Final Cut Pro"
			tell application "System Events"
				tell process "Final Cut Pro"
					display dialog "It doesn't look like you have a Default Destination selected." & return & return & "You can set a Default Destination by going to 'Preferences', clicking the 'Destinations' tab, right-clicking on the Destination you would like to use and then click 'Make Default'." buttons {"Close"} with icon fcpxIcon
					set frontmost to true
				end tell
			end tell
		]]
		local ok,dialogBoxResult = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA)
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Get Current FCPX Save Location:
	--------------------------------------------------------------------------------
	local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist NSNavLastRootDirectory -string")
	if executeStatus == nil then
		displayErrorMessage("We could not determine the last place you exported a file to. If this is the first time you've used Final Cut Pro, please do a test export prior to using this tool.")
		return "Failed"
	end
	local lastSavePath = trim(executeResult)

	--------------------------------------------------------------------------------
	-- Filmstrip or List Mode?
	--------------------------------------------------------------------------------
	local fcpxBrowserMode = fcpxWhichBrowserMode()
	if (fcpxBrowserMode == "Failed") then -- Error Checking:
		displayErrorMessage("Unable to determine if Filmstrip or List Mode.")
		return
	end

	--------------------------------------------------------------------------------
	-- Get all FCPX UI Elements:
	--------------------------------------------------------------------------------
	fcpx = hs.application("Final Cut Pro")
	fcpxElements = ax.applicationElement(fcpx)[1]

	--------------------------------------------------------------------------------
	-- Which Split Group:
	--------------------------------------------------------------------------------
	local whichSplitGroup = nil
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
		if whichSplitGroup == nil then
			if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
				whichSplitGroup = i
			end
		end
	end
	if whichSplitGroup == nil then
		displayErrorMessage("Unable to locate Split Group.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- List Mode:
	--------------------------------------------------------------------------------
	if fcpxBrowserMode == "List" then

		--------------------------------------------------------------------------------
		-- Which Group contains the browser:
		--------------------------------------------------------------------------------
		whichGroup = nil
		for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
			if whichGroupGroup == nil then
				if fcpxElements[whichSplitGroup][i]:attributeValue("AXRole") == "AXGroup" then
					--------------------------------------------------------------------------------
					-- We now have ALL of the groups, and need to work out which group we actually want:
					--------------------------------------------------------------------------------
					for x=1, fcpxElements[whichSplitGroup][i]:attributeValueCount("AXChildren") do
						if fcpxElements[whichSplitGroup][i][x]:attributeValue("AXRole") == "AXSplitGroup" then
							--------------------------------------------------------------------------------
							-- Which Split Group is it:
							--------------------------------------------------------------------------------
							for y=1, fcpxElements[whichSplitGroup][i][x]:attributeValueCount("AXChildren") do
								if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXRole") == "AXSplitGroup" then
									if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXIdentifier") == "_NS:231" then
										whichGroup = i
										goto listGroupDone
									end
								end
							end
						end
					end
				end
			end
		end
		::listGroupDone::
		if whichGroup == nil then
			local appleScriptA = [[
				activate application "Final Cut Pro"
				tell application "System Events"
					tell process "Final Cut Pro"
						display dialog "It doesn't look like you have any clips selected in the Library?" buttons {"Close"} with icon fcpxIcon
						set frontmost to true
					end tell
				end tell
			]]
			local ok,dialogBoxResult = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA)
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Split Group Two:
		--------------------------------------------------------------------------------
		whichSplitGroupTwo = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup]:attributeValueCount("AXChildren")) do
			if whichSplitGroupTwo == nil then
				if fcpxElements[whichSplitGroup][whichGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
					whichSplitGroupTwo = i
					goto listSplitGroupTwo
				end
			end
		end
		::listSplitGroupTwo::
		if whichSplitGroupTwo == nil then
			displayErrorMessage("Unable to locate Split Group Two.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Split Group Three:
		--------------------------------------------------------------------------------
		whichSplitGroupThree = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValueCount("AXChildren")) do
			if whichSplitGroupThree == nil then
				if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
					whichSplitGroupThree = i
					goto listSplitGroupThree
				end
			end
		end
		::listSplitGroupThree::
		if whichSplitGroupThree == nil then
			displayErrorMessage("Unable to locate Split Group Three.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Scroll Area:
		--------------------------------------------------------------------------------
		whichScrollArea = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXScrollArea" then
				whichScrollArea = i
			end
		end
		if whichScrollArea == nil then
			displayErrorMessage("Unable to locate Scroll Area.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Outline:
		--------------------------------------------------------------------------------
		whichOutline = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXOutline" then
				whichOutline = i
			end
		end
		if whichOutline == nil then
			displayErrorMessage("Unable to locate Outline.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Rows's (can be multiple):
		--------------------------------------------------------------------------------
		whichRows = {nil}
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea][whichOutline]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea][whichOutline]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXRow" then
				if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea][whichOutline]:attributeValue("AXChildren")[i]:attributeValue("AXSelected") == true then
					whichRows[#whichRows + 1] = i
				end
			end
		end

	--------------------------------------------------------------------------------
	-- Filmstrip Mode:
	--------------------------------------------------------------------------------
	elseif fcpxBrowserMode == "Filmstrip" then

		--------------------------------------------------------------------------------
		-- Which Group contains the browser:
		--------------------------------------------------------------------------------
		whichGroup = nil
		for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
			if whichGroupGroup == nil then
				if fcpxElements[whichSplitGroup][i]:attributeValue("AXRole") == "AXGroup" then
					--------------------------------------------------------------------------------
					-- We now have ALL of the groups, and need to work out which group we actually want:
					--------------------------------------------------------------------------------
					for x=1, fcpxElements[whichSplitGroup][i]:attributeValueCount("AXChildren") do
						if fcpxElements[whichSplitGroup][i][x]:attributeValue("AXRole") == "AXSplitGroup" then
							--------------------------------------------------------------------------------
							-- Which Split Group is it:
							--------------------------------------------------------------------------------
							for y=1, fcpxElements[whichSplitGroup][i][x]:attributeValueCount("AXChildren") do
								if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXRole") == "AXScrollArea" then
									if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXIdentifier") == "_NS:40" then
										whichGroup = i
										goto filmstripGroupDone
									end
								end
							end
						end
					end
				end
			end
		end
		::filmstripGroupDone::
		if whichGroup == nil then
			displayErrorMessage("Unable to locate Group.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Split Group Two:
		--------------------------------------------------------------------------------
		whichSplitGroupTwo = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup]:attributeValueCount("AXChildren")) do
			if whichSplitGroupTwo == nil then
				if fcpxElements[whichSplitGroup][whichGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
					whichSplitGroupTwo = i
					goto filmstripSplitGroupTwoDone
				end
			end
		end
		::filmstripSplitGroupTwoDone::
		if whichSplitGroupTwo == nil then
			displayErrorMessage("Unable to locate Split Group Two.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Scroll Area:
		--------------------------------------------------------------------------------
		whichScrollArea = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXScrollArea" then
				whichScrollArea = i
			end
		end
		if whichScrollArea == nil then
			displayErrorMessage("Unable to locate Scroll Area.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Group Two:
		--------------------------------------------------------------------------------
		whichGroupTwo = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
				whichGroupTwo = i
			end
		end
		if whichGroupTwo == nil then
			displayErrorMessage("Unable to locate Group Two.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Group Three's (can be multiple):
		--------------------------------------------------------------------------------
		whichGroupThree = {}
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
				if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXSelectedChildren")[1] ~= nil then
					whichGroupThree[#whichGroupThree + 1] = i
				end
			end
		end
	end

	--------------------------------------------------------------------------------
	-- How many clips (regardless of Filmstrip or List mode)?
	--------------------------------------------------------------------------------
	local howManyClips = 0
	if fcpxBrowserMode == "Filmstrip" then howManyClips = #whichGroupThree end
	if fcpxBrowserMode == "List" then howManyClips = #whichRows end

	--------------------------------------------------------------------------------
	-- How many times cancel is forced during the Batch Export:
	--------------------------------------------------------------------------------
	cancelCount = 0

	--------------------------------------------------------------------------------
	-- If no clips are selected, then what about Keywords, Events or Libraries?
	--------------------------------------------------------------------------------
	if howManyClips == 0 then

		--------------------------------------------------------------------------------
		-- Which Library Scroll Area:
		--------------------------------------------------------------------------------
		whichLibraryScrollArea = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXScrollArea" then
				if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXIdentifier") == "_NS:32" then
					whichLibraryScrollArea = i
				end
			end
		end
		if whichLibraryScrollArea == nil then
			displayErrorMessage("Unable to locate Library Scroll Area.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- NOTE: There's only one AXOutline next so just use [1].
		--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Which Library Role:
		--------------------------------------------------------------------------------
		whichLibraryRows = {}
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichLibraryScrollArea][1]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichLibraryScrollArea][1]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXRow" then
				if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichLibraryScrollArea][1]:attributeValue("AXChildren")[i]:attributeValue("AXSelected") == true then
					whichLibraryRows[#whichLibraryRows + 1] = i
				end
			end
		end

		if #whichLibraryRows == 0 then
			displayErrorMessage("Unable to locate Library Role.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Display Dialog to make sure the current path is acceptable:
		--------------------------------------------------------------------------------
		local appleScriptA = 'set howManyClips to "' .. #whichLibraryRows .. '"\n'
		local appleScriptB = 'set lastSavePath to "' .. lastSavePath .. '"\n'
		local appleScriptC = [[
			activate application "Final Cut Pro"
			tell application "System Events"
				tell process "Final Cut Pro"
					try
						if howManyClips is equal to "1" then
							display dialog "Final Cut Pro will export the contents of the selected item using your default export settings to the following location:" & return & return & lastSavePath & return & return & "If you wish to change this location, export something else with your preferred destination first." & return & return & "Please do not move the mouse or interrupt Final Cut Pro once you press the Continue button as it may break the automation." & return & return & "If there's already a file with the same name in the export destination then that clip will be skipped." buttons {"Continue Batch Export", "Cancel"} with icon fcpxIcon
						else
							display dialog "Final Cut Pro will export the contents of the " & howManyClips & " selected items using your default export settings to the following location:" & return & return & lastSavePath & return & return & "If you wish to change this location, export something else with your preferred destination first." & return & return & "Please do not move the mouse or interrupt Final Cut Pro once you press the Continue button as it may break the automation." & return & return & "If there's already a file with the same name in the export destination then that clip will be skipped." buttons {"Continue Batch Export", "Cancel"} with icon fcpxIcon
						end if
					on error
						return "Failed"
					end try
					if the button returned of the result is "Continue Batch Export" then
						return "Done"
					end if
					set frontmost to true
				end tell
			end tell
		]]
		local ok,dialogBoxResult = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB .. appleScriptC)

		--------------------------------------------------------------------------------
		-- Abort when Cancel is pressed:
		--------------------------------------------------------------------------------
		if dialogBoxResult == "Failed" then return "Failed" end

		--------------------------------------------------------------------------------
		-- If was previously in Filmstrip mode - need to get data as if from list:
		--------------------------------------------------------------------------------
		if fcpxBrowserMode == "Filmstrip" then

			--------------------------------------------------------------------------------
			-- Switch to list mode:
			--------------------------------------------------------------------------------
			viewAsListResult = fcpx:selectMenuItem({"View", "Browser", "as List"})
			if viewAsListResult == nil then
				displayErrorMessage("Failed to switch to list mode.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Trigger Group clips by None:
			--------------------------------------------------------------------------------
			groupClipsByResult = fcpx:selectMenuItem({"View", "Browser", "Group Clips By", "None"})
			if groupClipsByResult == nil then
				displayErrorMessage("Failed to switch to Group Clips by None.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Which Group contains the browser:
			--------------------------------------------------------------------------------
			whichGroup = nil
			for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
				if whichGroupGroup == nil then
					if fcpxElements[whichSplitGroup][i]:attributeValue("AXRole") == "AXGroup" then
						--------------------------------------------------------------------------------
						-- We now have ALL of the groups, and need to work out which group we actually want:
						--------------------------------------------------------------------------------
						for x=1, fcpxElements[whichSplitGroup][i]:attributeValueCount("AXChildren") do
							if fcpxElements[whichSplitGroup][i][x]:attributeValue("AXRole") == "AXSplitGroup" then
								--------------------------------------------------------------------------------
								-- Which Split Group is it:
								--------------------------------------------------------------------------------
								for y=1, fcpxElements[whichSplitGroup][i][x]:attributeValueCount("AXChildren") do
									if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXRole") == "AXSplitGroup" then
										if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXIdentifier") == "_NS:231" then
											whichGroup = i
											goto listGroupDoneA
										end
									end
								end
							end
						end
					end
				end
			end
			::listGroupDoneA::
			if whichGroup == nil then
				displayErrorMessage("Unable to locate Group.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Which Split Group Two:
			--------------------------------------------------------------------------------
			whichSplitGroupTwo = nil
			for i=1, (fcpxElements[whichSplitGroup][whichGroup]:attributeValueCount("AXChildren")) do
				if whichSplitGroupTwo == nil then
					if fcpxElements[whichSplitGroup][whichGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
						whichSplitGroupTwo = i
						goto listSplitGroupTwoA
					end
				end
			end
			::listSplitGroupTwoA::
			if whichSplitGroupTwo == nil then
				displayErrorMessage("Unable to locate Split Group Two.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Which Split Group Three:
			--------------------------------------------------------------------------------
			whichSplitGroupThree = nil
			for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValueCount("AXChildren")) do
				if whichSplitGroupThree == nil then
					if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
						whichSplitGroupThree = i
						goto listSplitGroupThreeA
					end
				end
			end
			::listSplitGroupThreeA::
			if whichSplitGroupThree == nil then
				displayErrorMessage("Unable to locate Split Group Three.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Which Scroll Area:
			--------------------------------------------------------------------------------
			whichScrollArea = nil
			for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree]:attributeValueCount("AXChildren")) do
				if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXScrollArea" then
					whichScrollArea = i
				end
			end
			if whichScrollArea == nil then
				displayErrorMessage("Unable to locate Scroll Area.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Which Outline:
			--------------------------------------------------------------------------------
			whichOutline = nil
			for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea]:attributeValueCount("AXChildren")) do
				if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXOutline" then
					whichOutline = i
				end
			end
			if whichOutline == nil then
				displayErrorMessage("Unable to locate Outline.")
				return "Failed"
			end

		end

		--------------------------------------------------------------------------------
		-- Now we need to apply to each row:
		--------------------------------------------------------------------------------
		for i=1, #whichLibraryRows do

			--------------------------------------------------------------------------------
			-- Select Left Panel Item:
			--------------------------------------------------------------------------------
			fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichLibraryScrollArea][1][whichLibraryRows[i]]:setAttributeValue("AXSelected", true)

			--------------------------------------------------------------------------------
			-- Get all individual items from right panel:
			--------------------------------------------------------------------------------
			local whichRows = {}
			if whichRows ~= nil then -- Clear whichRows if needed.
				for k in pairs (whichRows) do
					whichRows[k] = nil
				end
			end
			for ii=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea][whichOutline]:attributeValueCount("AXChildren")) do
				if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea][whichOutline]:attributeValue("AXChildren")[ii]:attributeValue("AXRole") == "AXRow" then
					if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea][whichOutline]:attributeValue("AXChildren")[ii][1]:attributeValue("AXRole") == "AXGroup" then
						if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea][whichOutline]:attributeValue("AXChildren")[ii][1][2]:attributeValue("AXDescription") == "Organizer filmlist name column" then
							whichRows[#whichRows + 1] = ii
						end
					end
				end
			end

			if #whichRows == 0 then
				displayErrorMessage("Nothing in the selected item.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Bring Focus Back to Clips:
			--------------------------------------------------------------------------------
			local originalMousePoint = hs.mouse.getAbsolutePosition()
			local listPosition = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea]:attributeValue("AXPosition")
			hs.eventtap.leftClick(listPosition)
			hs.mouse.setAbsolutePosition(originalMousePoint)

			--------------------------------------------------------------------------------
			-- Begin Clip Loop:
			--------------------------------------------------------------------------------
			for x=1, #whichRows do

				--------------------------------------------------------------------------------
				-- Select clip:
				--------------------------------------------------------------------------------
				fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea][whichOutline][whichRows[x]]:setAttributeValue("AXSelected", true)

				--------------------------------------------------------------------------------
				-- Trigger CMD+E (Export Using Default Share)
				--------------------------------------------------------------------------------
				if not keyStrokeFromPlist("ShareDefaultDestination") then
					displayErrorMessage("Failed to trigger the 'Export using Default Share Destination' Shortcut.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- Wait for window to open:
				--------------------------------------------------------------------------------
				fcpxExportWindow = ax.applicationElement(fcpx)

				local timeoutCount = 0
				local exportWindowOpen = false

				::waitForExportWindowA::
				whichExportWindow = nil
				for yi=1, (fcpxExportWindow:attributeValueCount("AXChildren")) do
					if fcpxExportWindow:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXWindow" then
						for yx=1, fcpxExportWindow:attributeValue("AXChildren")[yi]:attributeValueCount("AXChildren") do
							if fcpxExportWindow[yi][yx]:attributeValue("AXRole") == "AXImage" then
								if fcpxExportWindow[yi][yx]:attributeValue("AXDescription") == "Share WindowBackground" then
									exportWindowOpen = true
									whichExportWindow = yi
								end
							end
						end
					end
				end

				if exportWindowOpen == false then
					timeoutCount = timeoutCount + 1
					if timeoutCount == 10 then
						displayErrorMessage("It took too long for Export Window to open so I gave up.")
						return "Failed"
					else
						sleep(0.5)
						goto waitForExportWindowA
					end
				end

				--------------------------------------------------------------------------------
				-- Find Next Button:
				--------------------------------------------------------------------------------
				whichNextButton = nil
				for yi=1, (fcpxExportWindow[whichExportWindow]:attributeValueCount("AXChildren")) do
					if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXButton" then
						if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[yi]:attributeValue("AXTitle") == "Next…" then
							whichNextButton = yi
						end
					end
				end
				if whichNextButton == nil then
					displayErrorMessage("Unable to locate Group Two.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- Then press it:
				--------------------------------------------------------------------------------
				pressNextButtonResult = fcpxExportWindow[whichExportWindow][whichNextButton]:performAction("AXPress")
				if pressNextButtonResult == nil then
					displayErrorMessage("Unable to press Next Button.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- Wait for Save Window to Open:
				--------------------------------------------------------------------------------
				local timeoutCount = 0
				local saveWindowOpen = false

				whichSaveSheet = nil

				::waitForSaveWindowA::
				for yi=1, (fcpxExportWindow[whichExportWindow]:attributeValueCount("AXChildren")) do
					if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXSheet" then
						if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[yi]:attributeValue("AXDescription") == "save" then
							whichSaveSheet = yi
							saveWindowOpen = true
						end
					end
				end
				if whichSaveSheet == nil then
					displayErrorMessage("Unable to locate Save Window.")
					return "Failed"
				end

				if saveWindowOpen == false then
					timeoutCount = timeoutCount + 1
					if timeoutCount == 10 then
						displayErrorMessage("It took too long for Save Window to open so I gave up.")
						return "Failed"
					else
						sleep(0.5)
						goto waitForSaveWindowA
					end
				end

				--------------------------------------------------------------------------------
				-- Find Save Button:
				--------------------------------------------------------------------------------
				whichSaveButton = nil
				for yi=1, (fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValueCount("AXChildren")) do
					if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXButton" then
						if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[yi]:attributeValue("AXTitle") == "Save" then
							whichSaveButton = yi
						end
					end
				end
				if whichSaveButton == nil then
					displayErrorMessage("Unable to locate Group Two.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- Press Save Button:
				--------------------------------------------------------------------------------
				local pressSaveButtonResult = fcpxExportWindow[whichExportWindow][whichSaveSheet][whichSaveButton]:performAction("AXPress")
				if pressSaveButtonResult == nil then
					displayErrorMessage("Unable to press Save Button.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- Make sure Save Window is closed:
				--------------------------------------------------------------------------------
				local timeoutCount = 0

				::checkSaveWindowIsClosedA::
				if fcpxExportWindow[whichExportWindow][whichSaveSheet] == nil then
					-- Continue on...
				else
					--------------------------------------------------------------------------------
					-- If an alert appears, click Cancel:
					--------------------------------------------------------------------------------
					whichAlertSheet = nil
					whichAlertButton = nil
					performCancel = false
					for yi=1, (fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValueCount("AXChildren")) do
						if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXSheet" then
							if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[yi]:attributeValue("AXDescription") == "alert" then
								for yx=1, fcpxExportWindow[whichExportWindow][whichSaveSheet][yi]:attributeValueCount("AXChildren") do
									if fcpxExportWindow[whichExportWindow][whichSaveSheet][yi][yx]:attributeValue("AXRole") == "AXButton" then
										if fcpxExportWindow[whichExportWindow][whichSaveSheet][yi][yx]:attributeValue("AXTitle") == "Cancel" then
											whichAlertSheet = yi
											whichAlertButton = yx
											performCancel = true
										end
									end
								end
							end
						end
					end
					if performCancel then
						cancelCount = cancelCount + 1

						--------------------------------------------------------------------------------
						-- Press Cancel on the Alert:
						--------------------------------------------------------------------------------
						local pressCancelButton = fcpxExportWindow[whichExportWindow][whichSaveSheet][whichAlertSheet][whichAlertButton]:performAction("AXPress")
						if pressCancelButton == nil then
							displayErrorMessage("Unable to press Cancel Button on the Alert.")
							return "Failed"
						end

						--------------------------------------------------------------------------------
						-- Press Cancel on the Save Dialog:
						--------------------------------------------------------------------------------
						whichCancelButton = nil
						for yi=1, (fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValueCount("AXChildren")) do
							if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXButton" then
								if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[yi]:attributeValue("AXTitle") == "Cancel" then
									whichCancelButton = yi
								end
							end
						end
						if whichCancelButton == nil then
							displayErrorMessage("Unable to locate the cancel button.")
							return "Failed"
						end
						local pressCancelButton = fcpxExportWindow[whichExportWindow][whichSaveSheet][whichCancelButton]:performAction("AXPress")
						if pressCancelButton == nil then
							displayErrorMessage("Unable to press Cancel Button on Save Dialog.")
							return "Failed"
						end

						--------------------------------------------------------------------------------
						-- Press Cancel on the Export Window:
						--------------------------------------------------------------------------------
						whichCancelExportButton = nil
						for yi=1, (fcpxExportWindow[whichExportWindow]:attributeValueCount("AXChildren")) do
							if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXButton" then
								if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[yi]:attributeValue("AXTitle") == "Cancel" then
									whichCancelExportButton = yi
								end
							end
						end
						if whichCancelExportButton == nil then
							displayErrorMessage("Unable to locate Group Two.")
							return "Failed"
						end
						local pressCancelButton = fcpxExportWindow[whichExportWindow][whichCancelExportButton]:performAction("AXPress")
						if pressCancelButton == nil then
							displayErrorMessage("Unable to press Cancel Button on Export Window.")
							return "Failed"
						end

						goto nextClipInListQueueA

					end -- Perform Cancel

					timeoutCount = timeoutCount + 1
					if timeoutCount == 20 then
						displayErrorMessage("It took too long for the Save Window to close so I gave up.")
						return "Failed"
					else
						sleep(0.5)
						goto checkSaveWindowIsClosedA
					end
				end -- Save Sheet Closed
				::nextClipInListQueueA::
			end -- x loop
		end -- i loop
	else
	--------------------------------------------------------------------------------
	-- Single Keyword or Smart Selection:
	--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Display Dialog to make sure the current path is acceptable:
		--------------------------------------------------------------------------------
		local appleScriptA = 'set howManyClips to "' .. howManyClips .. '"\n'
		local appleScriptB = 'set lastSavePath to "' .. lastSavePath .. '"\n'
		local appleScriptC = [[
			activate application "Final Cut Pro"
			tell application "System Events"
				tell process "Final Cut Pro"
					try
						if howManyClips is "1" then
							display dialog "Final Cut Pro will export this clip using your default export settings to the following location:" & return & return & lastSavePath & return & return & "If you wish to change this location, export something else with your preferred destination first." & return & return & "Please do not move the mouse or interrupt Final Cut Pro once you press the Continue button as it may break the automation." & return & return & "If there's already a file with the same name in the export destination then that clip will be skipped." buttons {"Continue Batch Export", "Cancel"} with icon fcpxIcon
						else
							display dialog "Final Cut Pro will export these " & howManyClips & " clips using your default export settings to the following location:" & return & return & lastSavePath & return & return & "If you wish to change this location, export something else with your preferred destination first." & return & return & "Please do not move the mouse or interrupt Final Cut Pro once you press the Continue button as it may break the automation." & return & return & "If there's already a file with the same name in the export destination then that clip will be skipped." buttons {"Continue Batch Export", "Cancel"} with icon fcpxIcon
						end if
					on error
						return "Failed"
					end try
					if the button returned of the result is "Continue Batch Export" then
						return "Done"
					end if
					set frontmost to true
				end tell
			end tell
		]]
		local ok,dialogBoxResult = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB .. appleScriptC)

		--------------------------------------------------------------------------------
		-- Abort when Cancel is pressed:
		--------------------------------------------------------------------------------
		if dialogBoxResult == "Failed" then return "Failed" end

		--------------------------------------------------------------------------------
		-- Bring Focus Back to Clips:
		--------------------------------------------------------------------------------
		if fcpxBrowserMode == "List" then
			local originalMousePoint = hs.mouse.getAbsolutePosition()
			local listPosition = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea][whichOutline][1]:attributeValue("AXPosition")
			hs.eventtap.leftClick(listPosition)
			hs.mouse.setAbsolutePosition(originalMousePoint)
		end

		--------------------------------------------------------------------------------
		-- Let the games begin!
		--------------------------------------------------------------------------------
		if fcpxBrowserMode == "Filmstrip" then
			for i=1, #whichGroupThree do

				--------------------------------------------------------------------------------
				-- Which Layout Item:
				--------------------------------------------------------------------------------
				whichLayoutItem = nil
				local noRangeSelected = false
				for x=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo][whichGroupThree[i]]:attributeValueCount("AXChildren")) do
					if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo][whichGroupThree[i]]:attributeValue("AXChildren")[x]:attributeValue("AXRole") == "AXLayoutItem" then
						whichLayoutItem = x
					else
						--------------------------------------------------------------------------------
						-- If one of the clips doesn't have a range selected:
						--------------------------------------------------------------------------------
						if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo][whichGroupThree[i]]:attributeValue("AXChildren")[x]:attributeValue("AXRole") == "AXImage" then
							whichLayoutItem = x
							noRangeSelected = true
						end
					end
				end
				if whichLayoutItem == nil then
					displayErrorMessage("Unable to locate Layout Item.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- If one of the clips doesn't have a range selected:
				--------------------------------------------------------------------------------
				::checkClipPositionTop::
				if noRangeSelected then
					clipPosition = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo][whichGroupThree[i]][whichLayoutItem]:attributeValue("AXPosition")
				else
					clipPosition = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo][whichGroupThree[i]][whichLayoutItem][1]:attributeValue("AXPosition")
				end

				clipPosition['x'] = clipPosition['x'] + 5
				clipPosition['y'] = clipPosition['y'] + 10

				--------------------------------------------------------------------------------
				-- Make sure the clip is actually visible:
				--------------------------------------------------------------------------------
				local scrollAreaPosition = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea]:attributeValue("AXPosition")
				local scrollAreaSize = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea]:attributeValue("AXSize")

					--------------------------------------------------------------------------------
					-- Need to scroll up:
					--------------------------------------------------------------------------------
					if clipPosition['y'] < scrollAreaPosition['y'] then
						local scrollBarValue = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][2][1]:attributeValue("AXValue")
						fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][2][1]:setAttributeValue("AXValue", (scrollBarValue - 0.02))
						goto checkClipPositionTop
					end

					--------------------------------------------------------------------------------
					-- Need to scroll down:
					--------------------------------------------------------------------------------
					if clipPosition['y'] > (scrollAreaPosition['y']+scrollAreaSize['h']) then
						local scrollBarValue = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][2][1]:attributeValue("AXValue")
						fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][2][1]:setAttributeValue("AXValue", (scrollBarValue + 0.02))
						goto checkClipPositionTop
					end

				--------------------------------------------------------------------------------
				-- Click Thumbnail:
				--------------------------------------------------------------------------------
				local originalMousePoint = hs.mouse.getAbsolutePosition()
				hs.eventtap.leftClick(clipPosition)
				hs.mouse.setAbsolutePosition(originalMousePoint)

				--------------------------------------------------------------------------------
				-- Trigger CMD+E (Export Using Default Share):
				--------------------------------------------------------------------------------
				if not keyStrokeFromPlist("ShareDefaultDestination") then
					displayErrorMessage("Failed to trigger the 'Export using Default Share Destination' Shortcut.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- Wait for window to open:
				--------------------------------------------------------------------------------
				fcpxExportWindow = ax.applicationElement(fcpx)

				local timeoutCount = 0
				local exportWindowOpen = false

				::waitForExportWindowC::
				whichExportWindow = nil
				for yi=1, (fcpxExportWindow:attributeValueCount("AXChildren")) do
					if fcpxExportWindow:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXWindow" then
						for yx=1, fcpxExportWindow:attributeValue("AXChildren")[yi]:attributeValueCount("AXChildren") do
							if fcpxExportWindow[yi][yx]:attributeValue("AXRole") == "AXImage" then
								if fcpxExportWindow[yi][yx]:attributeValue("AXDescription") == "Share WindowBackground" then

									exportWindowOpen = true
									whichExportWindow = yi
								end
							end
						end
					end
				end

				if exportWindowOpen == false then
					timeoutCount = timeoutCount + 1
					if timeoutCount == 5 then
						displayErrorMessage("It took too long (five seconds) for Export Window to open so I gave up.")
						return "Failed"
					else
						sleep(1)
						goto waitForExportWindowC
					end
				end

				--------------------------------------------------------------------------------
				-- Find Next Button:
				--------------------------------------------------------------------------------
				whichNextButton = nil
				for yi=1, (fcpxExportWindow[whichExportWindow]:attributeValueCount("AXChildren")) do
					if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXButton" then
						if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[yi]:attributeValue("AXTitle") == "Next…" then
							whichNextButton = yi
						end
					end
				end
				if whichNextButton == nil then
					displayErrorMessage("Unable to locate Group Two.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- Then press it:
				--------------------------------------------------------------------------------
				local pressNextButtonResult = fcpxExportWindow[whichExportWindow][whichNextButton]:performAction("AXPress")
				if pressNextButtonResult == nil then
					displayErrorMessage("Failed to press Next Button.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- Wait for Save Window to Open:
				--------------------------------------------------------------------------------
				local timeoutCount = 0
				local saveWindowOpen = false

				whichSaveSheet = nil

				::waitForSaveWindowC::
				for yi=1, (fcpxExportWindow[whichExportWindow]:attributeValueCount("AXChildren")) do
					if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXSheet" then
						if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[yi]:attributeValue("AXDescription") == "save" then
							whichSaveSheet = yi
							saveWindowOpen = true
						end
					end
				end
				if whichSaveSheet == nil then
					displayErrorMessage("Unable to locate Save Window.")
					return "Failed"
				end

				if saveWindowOpen == false then
					timeoutCount = timeoutCount + 1
					if timeoutCount == 10 then
						displayErrorMessage("It took too long for Save Window to open so I gave up.")
						return "Failed"
					else
						sleep(0.5)
						goto waitForSaveWindowC
					end
				end

				--------------------------------------------------------------------------------
				-- Find Save Button:
				--------------------------------------------------------------------------------
				whichSaveButton = nil
				for yi=1, (fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValueCount("AXChildren")) do
					if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXButton" then
						if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[yi]:attributeValue("AXTitle") == "Save" then
							whichSaveButton = yi
						end
					end
				end
				if whichSaveButton == nil then
					displayErrorMessage("Unable to locate Group Two.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- Press Save Button:
				--------------------------------------------------------------------------------
				local pressSaveButtonResult = fcpxExportWindow[whichExportWindow][whichSaveSheet][whichSaveButton]:performAction("AXPress")
				if pressSaveButtonResult == nil then
					displayErrorMessage("Unable to press Save Button.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- Make sure Save Window is closed:
				--------------------------------------------------------------------------------
				local timeoutCount = 0

				::checkSaveWindowIsClosedC::
				if fcpxExportWindow[whichExportWindow][whichSaveSheet] == nil then
					-- Continue on...
				else

					--------------------------------------------------------------------------------
					-- If an alert appears, click Cancel:
					--------------------------------------------------------------------------------
					whichAlertSheet = nil
					whichAlertButton = nil
					performCancel = false
					for yi=1, (fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValueCount("AXChildren")) do
						if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXSheet" then
							if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[yi]:attributeValue("AXDescription") == "alert" then
								for yx=1, fcpxExportWindow[whichExportWindow][whichSaveSheet][yi]:attributeValueCount("AXChildren") do
									if fcpxExportWindow[whichExportWindow][whichSaveSheet][yi][yx]:attributeValue("AXRole") == "AXButton" then
										if fcpxExportWindow[whichExportWindow][whichSaveSheet][yi][yx]:attributeValue("AXTitle") == "Cancel" then
											whichAlertSheet = yi
											whichAlertButton = yx
											performCancel = true
										end
									end
								end
							end
						end
					end
					if performCancel then
						cancelCount = cancelCount + 1

						--------------------------------------------------------------------------------
						-- Press Cancel on the Alert:
						--------------------------------------------------------------------------------
						local pressCancelButton = fcpxExportWindow[whichExportWindow][whichSaveSheet][whichAlertSheet][whichAlertButton]:performAction("AXPress")
						if pressCancelButton == nil then
							displayErrorMessage("Unable to press Cancel on the Alert.")
							return "Failed"
						end

						--------------------------------------------------------------------------------
						-- Press Cancel on the Save Dialog:
						--------------------------------------------------------------------------------
						whichCancelButton = nil
						for yi=1, (fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValueCount("AXChildren")) do
							if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXButton" then
								if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[yi]:attributeValue("AXTitle") == "Cancel" then
									whichCancelButton = yi
								end
							end
						end
						if whichCancelButton == nil then
							displayErrorMessage("Unable to locate the cancel button.")
							return "Failed"
						end
						local pressCancelButton = fcpxExportWindow[whichExportWindow][whichSaveSheet][whichCancelButton]:performAction("AXPress")
						if pressCancelButton == nil then
							displayErrorMessage("Unable to press the cancel button on the save dialog.")
							return "Failed"
						end

						--------------------------------------------------------------------------------
						-- Press Cancel on the Export Window:
						--------------------------------------------------------------------------------
						whichCancelExportButton = nil
						for yi=1, (fcpxExportWindow[whichExportWindow]:attributeValueCount("AXChildren")) do
							if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXButton" then
								if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[yi]:attributeValue("AXTitle") == "Cancel" then
									whichCancelExportButton = yi
								end
							end
						end
						if whichCancelExportButton == nil then
							displayErrorMessage("Unable to locate Group Two.")
							return "Failed"
						end
						local pressCancelButton = fcpxExportWindow[whichExportWindow][whichCancelExportButton]:performAction("AXPress")
						if pressCancelButton == nil then
							displayErrorMessage("Unable to press the Cancel button on the Export Window.")
							return "Failed"
						end

						goto nextClipInFilmstripQueueC

					end
					timeoutCount = timeoutCount + 1
					if timeoutCount == 20 then
						displayErrorMessage("It took too long for the Save Window to close so I gave up.")
						return "Failed"
					else
						sleep(0.5)
						goto checkSaveWindowIsClosedC
					end
				end
				::nextClipInFilmstripQueueC::
			end
		end
		--------------------------------------------------------------------------------
		-- List Mode:
		--------------------------------------------------------------------------------
		if fcpxBrowserMode == "List" then
			for i=1, #whichRows do

				--------------------------------------------------------------------------------
				-- Select clip:
				--------------------------------------------------------------------------------
				fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichScrollArea][whichOutline][whichRows[i]]:setAttributeValue("AXSelected", true)

				--------------------------------------------------------------------------------
				-- Trigger CMD+E (Export Using Default Share)
				--------------------------------------------------------------------------------
				if not keyStrokeFromPlist("ShareDefaultDestination") then
					displayErrorMessage("Failed to trigger the 'Export using Default Share Destination' Shortcut.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- Wait for window to open:
				--------------------------------------------------------------------------------
				fcpxExportWindow = ax.applicationElement(fcpx)

				local timeoutCount = 0
				local exportWindowOpen = false

				::waitForExportWindow::
				whichExportWindow = nil
				for yi=1, (fcpxExportWindow:attributeValueCount("AXChildren")) do
					if fcpxExportWindow:attributeValue("AXChildren")[yi]:attributeValue("AXRole") == "AXWindow" then
						for yx=1, fcpxExportWindow:attributeValue("AXChildren")[yi]:attributeValueCount("AXChildren") do
							if fcpxExportWindow[yi][yx]:attributeValue("AXRole") == "AXImage" then
								if fcpxExportWindow[yi][yx]:attributeValue("AXDescription") == "Share WindowBackground" then
									exportWindowOpen = true
									whichExportWindow = yi
								end
							end
						end
					end
				end

				if exportWindowOpen == false then
					timeoutCount = timeoutCount + 1
					if timeoutCount == 10 then
						displayErrorMessage("It took too long for Export Window to open so I gave up.")
						return "Failed"
					else
						sleep(0.5)
						goto waitForExportWindow
					end
				end

				--------------------------------------------------------------------------------
				-- Find Next Button:
				--------------------------------------------------------------------------------
				whichNextButton = nil
				for i=1, (fcpxExportWindow[whichExportWindow]:attributeValueCount("AXChildren")) do
					if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXButton" then
						if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[i]:attributeValue("AXTitle") == "Next…" then
							whichNextButton = i
						end
					end
				end
				if whichNextButton == nil then
					displayErrorMessage("Unable to locate Group Two.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- Then press it:
				--------------------------------------------------------------------------------
				fcpxExportWindow[whichExportWindow][whichNextButton]:performAction("AXPress")

				--------------------------------------------------------------------------------
				-- Wait for Save Window to Open:
				--------------------------------------------------------------------------------
				local timeoutCount = 0
				local saveWindowOpen = false

				whichSaveSheet = nil

				::waitForSaveWindow::
				for i=1, (fcpxExportWindow[whichExportWindow]:attributeValueCount("AXChildren")) do
					if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSheet" then
						if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "save" then
							whichSaveSheet = i
							saveWindowOpen = true
						end
					end
				end
				if whichSaveSheet == nil then
					displayErrorMessage("Unable to locate Save Window.")
					return "Failed"
				end

				if saveWindowOpen == false then
					timeoutCount = timeoutCount + 1
					if timeoutCount == 10 then
						displayErrorMessage("It took too long for Save Window to open so I gave up.")
						return "Failed"
					else
						sleep(0.5)
						goto waitForSaveWindow
					end
				end

				--------------------------------------------------------------------------------
				-- Find Save Button:
				--------------------------------------------------------------------------------
				whichSaveButton = nil
				for i=1, (fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValueCount("AXChildren")) do
					if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXButton" then
						if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[i]:attributeValue("AXTitle") == "Save" then
							whichSaveButton = i
						end
					end
				end
				if whichSaveButton == nil then
					displayErrorMessage("Unable to locate Group Two.")
					return "Failed"
				end

				--------------------------------------------------------------------------------
				-- Press Save Button:
				--------------------------------------------------------------------------------
				fcpxExportWindow[whichExportWindow][whichSaveSheet][whichSaveButton]:performAction("AXPress")

				--------------------------------------------------------------------------------
				-- Make sure Save Window is closed:
				--------------------------------------------------------------------------------
				local timeoutCount = 0

				::checkSaveWindowIsClosed::
				if fcpxExportWindow[whichExportWindow][whichSaveSheet] == nil then
					-- Continue on...
				else

					--------------------------------------------------------------------------------
					-- If an alert appears, click Cancel:
					--------------------------------------------------------------------------------
					whichAlertSheet = nil
					whichAlertButton = nil
					performCancel = false
					for i=1, (fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValueCount("AXChildren")) do
						if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSheet" then
							if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "alert" then
								for x=1, fcpxExportWindow[whichExportWindow][whichSaveSheet][i]:attributeValueCount("AXChildren") do
									if fcpxExportWindow[whichExportWindow][whichSaveSheet][i][x]:attributeValue("AXRole") == "AXButton" then
										if fcpxExportWindow[whichExportWindow][whichSaveSheet][i][x]:attributeValue("AXTitle") == "Cancel" then
											whichAlertSheet = i
											whichAlertButton = x
											performCancel = true
										end
									end
								end
							end
						end
					end
					if performCancel then
						cancelCount = cancelCount + 1

						--------------------------------------------------------------------------------
						-- Press Cancel on the Alert:
						--------------------------------------------------------------------------------
						fcpxExportWindow[whichExportWindow][whichSaveSheet][whichAlertSheet][whichAlertButton]:performAction("AXPress")

						--------------------------------------------------------------------------------
						-- Press Cancel on the Save Dialog:
						--------------------------------------------------------------------------------
						whichCancelButton = nil
						for i=1, (fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValueCount("AXChildren")) do
							if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXButton" then
								if fcpxExportWindow[whichExportWindow][whichSaveSheet]:attributeValue("AXChildren")[i]:attributeValue("AXTitle") == "Cancel" then
									whichCancelButton = i
								end
							end
						end
						if whichCancelButton == nil then
							displayErrorMessage("Unable to locate the cancel button.")
							return "Failed"
						end
						fcpxExportWindow[whichExportWindow][whichSaveSheet][whichCancelButton]:performAction("AXPress")

						--------------------------------------------------------------------------------
						-- Press Cancel on the Export Window:
						--------------------------------------------------------------------------------
						whichCancelExportButton = nil
						for i=1, (fcpxExportWindow[whichExportWindow]:attributeValueCount("AXChildren")) do
							if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXButton" then
								if fcpxExportWindow[whichExportWindow]:attributeValue("AXChildren")[i]:attributeValue("AXTitle") == "Cancel" then
									whichCancelExportButton = i
								end
							end
						end
						if whichCancelExportButton == nil then
							displayErrorMessage("Unable to locate Group Two.")
							return "Failed"
						end
						fcpxExportWindow[whichExportWindow][whichCancelExportButton]:performAction("AXPress")

						goto nextClipInListQueue

					end
					timeoutCount = timeoutCount + 1
					if timeoutCount == 20 then
						displayErrorMessage("It took too long for the Save Window to close so I gave up.")
						return "Failed"
					else
						sleep(0.5)
						goto checkSaveWindowIsClosed
					end
				end
				::nextClipInListQueue::
			end -- i loop
		end -- List Mode
	end -- Left Panel or Right Panel

	--------------------------------------------------------------------------------
	-- Batch Export Complete:
	--------------------------------------------------------------------------------
	local appleScriptA = 'set cancelCount to "' .. cancelCount .. '"\n'
	local appleScriptB = [[
		activate application "Final Cut Pro"
		tell application "System Events"
			tell process "Final Cut Pro"
				if cancelCount is "0" then
					display dialog "Batch Export is now complete." buttons {"Done"} with icon fcpxIcon
				else if cancelCount is "1" then
					display dialog "Batch Export is now complete." & return & return & "One clip was skipped as a file with the same name already existed." buttons {"Done"} with icon fcpxIcon
				else
					display dialog "Batch Export is now complete." & return & return & cancelCount & " clips were skipped as files with the same names already existed." buttons {"Done"} with icon fcpxIcon
				end if
			end tell
		end tell
	]]
	local ok,dialogBoxResult = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB)

end

--------------------------------------------------------------------------------
-- PERFORM MULTICAM MATCH FRAME:
--------------------------------------------------------------------------------
function multicamMatchFrame(goBackToTimeline)

	--------------------------------------------------------------------------------
	-- Just in case:
	--------------------------------------------------------------------------------
	if goBackToTimeline == nil then goBackToTimeline = true end
	if type(goBackToTimeline) ~= "boolean" then goBackToTimeline = true end

	--------------------------------------------------------------------------------
	-- Delete any pre-existing highlights:
	--------------------------------------------------------------------------------
	deleteAllHighlights()

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	fcpx = hs.application("Final Cut Pro")

	--------------------------------------------------------------------------------
	-- Reveal In Browser:
	--------------------------------------------------------------------------------
	revealInBrowserResult = fcpx:selectMenuItem({"File", "Reveal in Browser"})
	if revealInBrowserResult == nil then
		displayErrorMessage("Unable to Reveal in Browser.")
		return
	end

	--------------------------------------------------------------------------------
	-- Get Browser Playhead Value:
	--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Our Persistent Playhead Value:
		--------------------------------------------------------------------------------
		local persistentPlayheadValue = nil

		--------------------------------------------------------------------------------
		-- Filmstrip or List Mode?
		--------------------------------------------------------------------------------
		local fcpxBrowserMode = fcpxWhichBrowserMode()
		if (fcpxBrowserMode == "Failed") then -- Error Checking:
			displayErrorMessage("Unable to determine if Filmstrip or List Mode.")
			return
		end

		--------------------------------------------------------------------------------
		-- Get all FCPX UI Elements:
		--------------------------------------------------------------------------------
		fcpxElements = ax.applicationElement(fcpx)[1]

		--------------------------------------------------------------------------------
		-- Which Split Group:
		--------------------------------------------------------------------------------
		local whichSplitGroup = nil
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if whichSplitGroup == nil then
				if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
					whichSplitGroup = i
				end
			end
		end
		if whichSplitGroup == nil then
			displayErrorMessage("Unable to locate Split Group.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- List Mode:
		--------------------------------------------------------------------------------
		if fcpxBrowserMode == "List" then

			--------------------------------------------------------------------------------
			-- Which Group contains the browser:
			--------------------------------------------------------------------------------
			local whichGroup = nil
			for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
				if whichGroupGroup == nil then
					if fcpxElements[whichSplitGroup][i]:attributeValue("AXRole") == "AXGroup" then
						--------------------------------------------------------------------------------
						-- We now have ALL of the groups, and need to work out which group we actually want:
						--------------------------------------------------------------------------------
						for x=1, fcpxElements[whichSplitGroup][i]:attributeValueCount("AXChildren") do
							if fcpxElements[whichSplitGroup][i][x]:attributeValue("AXRole") == "AXSplitGroup" then
								--------------------------------------------------------------------------------
								-- Which Split Group is it:
								--------------------------------------------------------------------------------
								for y=1, fcpxElements[whichSplitGroup][i][x]:attributeValueCount("AXChildren") do
									if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXRole") == "AXSplitGroup" then
										if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXIdentifier") == "_NS:231" then
											whichGroup = i
											goto listGroupDone
										end
									end
								end
							end
						end
					end
				end
			end
			::listGroupDone::
			if whichGroup == nil then
				displayErrorMessage("Unable to locate Group.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Which Split Group Two:
			--------------------------------------------------------------------------------
			local whichSplitGroupTwo = nil
			for i=1, (fcpxElements[whichSplitGroup][whichGroup]:attributeValueCount("AXChildren")) do
				if whichSplitGroupTwo == nil then
					if fcpxElements[whichSplitGroup][whichGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
						whichSplitGroupTwo = i
						goto listSplitGroupTwo
					end
				end
			end
			::listSplitGroupTwo::
			if whichSplitGroupTwo == nil then
				displayErrorMessage("Unable to locate Split Group Two.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Which Split Group Three:
			--------------------------------------------------------------------------------
			local whichSplitGroupThree = nil
			for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValueCount("AXChildren")) do
				if whichSplitGroupThree == nil then
					if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
						whichSplitGroupThree = i
						goto listSplitGroupThree
					end
				end
			end
			::listSplitGroupThree::
			if whichSplitGroupThree == nil then
				displayErrorMessage("Unable to locate Split Group Three.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Which Group Two:
			--------------------------------------------------------------------------------
			local whichGroupTwo = nil
			for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree]:attributeValueCount("AXChildren")) do
				if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
					whichGroupTwo = i
				end
			end
			if whichGroupTwo == nil then
				displayErrorMessage("Unable to locate Group Two.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Which is Persistent Playhead?
			--------------------------------------------------------------------------------
			local whichPersistentPlayhead = (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichGroupTwo]:attributeValueCount("AXChildren")) - 1

			--------------------------------------------------------------------------------
			-- Get it's value:
			--------------------------------------------------------------------------------
			persistentPlayheadValue = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichGroupTwo][whichPersistentPlayhead]:attributeValue("AXValue")

		--------------------------------------------------------------------------------
		-- Filmstrip Mode:
		--------------------------------------------------------------------------------
		elseif fcpxBrowserMode == "Filmstrip" then

			--------------------------------------------------------------------------------
			-- Which Group contains the browser:
			--------------------------------------------------------------------------------
			local whichGroup = nil
			for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
				if whichGroupGroup == nil then
					if fcpxElements[whichSplitGroup][i]:attributeValue("AXRole") == "AXGroup" then
						--------------------------------------------------------------------------------
						-- We now have ALL of the groups, and need to work out which group we actually want:
						--------------------------------------------------------------------------------
						for x=1, fcpxElements[whichSplitGroup][i]:attributeValueCount("AXChildren") do
							if fcpxElements[whichSplitGroup][i][x]:attributeValue("AXRole") == "AXSplitGroup" then
								--------------------------------------------------------------------------------
								-- Which Split Group is it:
								--------------------------------------------------------------------------------
								for y=1, fcpxElements[whichSplitGroup][i][x]:attributeValueCount("AXChildren") do
									if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXRole") == "AXScrollArea" then
										if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXIdentifier") == "_NS:40" then
											whichGroup = i
											goto filmstripGroupDone
										end
									end
								end
							end
						end
					end
				end
			end
			::filmstripGroupDone::
			if whichGroup == nil then
				displayErrorMessage("Unable to locate Group.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Which Split Group Two:
			--------------------------------------------------------------------------------
			local whichSplitGroupTwo = nil
			for i=1, (fcpxElements[whichSplitGroup][whichGroup]:attributeValueCount("AXChildren")) do
				if whichSplitGroupTwo == nil then
					if fcpxElements[whichSplitGroup][whichGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
						whichSplitGroupTwo = i
						goto filmstripSplitGroupTwoDone
					end
				end
			end
			::filmstripSplitGroupTwoDone::
			if whichSplitGroupTwo == nil then
				displayErrorMessage("Unable to locate Split Group Two.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Which Scroll Area:
			--------------------------------------------------------------------------------
			local whichScrollArea = nil
			for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValueCount("AXChildren")) do
				if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXScrollArea" then
					whichScrollArea = i
				end
			end
			if whichScrollArea == nil then
				displayErrorMessage("Unable to locate Scroll Area.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Which Group Two:
			--------------------------------------------------------------------------------
			local whichGroupTwo = nil
			for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea]:attributeValueCount("AXChildren")) do
				if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
					whichGroupTwo = i
				end
			end
			if whichGroupTwo == nil then
				displayErrorMessage("Unable to locate Group Two.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Which is Persistent Playhead?
			--------------------------------------------------------------------------------
			local whichPersistentPlayhead = (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo]:attributeValueCount("AXChildren")) - 1

			--------------------------------------------------------------------------------
			-- Let's get it's value:
			--------------------------------------------------------------------------------
			persistentPlayheadValue = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo][whichPersistentPlayhead]:attributeValue("AXValue")
		end

	--------------------------------------------------------------------------------
	-- Is the Persistent Playhead Value valid:
	--------------------------------------------------------------------------------
	if persistentPlayheadValue == nil then
		displayErrorMessage("Failed to get Persistent Playhead Value.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Put focus back on the timeline:
	--------------------------------------------------------------------------------
	goToTimelineResult = fcpx:selectMenuItem({"Window", "Go To", "Timeline"})
	if goToTimelineResult == nil then
		displayErrorMessage("Unable to return to timeline.")
		return
	end

	--------------------------------------------------------------------------------
	-- Open in Angle Editor:
	--------------------------------------------------------------------------------
	openInAngleEditorResult = fcpx:selectMenuItem({"Clip", "Open in Angle Editor"})
	if openInAngleEditorResult == nil then
		displayErrorMessage("Failed to open clip in Angle Editor.\n\nAre you sure the clip you have selected is a Multicam?")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Zoom to Fit:
	--------------------------------------------------------------------------------
	if goBackToTimeline == false then
		zoomToFitResult = fcpx:selectMenuItem({"View", "Zoom to Fit"})
		if zoomToFitResult == nil then
			displayErrorMessage("Failed to Zoom to Fit.")
			return "Failed"
		end
	end

	--------------------------------------------------------------------------------
	-- Which Timecode Text:
	--------------------------------------------------------------------------------
	local timecodeValue = 25 -- Assume 25fps by default.
	local whichTimecodeText = nil
	for i=1, (fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren")) do
		if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXStaticText" then
			whichTimecodeText = i
		end
	end
	if whichTimecodeText ~= nil then
		if fcpxElements[whichSplitGroup][whichTimecodeText]:attributeValue("AXValue") ~= nil then
			local timecodeText = fcpxElements[whichSplitGroup][whichTimecodeText]:attributeValue("AXValue")
			if string.match(timecodeText, " 23.98p ") then timecodeValue = 23.98 end
			if string.match(timecodeText, " 24p ") then timecodeValue = 24 end
			if string.match(timecodeText, " 29.97i ") then timecodeValue = 29.97 end
			if string.match(timecodeText, " 29.97p ") then timecodeValue = 29.97 end
			if string.match(timecodeText, " 30p ") then timecodeValue = 30 end
			if string.match(timecodeText, " 50p ") then timecodeValue = 50 end
			if string.match(timecodeText, " 59.94p ") then timecodeValue = 59.94 end
			if string.match(timecodeText, " 60p ") then timecodeValue = 60 end
		end
	end

	--------------------------------------------------------------------------------
	-- Convert Seconds to Timecode:
	--------------------------------------------------------------------------------
	local matchFrameTimecode = secondsToTimecode(persistentPlayheadValue, timecodeValue)

	--------------------------------------------------------------------------------
	-- Go to that position in timeline:
	--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Which Timecode Group:
		--------------------------------------------------------------------------------
		local whichTimecodeGroup = nil
		for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
			if whichTimecodeGroup == nil then
				if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
					if (fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1]) ~= nil then
						for x=1, fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i]:attributeValueCount("AXChildren") do
							if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][x] ~= nil then
								if (fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][x]:attributeValue("AXDescription")) == "Timecode LCD" then
									whichTimecodeGroup = i
								end
							end
						end
					end
				end
			end
		end
		if whichTimecodeGroup == nil then
			displayErrorMessage("Unable to locate Timecode Group.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Activate 'Move Playhead Position':
		--------------------------------------------------------------------------------
		local timeoutCount = 0
		::tryTimecodeEnterModeAgain::
		if not keyStrokeFromPlist("ShowTimecodeEntryPlayhead") then
			displayErrorMessage("Failed to trigger the 'Move Playhead Position' Command.")
			return "Failed"
		end
		for i=1, fcpxElements[whichSplitGroup][whichTimecodeGroup]:attributeValueCount("AXChildren") do
			if fcpxElements[whichSplitGroup][whichTimecodeGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXButton" then
				if fcpxElements[whichSplitGroup][whichTimecodeGroup]:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "Numeric Entry Type" then
					goto typeTimecode
				end
			end
		end
		timeoutCount = timeoutCount + 1
		if timeoutCount == 100 then
			displayErrorMessage("We were unable to enter the source timecode for some reason.\n\nPlease make sure you haven't changed the default shortcut key for 'Move Playhead Position'.")
			return "Failed"
		end
		sleep(0.01)
		goto tryTimecodeEnterModeAgain
		::typeTimecode::

		--------------------------------------------------------------------------------
		-- Type in Original Timecode & Press Return Key:
		--------------------------------------------------------------------------------
		hs.eventtap.keyStrokes(matchFrameTimecode)
		hs.eventtap.keyStroke({}, 'return')

	--------------------------------------------------------------------------------
	-- Reveal In Browser:
	--------------------------------------------------------------------------------
	revealInBrowserResult = fcpx:selectMenuItem({"File", "Reveal in Browser"})
	if revealInBrowserResult == nil then
		displayErrorMessage("Unable to Reveal in Browser.")
		return
	end

	--------------------------------------------------------------------------------
	-- Go back to original timeline if appropriate:
	--------------------------------------------------------------------------------
	if goBackToTimeline then
		timelineHistoryBackResult = fcpx:selectMenuItem({"View", "Timeline History Back"})
		if timelineHistoryBackResult == nil then
			displayErrorMessage("Unable to go back to previous timeline.")
			return
		end
	end

	--------------------------------------------------------------------------------
	-- Highlight Browser Playhead:
	--------------------------------------------------------------------------------
	highlightFCPXBrowserPlayhead()

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
	-- Define FCPX:
	--------------------------------------------------------------------------------
	fcpx = hs.appfinder.appFromName("Final Cut Pro")

	--------------------------------------------------------------------------------
	-- Click on 'Reveal in Browser':
	--------------------------------------------------------------------------------
	local resultRevealInBrowser = nil
	resultRevealInBrowser = fcpx:selectMenuItem({"File", "Reveal in Browser"})
	if resultRevealInBrowser == nil then
		--------------------------------------------------------------------------------
		-- Error:
		--------------------------------------------------------------------------------
		displayErrorMessage("Unable to trigger Reveal in Browser.")
		return
	end

	--------------------------------------------------------------------------------
	-- Filmstrip or List Mode?
	--------------------------------------------------------------------------------
	local fcpxBrowserMode = fcpxWhichBrowserMode()

	-- Error Checking:
	if (fcpxBrowserMode == "Failed") then
		displayErrorMessage("Unable to determine if Filmstrip or List Mode.")
		return
	end

	--------------------------------------------------------------------------------
	-- Get all FCPX UI Elements:
	--------------------------------------------------------------------------------
	fcpx = hs.application("Final Cut Pro")
	fcpxElements = ax.applicationElement(fcpx)[1]

	--------------------------------------------------------------------------------
	-- Which Split Group:
	--------------------------------------------------------------------------------
	local whichSplitGroup = nil
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
		if whichSplitGroup == nil then
			if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
				whichSplitGroup = i
			end
		end
	end
	if whichSplitGroup == nil then
		displayErrorMessage("Unable to locate Split Group.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- List Mode:
	--------------------------------------------------------------------------------
	if fcpxBrowserMode == "List" then

		--------------------------------------------------------------------------------
		-- Which Group contains the browser:
		--------------------------------------------------------------------------------
		local whichGroup = nil
		for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
			if whichGroupGroup == nil then
				if fcpxElements[whichSplitGroup][i]:attributeValue("AXRole") == "AXGroup" then
					--------------------------------------------------------------------------------
					-- We now have ALL of the groups, and need to work out which group we actually want:
					--------------------------------------------------------------------------------
					for x=1, fcpxElements[whichSplitGroup][i]:attributeValueCount("AXChildren") do
						if fcpxElements[whichSplitGroup][i][x]:attributeValue("AXRole") == "AXSplitGroup" then
							--------------------------------------------------------------------------------
							-- Which Split Group is it:
							--------------------------------------------------------------------------------
							for y=1, fcpxElements[whichSplitGroup][i][x]:attributeValueCount("AXChildren") do
								if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXRole") == "AXSplitGroup" then
									if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXIdentifier") == "_NS:231" then
										whichGroup = i
										goto listGroupDone
									end
								end
							end
						end
					end
				end
			end
		end
		::listGroupDone::
		if whichGroup == nil then
			displayErrorMessage("Unable to locate Group.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Split Group Two:
		--------------------------------------------------------------------------------
		local whichSplitGroupTwo = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup]:attributeValueCount("AXChildren")) do
			if whichSplitGroupTwo == nil then
				if fcpxElements[whichSplitGroup][whichGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
					whichSplitGroupTwo = i
					goto listSplitGroupTwo
				end
			end
		end
		::listSplitGroupTwo::
		if whichSplitGroupTwo == nil then
			displayErrorMessage("Unable to locate Split Group Two.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Split Group Three:
		--------------------------------------------------------------------------------
		local whichSplitGroupThree = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValueCount("AXChildren")) do
			if whichSplitGroupThree == nil then
				if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
					whichSplitGroupThree = i
					goto listSplitGroupThree
				end
			end
		end
		::listSplitGroupThree::
		if whichSplitGroupThree == nil then
			displayErrorMessage("Unable to locate Split Group Three.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Group Two:
		--------------------------------------------------------------------------------
		local whichGroupTwo = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
				whichGroupTwo = i
			end
		end
		if whichGroupTwo == nil then
			displayErrorMessage("Unable to locate Group Two.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which is Persistent Playhead?
		--------------------------------------------------------------------------------
		local whichPersistentPlayhead = (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichGroupTwo]:attributeValueCount("AXChildren")) - 1

		--------------------------------------------------------------------------------
		-- Get Description Based off Playhead:
		--------------------------------------------------------------------------------
		persistentPlayheadPosition = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichSplitGroupThree][whichGroupTwo][whichPersistentPlayhead]:attributeValue("AXPosition")

		persistentPlayheadPosition['x'] = persistentPlayheadPosition['x'] + 20
		persistentPlayheadPosition['y'] = persistentPlayheadPosition['y'] + 20

		currentElement = ax.systemWideElement():elementAtPosition(persistentPlayheadPosition)

		if currentElement:attributeValue("AXRole") == "AXHandle" then
			currentElement = currentElement:attributeValue("AXParent")
		end

		oneElementBack = currentElement:attributeValue("AXParent")

		local searchTerm = oneElementBack:attributeValue("AXDescription")

		local whichSearchGroup = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup]:attributeValueCount("AXChildren")) do
			if whichSearchGroup == nil then
				if fcpxElements[whichSplitGroup][whichGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
					whichSearchGroup = i
					goto searchGroupDone
				end
			end
		end
		::searchGroupDone::
		if whichSearchGroup == nil then
			displayErrorMessage("Unable to locate Search Group.")
			return "Failed"
		end

		local searchTextFieldPosition = fcpxElements[whichSplitGroup][whichGroup][whichSearchGroup]:attributeValueCount("AXChildren")
		local searchTextField = fcpxElements[whichSplitGroup][whichGroup][whichSearchGroup][searchTextFieldPosition]

		--------------------------------------------------------------------------------
		-- Set the search field to Title of the Selected Clip:
		--------------------------------------------------------------------------------
		local searchTextFieldResult = searchTextField:setAttributeValue("AXValue", searchTerm)
		if searchTextFieldResult == nil then
			displayErrorMessage("Unable to set Search Field.")
		end

		--------------------------------------------------------------------------------
		-- Trigger the search:
		--------------------------------------------------------------------------------
		local searchTextFieldActionResult = searchTextField:performAction("AXConfirm")
		if searchTextFieldActionResult == nil then
			displayErrorMessage("Unable to trigger Search.")
		end

		--------------------------------------------------------------------------------
		-- Highlight Browser Playhead:
		--------------------------------------------------------------------------------
		highlightFCPXBrowserPlayhead()

	--------------------------------------------------------------------------------
	-- Filmstrip Mode:
	--------------------------------------------------------------------------------
	elseif fcpxBrowserMode == "Filmstrip" then

		--------------------------------------------------------------------------------
		-- Which Group contains the browser:
		--------------------------------------------------------------------------------
		local whichGroup = nil
		for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
			if whichGroupGroup == nil then
				if fcpxElements[whichSplitGroup][i]:attributeValue("AXRole") == "AXGroup" then
					--------------------------------------------------------------------------------
					-- We now have ALL of the groups, and need to work out which group we actually want:
					--------------------------------------------------------------------------------
					for x=1, fcpxElements[whichSplitGroup][i]:attributeValueCount("AXChildren") do
						if fcpxElements[whichSplitGroup][i][x]:attributeValue("AXRole") == "AXSplitGroup" then
							--------------------------------------------------------------------------------
							-- Which Split Group is it:
							--------------------------------------------------------------------------------
							for y=1, fcpxElements[whichSplitGroup][i][x]:attributeValueCount("AXChildren") do
								if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXRole") == "AXScrollArea" then
									if fcpxElements[whichSplitGroup][i][x][y]:attributeValue("AXIdentifier") == "_NS:40" then
										whichGroup = i
										goto filmstripGroupDone
									end
								end
							end
						end
					end
				end
			end
		end
		::filmstripGroupDone::
		if whichGroup == nil then
			displayErrorMessage("Unable to locate Group.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Split Group Two:
		--------------------------------------------------------------------------------
		local whichSplitGroupTwo = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup]:attributeValueCount("AXChildren")) do
			if whichSplitGroupTwo == nil then
				if fcpxElements[whichSplitGroup][whichGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
					whichSplitGroupTwo = i
					goto filmstripSplitGroupTwoDone
				end
			end
		end
		::filmstripSplitGroupTwoDone::
		if whichSplitGroupTwo == nil then
			displayErrorMessage("Unable to locate Split Group Two.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Scroll Area:
		--------------------------------------------------------------------------------
		local whichScrollArea = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXScrollArea" then
				whichScrollArea = i
			end
		end
		if whichScrollArea == nil then
			displayErrorMessage("Unable to locate Scroll Area.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which Group Two:
		--------------------------------------------------------------------------------
		local whichGroupTwo = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea]:attributeValueCount("AXChildren")) do
			if fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
				whichGroupTwo = i
			end
		end
		if whichGroupTwo == nil then
			displayErrorMessage("Unable to locate Group Two.")
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Which is Persistent Playhead:
		--------------------------------------------------------------------------------
		local whichPersistentPlayhead = (fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo]:attributeValueCount("AXChildren")) - 1

		--------------------------------------------------------------------------------
		-- Get Description Based off Playhead:
		--------------------------------------------------------------------------------
		persistentPlayheadPosition = fcpxElements[whichSplitGroup][whichGroup][whichSplitGroupTwo][whichScrollArea][whichGroupTwo][whichPersistentPlayhead]:attributeValue("AXPosition")

		persistentPlayheadPosition['x'] = persistentPlayheadPosition['x'] + 20
		persistentPlayheadPosition['y'] = persistentPlayheadPosition['y'] + 20

		currentElement = ax.systemWideElement():elementAtPosition(persistentPlayheadPosition)

		if currentElement:attributeValue("AXRole") == "AXHandle" then
			currentElement = currentElement:attributeValue("AXParent")
		end

		oneElementBack = currentElement:attributeValue("AXParent")

		local searchTerm = oneElementBack:attributeValue("AXDescription")

		local whichSearchGroup = nil
		for i=1, (fcpxElements[whichSplitGroup][whichGroup]:attributeValueCount("AXChildren")) do
			if whichSearchGroup == nil then
				if fcpxElements[whichSplitGroup][whichGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXGroup" then
					whichSearchGroup = i
					goto searchGroupDone
				end
			end
		end
		::searchGroupDone::
		if whichSearchGroup == nil then
			displayErrorMessage("Unable to locate Search Group.")
			return "Failed"
		end

		local searchTextFieldPosition = fcpxElements[whichSplitGroup][whichGroup][whichSearchGroup]:attributeValueCount("AXChildren")
		local searchTextField = fcpxElements[whichSplitGroup][whichGroup][whichSearchGroup][searchTextFieldPosition]

		--------------------------------------------------------------------------------
		-- Set the search field to Title of the Selected Clip:
		--------------------------------------------------------------------------------
		local searchTextFieldResult = searchTextField:setAttributeValue("AXValue", searchTerm)
		if searchTextFieldResult == nil then
			displayErrorMessage("Unable to set Search Field.")
		end

		--------------------------------------------------------------------------------
		-- Trigger the search:
		--------------------------------------------------------------------------------
		local searchTextFieldActionResult = searchTextField:performAction("AXConfirm")
		if searchTextFieldActionResult == nil then
			displayErrorMessage("Unable to trigger Search.")
		end

		--------------------------------------------------------------------------------
		-- Highlight Browser Playhead:
		--------------------------------------------------------------------------------
		highlightFCPXBrowserPlayhead()

	end
end

--------------------------------------------------------------------------------
-- FCPX SAVE KEYWORDS:
--------------------------------------------------------------------------------
function fcpxSaveKeywordSearches(whichButton)

	--------------------------------------------------------------------------------
	-- Delete any pre-existing highlights:
	--------------------------------------------------------------------------------
	deleteAllHighlights()

	--------------------------------------------------------------------------------
	-- Open FCPX Keyword Editor:
	--------------------------------------------------------------------------------
	fcpxOpenKeywordEditorResult = fcpxOpenKeywordEditor()
	if fcpxOpenKeywordEditorResult == "Failed" then
		displayErrorMessage("Unable to open Keyword Editor.")
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Get all FCPX UI Elements:
	--------------------------------------------------------------------------------
	fcpx = hs.application("Final Cut Pro")
	fcpxElements = ax.applicationElement(fcpx)[1]

	--------------------------------------------------------------------------------
	-- Get Starting Textfield:
	--------------------------------------------------------------------------------
	local startTextField = nil
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
		if startTextField == nil then
			if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "favorite 1" then
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
			if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "Keyword Shortcuts" then
				keywordDisclosureTriangle = i
				goto keywordDisclosureTriangleDone
			end
		end
		::keywordDisclosureTriangleDone::
		if fcpxElements[keywordDisclosureTriangle] == nil then
			displayMessage("Please make sure that the Keyboard Shortcuts are visible before using this feature.")
			return "Failed"
		else
			local keywordDisclosureTriangleResult = fcpxElements[keywordDisclosureTriangle]:performAction("AXPress")
			if keywordDisclosureTriangleResult == nil then
				displayMessage("Please make sure that the Keyboard Shortcuts are visible before using this feature.")
				return "Failed"
			end
		end
	end

	--------------------------------------------------------------------------------
	-- Get Values from the Keyword Editor:
	--------------------------------------------------------------------------------
	local savedKeywordValues = {}
	local favoriteCount = 1
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
		if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "favorite " .. favoriteCount then
			savedKeywordValues[favoriteCount] = fcpxElements[i]:attributeValue("AXHelp")
			favoriteCount = favoriteCount + 1
		end
	end

	--------------------------------------------------------------------------------
	-- Save Values to Settings:
	--------------------------------------------------------------------------------
	local savedKeywords = hs.settings.get("fcpxHacks.savedKeywords")
	if savedKeywords == nil then savedKeywords = {} end
	for i=1, 9 do
		if savedKeywords['Preset ' .. tostring(whichButton)] == nil then
			savedKeywords['Preset ' .. tostring(whichButton)] = {}
		end
		savedKeywords['Preset ' .. tostring(whichButton)]['Item ' .. tostring(i)] = savedKeywordValues[i]
	end
	hs.settings.set("fcpxHacks.savedKeywords", savedKeywords)

	--------------------------------------------------------------------------------
	-- Saved:
	--------------------------------------------------------------------------------
	hs.alert.show("Your Keywords have been saved to Preset " .. tostring(whichButton) .. ".")

end

--------------------------------------------------------------------------------
-- FCPX RESTORE KEYWORDS:
--------------------------------------------------------------------------------
function fcpxRestoreKeywordSearches(whichButton)

	--------------------------------------------------------------------------------
	-- Delete any pre-existing highlights:
	--------------------------------------------------------------------------------
	deleteAllHighlights()

	--------------------------------------------------------------------------------
	-- Get Values from FCPX's plist:
	--------------------------------------------------------------------------------
	local savedKeywords = hs.settings.get("fcpxHacks.savedKeywords")
	local restoredKeywordValues = {}

	if savedKeywords == nil then
		displayMessage("It doesn't look like you've saved any keyword presets yet?")
		return "Fail"
	end
	if savedKeywords['Preset ' .. tostring(whichButton)] == nil then
		displayMessage("It doesn't look like you've saved anything to this keyword preset yet?")
		return "Fail"
	end
	for i=1, 9 do
		restoredKeywordValues[i] = savedKeywords['Preset ' .. tostring(whichButton)]['Item ' .. tostring(i)]
	end

	--------------------------------------------------------------------------------
	-- Open FCPX Keyword Editor:
	--------------------------------------------------------------------------------
	fcpxOpenKeywordEditorResult = fcpxOpenKeywordEditor()
	if fcpxOpenKeywordEditorResult == "Failed" then
		displayErrorMessage("Unable to open Keyword Editor.")
		return "Failed"
	else
		sleep(0.5)
	end

	--------------------------------------------------------------------------------
	-- Get all FCPX UI Elements:
	--------------------------------------------------------------------------------
	fcpx = hs.application("Final Cut Pro")
	fcpxElements = ax.applicationElement(fcpx)[1]

	--------------------------------------------------------------------------------
	-- Get Starting Textfield:
	--------------------------------------------------------------------------------
	local startTextField = nil
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
		if startTextField == nil then
			if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "favorite 1" then
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
			if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "Keyword Shortcuts" then
				keywordDisclosureTriangle = i
				goto keywordDisclosureTriangleDone
			end
		end
		::keywordDisclosureTriangleDone::

		local keywordDisclosureTriangleResult = fcpxElements[keywordDisclosureTriangle]:performAction("AXPress")
		if keywordDisclosureTriangleResult == nil then
			displayMessage("Please make sure that the Keyboard Shortcuts are visible before using this feature.")
			return "Failed"
		end
	end

	--------------------------------------------------------------------------------
	-- Restore Values to Keyword Editor:
	--------------------------------------------------------------------------------
	local favoriteCount = 1
	for i=1, fcpxElements:attributeValueCount("AXChildren") do
		if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "favorite " .. favoriteCount then
			currentKeywordSelection = fcpxElements[i]

			setKeywordResult = currentKeywordSelection:setAttributeValue("AXValue", restoredKeywordValues[favoriteCount])
			keywordActionResult = currentKeywordSelection:setAttributeValue("AXFocused", true)
			hs.eventtap.keyStroke({""}, "return")

			favoriteCount = favoriteCount + 1
		end
	end

	--------------------------------------------------------------------------------
	-- Successfully Restored:
	--------------------------------------------------------------------------------
	hs.alert.show("Your Keywords have been restored to Preset " .. tostring(whichButton) .. ".")

end

--------------------------------------------------------------------------------
-- FCPX COLOR BOARD PUCK SELECTION:
--------------------------------------------------------------------------------
function colorBoardSelectPuck(whichPuck, whichPanel, whichDirection)

	--------------------------------------------------------------------------------
	-- Local Variables:
	--------------------------------------------------------------------------------
	local whichSplitGroup = nil
	local whichGroup = nil

	--------------------------------------------------------------------------------
	-- Make sure Nudge Shortcuts are allocated:
	--------------------------------------------------------------------------------
	local nudgeShortcutMissing = false
	if whichDirection == "up" then
		if finalCutProShortcutKey["ColorBoard-NudgePuckUp"]['characterString'] == "" then
			nudgeShortcutMissing = true
		end
	end
	if whichDirection == "down" then
		if finalCutProShortcutKey["ColorBoard-NudgePuckDown"]['characterString'] == "" then
			nudgeShortcutMissing = true
		end
	end
	if whichDirection == "left" then
		if finalCutProShortcutKey["ColorBoard-NudgePuckLeft"]['characterString'] == "" then
			nudgeShortcutMissing = true
		end
	end
	if whichDirection == "right" then
		if finalCutProShortcutKey["ColorBoard-NudgePuckRight"]['characterString'] == "" then
			nudgeShortcutMissing = true
		end
	end
	if nudgeShortcutMissing then
		displayMessage("This feature requires the Color Board Nudge Pucks shortcuts to be allocated.\n\nPlease allocate these shortcuts keys to anything you like in the Command Editor and try again.")
	end

	--------------------------------------------------------------------------------
	-- The first button is actually the reset button:
	--------------------------------------------------------------------------------
	whichPuck = whichPuck + 1

	--------------------------------------------------------------------------------
	-- Delete any pre-existing highlights:
	--------------------------------------------------------------------------------
	deleteAllHighlights()

	--------------------------------------------------------------------------------
	-- Get all FCPX UI Elements:
	--------------------------------------------------------------------------------
	fcpx = hs.application("Final Cut Pro")
	fcpxElements = ax.applicationElement(fcpx)[1]

	--------------------------------------------------------------------------------
	-- Check for cached value:
	--------------------------------------------------------------------------------
	local useCache = false
	if colorBoardSelectPuckSplitGroupCache ~= nil and colorBoardSelectPuckGroupCache ~= nil then
		if fcpxElements[colorBoardSelectPuckSplitGroupCache][colorBoardSelectPuckGroupCache][1] ~= nil then
			if fcpxElements[colorBoardSelectPuckSplitGroupCache][colorBoardSelectPuckGroupCache][1]:attributeValue("AXTitle") == "Color" then
				useCache = true
				whichSplitGroup = colorBoardSelectPuckSplitGroupCache
				whichGroup = colorBoardSelectPuckGroupCache
			end
		end
	end

	--------------------------------------------------------------------------------
	-- Find these values if not already in the cache:
	--------------------------------------------------------------------------------
	if not useCache then

		--------------------------------------------------------------------------------
		-- Which Split Group:
		--------------------------------------------------------------------------------
		for i=1, fcpxElements:attributeValueCount("AXChildren") do
			if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
				whichSplitGroup = i
				goto colorBoardSelectPuckSplitGroupExit
			end
		end
		if whichSplitGroup == nil then
			displayErrorMessage("Unable to locate Split Group.")
			return "Failed"
		end
		::colorBoardSelectPuckSplitGroupExit::
		colorBoardSelectPuckSplitGroupCache = whichSplitGroup -- Used for caching.

		--------------------------------------------------------------------------------
		-- Which Group?
		--------------------------------------------------------------------------------
		for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
			if fcpxElements[whichSplitGroup][i]:attributeValueCount("AXChildren") ~= 0 then
				if fcpxElements[whichSplitGroup][i]:attributeValue("AXChildren")[1]:attributeValue("AXRole") == "AXCheckBox" then
					if fcpxElements[whichSplitGroup][i]:attributeValue("AXChildren")[1]:attributeValue("AXTitle") == "Color" then
						whichGroup = i
						goto colorBoardSelectPuckGroupExit
					end
				end
			end
		end
		if whichGroup == nil then
			--------------------------------------------------------------------------------
			-- If we can't find the group, maybe it's not open?
			--------------------------------------------------------------------------------
			local pressColorBoard = fcpx:selectMenuItem({"Window", "Go To", "Color Board"})
			if pressColorBoard == nil then
				displayErrorMessage("Unable to open Color Board.")
				return "Failed"
			end

			--------------------------------------------------------------------------------
			-- Try Which Group Again:
			--------------------------------------------------------------------------------
			whichGroup = nil
			for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
				if fcpxElements[whichSplitGroup][i]:attributeValueCount("AXChildren") ~= 0 then
					if fcpxElements[whichSplitGroup][i]:attributeValue("AXChildren")[1]:attributeValue("AXRole") == "AXCheckBox" then
						if fcpxElements[whichSplitGroup][i]:attributeValue("AXChildren")[1]:attributeValue("AXTitle") == "Color" then
							whichGroup = i
							goto colorBoardSelectPuckGroupExit
						end
					end
				end
			end
			if whichGroup == nil then
				displayMessage("This feature only works when you have a single clip selected in the timeline.\n\nPlease select a clip and try again.")
				return "Failed"
			end
		end
		::colorBoardSelectPuckGroupExit::
		colorBoardSelectPuckGroupCache = whichGroup -- Used for caching.
	end

	--------------------------------------------------------------------------------
	-- Which Panel?
	--------------------------------------------------------------------------------
	if whichPanel ~= nil then
		if fcpxElements[whichSplitGroup][whichGroup][whichPanel]:attributeValue("AXValue") == 0 then
			fcpxElements[whichSplitGroup][whichGroup][whichPanel]:performAction("AXPress")
		end
	end

	--------------------------------------------------------------------------------
	-- Which Puck?
	--------------------------------------------------------------------------------
	local whichPuckCount = 1
	for i=1, fcpxElements[whichSplitGroup][whichGroup]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup][whichGroup]:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXButton" then
			if whichPuckCount == whichPuck then
				whichPuckButton = i
				goto colorBoardSelectPuckPuckButtonExit
			else
				whichPuckCount = whichPuckCount + 1
			end
		end
	end
	if whichPuckButton == nil then
		displayErrorMessage("Unable to locate Puck.")
		return "Failed"
	end
	::colorBoardSelectPuckPuckButtonExit::

	--------------------------------------------------------------------------------
	-- Click on the Puck:
	--------------------------------------------------------------------------------
	if not fcpxElements[whichSplitGroup][whichGroup][whichPuckButton]:attributeValue("AXFocused") then
		local originalMousePoint = hs.mouse.getAbsolutePosition()
		local colorBoardPosition = {}
		colorBoardPosition['x'] = fcpxElements[whichSplitGroup][whichGroup][whichPuckButton]:attributeValue("AXPosition")['x'] + (fcpxElements[whichSplitGroup][whichGroup][whichPuckButton]:attributeValue("AXSize")['w'] / 2)
		colorBoardPosition['y'] = fcpxElements[whichSplitGroup][whichGroup][whichPuckButton]:attributeValue("AXPosition")['y'] + (fcpxElements[whichSplitGroup][whichGroup][whichPuckButton]:attributeValue("AXSize")['h'] / 2)
		hs.eventtap.leftClick(colorBoardPosition)
		hs.mouse.setAbsolutePosition(originalMousePoint)
	end

	--------------------------------------------------------------------------------
	-- Perform a direction shortcut if required:
	--------------------------------------------------------------------------------


	--------------------------------------------------------------------------------
	-- If a Direction is specified:
	--------------------------------------------------------------------------------
	if whichDirection ~= nil then

		--------------------------------------------------------------------------------
		-- Get shortcut key from plist, press and hold if required:
		--------------------------------------------------------------------------------
		releaseColorBoardDown = false
		hs.timer.doUntil(function() return releaseColorBoardDown end, function()
			if whichDirection == "up" then
				if finalCutProShortcutKey["ColorBoard-NudgePuckUp"]['characterString'] ~= "" then
					keyStrokeFromPlist("ColorBoard-NudgePuckUp")
				end
			end
			if whichDirection == "down" then
				if finalCutProShortcutKey["ColorBoard-NudgePuckDown"]['characterString'] ~= "" then
					keyStrokeFromPlist("ColorBoard-NudgePuckDown")
				end
			end
			if whichDirection == "left" then
				if finalCutProShortcutKey["ColorBoard-NudgePuckLeft"]['characterString'] ~= "" then
					keyStrokeFromPlist("ColorBoard-NudgePuckLeft")
				end
			end
			if whichDirection == "right" then
				if finalCutProShortcutKey["ColorBoard-NudgePuckRight"]['characterString'] ~= "" then
					keyStrokeFromPlist("ColorBoard-NudgePuckRight")
				end
			end
		end, hs.eventtap.keyRepeatInterval())

	end

end

--------------------------------------------------------------------------------
-- COLOR BOARD - RELEASE KEYPRESS:
--------------------------------------------------------------------------------
function colorBoardSelectPuckRelease()
	releaseColorBoardDown = true
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
	-- Define FCPX:
	--------------------------------------------------------------------------------
	fcpx = hs.appfinder.appFromName("Final Cut Pro")

	--------------------------------------------------------------------------------
	-- Click on 'Reveal in Browser':
	--------------------------------------------------------------------------------
	resultRevealInBrowser = fcpx:selectMenuItem({"File", "Reveal in Browser"})

	--------------------------------------------------------------------------------
	-- If it worked then...
	--------------------------------------------------------------------------------
	if resultRevealInBrowser then
		--------------------------------------------------------------------------------
		-- Highlight FCPX Browser Playhead:
		--------------------------------------------------------------------------------
		highlightFCPXBrowserPlayhead()
	else
		--------------------------------------------------------------------------------
		-- Error:
		--------------------------------------------------------------------------------
		displayErrorMessage("Unable to trigger Reveal in Browser.")
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                C O M M O N     F C P X    F U N C T I O N S                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- LAUNCH FINAL CUT PRO:
--------------------------------------------------------------------------------
function launchFinalCutPro()
	hs.application.launchOrFocus("Final Cut Pro")
end

--------------------------------------------------------------------------------
-- RESTART FINAL CUT PRO:
--------------------------------------------------------------------------------
function restartFinalCutPro()

	if hs.application("Final Cut Pro") ~= nil then

		--------------------------------------------------------------------------------
		-- Kill Final Cut Pro:
		--------------------------------------------------------------------------------
		hs.application("Final Cut Pro"):kill()

		--------------------------------------------------------------------------------
		-- Wait until Final Cut Pro is Closed:
		--------------------------------------------------------------------------------
		local timeoutCount = 0
		repeat
			timeoutCount = timeoutCount + 1
			if timeoutCount == 10 then
				return "Failed"
			end
			sleep(1)
		until not isFinalCutProRunning()

		--------------------------------------------------------------------------------
		-- Launch Final Cut Pro:
		--------------------------------------------------------------------------------
		launchFinalCutPro()

		return true

	else
		return false
	end

end

--------------------------------------------------------------------------------
-- GET FINAL CUT PRO PROXY STATUS ICON:
--------------------------------------------------------------------------------
function getProxyStatusIcon() -- Returns Icon or Nil

	local result = nil

	local proxyOnIcon = "🔴"
	local proxyOffIcon = "🔵"

	local FFPlayerQuality = nil
	if getFinalCutProPlistValue("FFPlayerQuality") ~= nil then
		FFPlayerQuality = getFinalCutProPlistValue("FFPlayerQuality")
	end

	if FFPlayerQuality == "4" then
		result = proxyOnIcon 		-- Proxy (4)
	else
		result = proxyOffIcon 		-- Original (5)
	end

	return result

end

--------------------------------------------------------------------------------
-- GET FINAL CUT PRO'S ACTIVE COMMAND SET FROM PLIST:
--------------------------------------------------------------------------------
function getFinalCutProActiveCommandSet()

	local activeCommandSetResult = getFinalCutProPlistValue("Active Command Set")

	if activeCommandSetResult == nil then
		return nil
	else
		if hs.fs.attributes(activeCommandSetResult) == nil then
			return nil
		else
			return activeCommandSetResult
		end
	end

end

--------------------------------------------------------------------------------
-- GET FINAL CUT PRO PLIST VALUE:
--------------------------------------------------------------------------------
function getFinalCutProPlistValue(value) -- Returns Result or Nil

	local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist '" .. tostring(value) .. "'")

	if executeStatus == nil then
		return nil
	else
		return trim(executeResult)
	end

end

--------------------------------------------------------------------------------
-- READ SHORTCUT KEYS FROM FINAL CUT PRO PLIST:
--------------------------------------------------------------------------------
function readShortcutKeysFromPlist()
	--------------------------------------------------------------------------------
	-- Get plist values for 'Active Command Set':
	--------------------------------------------------------------------------------
	local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist 'Active Command Set'")
	if executeStatus == nil then
		displayErrorMessage("Could not retreieve the Active Command Set from Final Cut Pro's plist.")
		return "Failed"
	else
		if hs.fs.attributes(trim(executeResult)) == nil then
			displayErrorMessage("The Active Command Set in Final Cut Pro's plist could not be found.")
			return "Failed"
		else
			local activeCommandSet = trim(executeResult)
			for k, v in pairs(finalCutProShortcutKeyPlaceholders) do

				local executeCommand = "/usr/libexec/PlistBuddy -c \"Print :" .. tostring(k) .. ":\" '" .. tostring(activeCommandSet) .. "'"
				local executeResult,executeStatus,executeType,executeRC = hs.execute(executeCommand)

				if executeStatus == nil then
					--------------------------------------------------------------------------------
					-- Maybe there is nothing allocated to this command in the plist?
					--------------------------------------------------------------------------------
					if executeType ~= "exit" then
						print("[FCPX Hacks] WARNING: Retrieving data from plist failed (" .. tostring(k) .. ").")
						--print("executeResult: " .. tostring(executeResult))
						--print("executeStatus: " .. tostring(executeStatus))
						--print("executeType: " .. tostring(executeType))
						--print("executeRC: " .. tostring(executeRC))
					end
					local globalShortcut = finalCutProShortcutKeyPlaceholders[k]['global'] or false
					finalCutProShortcutKey[k] = { characterString = "", modifiers = {}, fn = finalCutProShortcutKeyPlaceholders[k]['fn'],  releasedFn = finalCutProShortcutKeyPlaceholders[k]['releasedFn'], repeatFn = finalCutProShortcutKeyPlaceholders[k]['repeatFn'], global = globalShortcut }
				else
					local x, lastDict = string.gsub(executeResult, "Dict {", "")
					lastDict = lastDict - 1
					local currentDict = ""

					--------------------------------------------------------------------------------
					-- Loop through each set of the same shortcut key:
					--------------------------------------------------------------------------------
					for whichDict=0, lastDict do

						if lastDict ~= 0 then
							if whichDict == 0 then
								addToK = ""
								currentDict = ":" .. tostring(whichDict)
							else
								currentDict = ":" .. tostring(whichDict)
								addToK = tostring(whichDict)
							end
						else
							currentDict = ""
							addToK = ""
						end

						--------------------------------------------------------------------------------
						-- Insert Blank Placeholder
						--------------------------------------------------------------------------------
						local globalShortcut = finalCutProShortcutKeyPlaceholders[k]['global'] or false
						finalCutProShortcutKey[k .. addToK] = { characterString = "", modifiers = {}, fn = finalCutProShortcutKeyPlaceholders[k]['fn'],  releasedFn = finalCutProShortcutKeyPlaceholders[k]['releasedFn'], repeatFn = finalCutProShortcutKeyPlaceholders[k]['repeatFn'], global = globalShortcut }

						local executeCommand = "/usr/libexec/PlistBuddy -c \"Print :" .. tostring(k) .. currentDict .. ":characterString\" '" .. tostring(activeCommandSet) .. "'"
						local executeResult,executeStatus,executeType,executeRC = hs.execute(executeCommand)

						if executeStatus == nil then
							if executeType == "exit" then
								--------------------------------------------------------------------------------
								-- Assuming that the plist was read fine, but contained no value:
								--------------------------------------------------------------------------------
								finalCutProShortcutKey[k .. addToK]['characterString'] = ""
							else
								displayErrorMessage("Could not read the plist correctly when retrieving characterString information.")
								return "Failed"
							end
						else
							finalCutProShortcutKey[k .. addToK]['characterString'] = translateKeyboardCharacters(trim(executeResult))
						end

					end
				end
			end
			for k, v in pairs(finalCutProShortcutKeyPlaceholders) do

				local executeCommand = "/usr/libexec/PlistBuddy -c \"Print :" .. tostring(k) .. ":\" '" .. tostring(activeCommandSet) .. "'"
				local executeResult,executeStatus = hs.execute(executeCommand)
				if executeStatus == nil then
					--------------------------------------------------------------------------------
					-- Maybe there is nothing allocated to this command in the plist?
					--------------------------------------------------------------------------------
					if executeType ~= "exit" then
						print("[FCPX Hacks] WARNING: Retrieving data from plist failed (" .. tostring(k) .. ").")
						--print("executeCommand: " .. tostring(executeCommand))
						--print("executeResult: " .. tostring(executeResult))
						--print("executeStatus: " .. tostring(executeStatus))
						--print("executeType: " .. tostring(executeType))
						--print("executeRC: " .. tostring(executeRC))
					end
					finalCutProShortcutKey[k]['modifiers'] = {}
				else
					local x, lastDict = string.gsub(executeResult, "Dict {", "")
					lastDict = lastDict - 1
					local currentDict = ""

					--------------------------------------------------------------------------------
					-- Loop through each set of the same shortcut key:
					--------------------------------------------------------------------------------
					for whichDict=0, lastDict do

						if lastDict ~= 0 then
							if whichDict == 0 then
								addToK = ""
								currentDict = ":" .. tostring(whichDict)
							else
								currentDict = ":" .. tostring(whichDict)
								addToK = tostring(whichDict)
							end
						else
							currentDict = ""
							addToK = ""
						end

						local executeCommand = "/usr/libexec/PlistBuddy -c \"Print :" .. tostring(k) .. currentDict .. ":modifiers\" '" .. tostring(activeCommandSet) .. "'"
						local executeResult,executeStatus,executeType,executeRC = hs.execute(executeCommand)
						if executeStatus == nil then
							if executeType == "exit" then
								--------------------------------------------------------------------------------
								-- Try modifierMask Instead!
								--------------------------------------------------------------------------------
								local executeCommand = "/usr/libexec/PlistBuddy -c \"Print :" .. tostring(k) .. currentDict .. ":modifierMask\" '" .. tostring(activeCommandSet) .. "'"
								local executeResult,executeStatus,executeType,executeRC = hs.execute(executeCommand)
								if executeStatus == nil then
									if executeType == "exit" then
										--------------------------------------------------------------------------------
										-- Assuming that the plist was read fine, but contained no value:
										--------------------------------------------------------------------------------
										finalCutProShortcutKey[k .. addToK]['modifiers'] = {}
									else
										displayErrorMessage("Could not read the plist correctly when retrieving modifierMask information.")
										return "Failed"
									end
								else
									finalCutProShortcutKey[k .. addToK]['modifiers'] = translateModifierMask(trim(executeResult))
								end
							else
								displayErrorMessage("Could not read the plist correctly when retrieving modifiers information.")
								return "Failed"
							end
						else
							finalCutProShortcutKey[k .. addToK]['modifiers'] = translateKeyboardModifiers(executeResult)
						end
					end
				end
			end
			return "Done"
		end
	end
end

--------------------------------------------------------------------------------
-- IS FINAL CUT PRO FRONTMOST?
--------------------------------------------------------------------------------
function isFinalCutProFrontmost()

	local fcpx = hs.appfinder.appFromName("Final Cut Pro")
	if fcpx == nil then
		return false
	else
		return fcpx:isFrontmost()
	end

end

--------------------------------------------------------------------------------
-- IS FINAL CUT PRO ACTIVE:
--------------------------------------------------------------------------------
function isFinalCutProRunning()

	local fcpx = hs.appfinder.appFromName("Final Cut Pro")
	if fcpx == nil then
		return false
	else
		return fcpx:isRunning()
	end

end

--------------------------------------------------------------------------------
-- IS FINAL CUT PRO INSTALLED:
--------------------------------------------------------------------------------
function isFinalCutProInstalled()
	return doesDirectoryExist('/Applications/Final Cut Pro.app')
end

--------------------------------------------------------------------------------
-- RETURNS FCPX VERSION:
--------------------------------------------------------------------------------
function finalCutProVersion()
	--------------------------------------------------------------------------------
	-- TO DO: Rewrite this in Lua:
	--------------------------------------------------------------------------------
	if isFinalCutProInstalled() then
		ok,appleScriptFinalCutProVersion = hs.osascript.applescript('return version of application "Final Cut Pro"')
		return appleScriptFinalCutProVersion
	else
		return "Not Installed"
	end
end

--------------------------------------------------------------------------------
-- FCPX OPEN KEYWORD EDITOR:
--------------------------------------------------------------------------------
function fcpxOpenKeywordEditor() -- Returns "Done" or "Failed"

	-- Define FCPX:
	local fcpx = hs.appfinder.appFromName("Final Cut Pro")

	-- Error Checking:
	if not fcpx then
		displayErrorMessage("Unable to detect Final Cut Pro.")
		return "Failed"
	end

	local str_showKeywordEditor = {"Mark", "Show Keyword Editor"}
	local showKeywordEditor = fcpx:findMenuItem(str_showKeywordEditor)

	if showKeywordEditor ~= nil then
		showKeywordEditorResult = fcpx:selectMenuItem({"Mark", "Show Keyword Editor"})
	else
		return "Done" -- Assuming window is already open.
	end
	if showKeywordEditorResult then
		return "Done"
	else
		return "Failed"
	end

end

--------------------------------------------------------------------------------
-- WHICH BROWSER MODE IS ACTIVE IN FCPX?
--------------------------------------------------------------------------------
function fcpxWhichBrowserMode() -- Returns "Filmstrip", "List" or "Failed"

	local fcpxBrowserMode = "Failed"

	-- Define FCPX:
	local fcpx = hs.appfinder.appFromName("Final Cut Pro")

	-- Put focus on FCPX:
	hs.application.launchOrFocus("Final Cut Pro")

	-- Error Checking:
	if not fcpx then
		displayErrorMessage("Unable to detect Final Cut Pro.")
		return "Failed"
	end

	local str_filmstripMode = {"View", "Browser", "as Filmstrips "}
	local str_listMode = {"View", "Browser", "as List"}

	local filmstripMode = fcpx:findMenuItem(str_filmstripMode)
	local listMode = fcpx:findMenuItem(str_listMode)

	if (filmstripMode and filmstripMode["ticked"]) then fcpxBrowserMode = "Filmstrip" end
	if (listMode and listMode["ticked"]) then fcpxBrowserMode = "List" end

	return fcpxBrowserMode

end

--------------------------------------------------------------------------------
-- IS FCPX IN SINGLE MONITOR MODE?
-------------------------------------------------------------------------------
function fcpxIsSingleMonitor() -- Returns "Yes", "No" or "Failed"
	-- Define FCPX:
	local fcpx = hs.appfinder.appFromName("Final Cut Pro")

	local fcpxSingleMonitor = "Failed"

	local str_singleMonitorMode = {"Window", "Show Events on Second Display"}
	local str_dualMonitorMode = {"Window", "Show Events in the Main Window"}

	local singleMonitorMode = fcpx:findMenuItem(str_singleMonitorMode)
	local dualMonitorMode = fcpx:findMenuItem(str_dualMonitorMode)

	if (singleMonitorMode) then fcpxSingleMonitor = "Yes" end
	if (dualMonitorMode) then fcpxSingleMonitor = "No" end

	return fcpxSingleMonitor
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     C O M M O N    F U N C T I O N S                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- HOW MANY ITEMS IN A TABLE?
--------------------------------------------------------------------------------
function tableCount(table)
  local count = 0
  for _ in pairs(table) do count = count + 1 end
  return count
end

--------------------------------------------------------------------------------
-- PROWL API KEY VALID:
--------------------------------------------------------------------------------
function prowlAPIKeyValid(input)

	local result = false
	local errorMessage = nil

	prowlAction = "https://api.prowlapp.com/publicapi/verify?apikey=" .. input
	httpResponse, httpBody, httpHeader = hs.http.get(prowlAction, nil)

	if string.match(httpBody, "success") then
		result = true
	else
		local xml = slaxdom:dom(tostring(httpBody))
		errorMessage = xml['root']['el'][1]['kids'][1]['value']
	end

	return result, errorMessage

end

--------------------------------------------------------------------------------
-- NINJA MOUSE CLICK:
--------------------------------------------------------------------------------
function ninjaMouseClick(position)
		local originalMousePoint = hs.mouse.getAbsolutePosition()
		hs.eventtap.leftClick(position)
		hs.mouse.setAbsolutePosition(originalMousePoint)
end

--------------------------------------------------------------------------------
-- PERFORM KEYSTROKE FROM PLIST DATA:
--------------------------------------------------------------------------------
function keyStrokeFromPlist(whichShortcut)
	if finalCutProShortcutKey[whichShortcut]['modifiers'] == nil then return false end
	if finalCutProShortcutKey[whichShortcut]['characterString'] == nil then return false end
	hs.eventtap.keyStroke(convertModifiersKeysForEventTap(finalCutProShortcutKey[whichShortcut]['modifiers']), 	keycodes.map[finalCutProShortcutKey[whichShortcut]['characterString']])
	return true
end

--------------------------------------------------------------------------------
-- MODIFIER MATCH:
--------------------------------------------------------------------------------
function modifierMatch(inputA, inputB)

	local match = true

	if fnutils.contains(inputA, "ctrl") and not fnutils.contains(inputB, "ctrl") then match = false end
	if fnutils.contains(inputA, "alt") and not fnutils.contains(inputB, "alt") then match = false end
	if fnutils.contains(inputA, "cmd") and not fnutils.contains(inputB, "cmd") then match = false end
	if fnutils.contains(inputA, "shift") and not fnutils.contains(inputB, "shift") then match = false end

	return match

end

--------------------------------------------------------------------------------
-- CONVERTS MODIFIERS KEYS INTO SOMETHING EVENTTAP CAN UNDERSTAND:
--------------------------------------------------------------------------------
function convertModifiersKeysForEventTap(input)

	for i in pairs(input) do
		if input[i] == "control" 	then input[i] = "ctrl" end
		if input[i] == "option" 	then input[i] = "alt" end
		if input[i] == "command" 	then input[i] = "cmd" end
		if input[i] == "⌃" 			then input[i] = "ctrl" end
		if input[i] == "⌥" 			then input[i] = "alt" end
		if input[i] == "⌘" 			then input[i] = "cmd" end
		if input[i] == "⇧" 			then input[i] = "shift" end
	end

	return input

end

--------------------------------------------------------------------------------
-- EXECUTE WITH ADMINISTRATOR PRIVILEGES:
--------------------------------------------------------------------------------
function executeWithAdministratorPrivileges(input)
	local appleScriptA = 'set shellScriptInput to "' .. input .. '"\n\n'
	local appleScriptB = [[
		try
			tell me to activate
			do shell script shellScriptInput with administrator privileges
			return true
		on error
			return false
		end try
	]]

	ok,result = hs.osascript.applescript(appleScriptA .. appleScriptB)
	return result
end

--------------------------------------------------------------------------------
-- KEYCODE TRANSLATOR:
--------------------------------------------------------------------------------
function keyCodeTranslator(input)

	local englishKeyCodes = {
		["'"] = 39,
		[","] = 43,
		["-"] = 27,
		["."] = 47,
		["/"] = 44,
		["0"] = 29,
		["1"] = 18,
		["2"] = 19,
		["3"] = 20,
		["4"] = 21,
		["5"] = 23,
		["6"] = 22,
		["7"] = 26,
		["8"] = 28,
		["9"] = 25,
		[";"] = 41,
		["="] = 24,
		["["] = 33,
		["\\"] = 42,
		["]"] = 30,
		["`"] = 50,
		["a"] = 0,
		["b"] = 11,
		["c"] = 8,
		["d"] = 2,
		["delete"] = 51,
		["down"] = 125,
		["e"] = 14,
		["end"] = 119,
		["escape"] = 53,
		["f"] = 3,
		["f1"] = 122,
		["f10"] = 109,
		["f11"] = 103,
		["f12"] = 111,
		["f13"] = 105,
		["f14"] = 107,
		["f15"] = 113,
		["f16"] = 106,
		["f17"] = 64,
		["f18"] = 79,
		["f19"] = 80,
		["f2"] = 120,
		["f20"] = 90,
		["f3"] = 99,
		["f4"] = 118,
		["f5"] = 96,
		["f6"] = 97,
		["f7"] = 98,
		["f8"] = 100,
		["f9"] = 101,
		["forwarddelete"] = 117,
		["g"] = 5,
		["h"] = 4,
		["help"] = 114,
		["home"] = 115,
		["i"] = 34,
		["j"] = 38,
		["k"] = 40,
		["l"] = 37,
		["left"] = 123,
		["m"] = 46,
		["n"] = 45,
		["o"] = 31,
		["p"] = 35,
		["pad*"] = 67,
		["pad+"] = 69,
		["pad-"] = 78,
		["pad."] = 65,
		["pad/"] = 75,
		["pad0"] = 82,
		["pad1"] = 83,
		["pad2"] = 84,
		["pad3"] = 85,
		["pad4"] = 86,
		["pad5"] = 87,
		["pad6"] = 88,
		["pad7"] = 89,
		["pad8"] = 91,
		["pad9"] = 92,
		["pad="] = 81,
		["padclear"] = 71,
		["padenter"] = 76,
		["pagedown"] = 121,
		["pageup"] = 116,
		["q"] = 12,
		["r"] = 15,
		["return"] = 36,
		["right"] = 124,
		["s"] = 1,
		["space"] = 49,
		["t"] = 17,
		["tab"] = 48,
		["u"] = 32,
		["up"] = 126,
		["v"] = 9,
		["w"] = 13,
		["x"] = 7,
		["y"] = 16,
		["z"] = 6,
		["§"] = 10
	}

	if englishKeyCodes[input] == nil then
		if hs.keycodes.map[input] == nil then
			return ""
		else
			return hs.keycodes.map[input]
		end
	else
		return englishKeyCodes[input]
	end

end

--------------------------------------------------------------------------------
-- DOUBLE LEFT CLICK:
--------------------------------------------------------------------------------
function doubleLeftClick(point)
	local clickState = hs.eventtap.event.properties.mouseEventClickState
	hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseDown"], point):setProperty(clickState, 1):post()
	hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], point):setProperty(clickState, 1):post()
	hs.timer.usleep(1000)
	hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseDown"], point):setProperty(clickState, 2):post()
	hs.eventtap.event.newMouseEvent(hs.eventtap.event.types["leftMouseUp"], point):setProperty(clickState, 2):post()
end

--------------------------------------------------------------------------------
-- TRANSLATE KEYBOARD CHARACTER STRINGS FROM PLIST TO HS FORMAT:
--------------------------------------------------------------------------------
function translateKeyboardCharacters(input)

	local result = tostring(input)

	if string.find(input, "NSF1FunctionKey") 			then result = "f1" 			end
	if string.find(input, "NSF2FunctionKey") 			then result = "f2" 			end
	if string.find(input, "NSF3FunctionKey") 			then result = "f3" 			end
	if string.find(input, "NSF4FunctionKey") 			then result = "f4" 			end
	if string.find(input, "NSF5FunctionKey") 			then result = "f5" 			end
	if string.find(input, "NSF6FunctionKey") 			then result = "f6" 			end
	if string.find(input, "NSF7FunctionKey") 			then result = "f7" 			end
	if string.find(input, "NSF8FunctionKey") 			then result = "f8" 			end
	if string.find(input, "NSF9FunctionKey") 			then result = "f9" 			end
	if string.find(input, "NSF10FunctionKey") 			then result = "f10" 		end
	if string.find(input, "NSF11FunctionKey") 			then result = "f11" 		end
	if string.find(input, "NSF12FunctionKey") 			then result = "f12" 		end
	if string.find(input, "NSF13FunctionKey") 			then result = "f13" 		end
	if string.find(input, "NSF14FunctionKey") 			then result = "f14" 		end
	if string.find(input, "NSF15FunctionKey") 			then result = "f15" 		end
	if string.find(input, "NSF16FunctionKey") 			then result = "f16" 		end
	if string.find(input, "NSF17FunctionKey") 			then result = "f17" 		end
	if string.find(input, "NSF18FunctionKey") 			then result = "f18" 		end
	if string.find(input, "NSF19FunctionKey") 			then result = "f19" 		end
	if string.find(input, "NSF20FunctionKey") 			then result = "f20" 		end
	if string.find(input, "NSUpArrowFunctionKey") 		then result = "up" 			end
	if string.find(input, "NSDownArrowFunctionKey") 	then result = "down" 		end
	if string.find(input, "NSLeftArrowFunctionKey") 	then result = "left" 		end
	if string.find(input, "NSRightArrowFunctionKey") 	then result = "right" 		end
	if string.find(input, "NSDeleteFunctionKey") 		then result = "delete" 		end
	if string.find(input, "NSHomeFunctionKey") 			then result = "home" 		end
	if string.find(input, "NSEndFunctionKey") 			then result = "end" 		end
	if string.find(input, "NSPageUpFunctionKey") 		then result = "pageup" 		end
	if string.find(input, "NSPageDownFunctionKey") 		then result = "pagedown" 	end

	--------------------------------------------------------------------------------
	-- Convert to lowercase:
	--------------------------------------------------------------------------------
	result = string.lower(result)

	local convertedToKeycode = keyCodeTranslator(result)
	if convertedToKeycode == nil then
		print("[FCPX HACKS] NON-FATAL ERROR: Failed to translate keyboard character (" .. tostring(input) .. ").")
		result = ""
	else
		result = convertedToKeycode
	end

	return result

end

--------------------------------------------------------------------------------
-- TRANSLATE KEYBOARD MODIFIERS FROM PLIST STRING TO HS TABLE FORMAT:
--------------------------------------------------------------------------------
function translateKeyboardModifiers(input)

	local result = {}
	if string.find(input, "command") then result[#result + 1] = "command" end
	if string.find(input, "control") then result[#result + 1] = "control" end
	if string.find(input, "option") then result[#result + 1] = "option" end
	if string.find(input, "shift") then result[#result + 1] = "shift" end
	return result

end

--------------------------------------------------------------------------------
-- TRANSLATE KEYBOARD MODIFIERS FROM PLIST STRING TO HS TABLE FORMAT:
--------------------------------------------------------------------------------
function translateModifierMask(value)

    local modifiers = {
        --AlphaShift = 1 << 16,
        shift      = 1 << 17,
        control    = 1 << 18,
        option	   = 1 << 19,
        command    = 1 << 20,
        --NumericPad = 1 << 21,
        --Help       = 1 << 22,
        --Function   = 1 << 23,
    }

    local answer = {}

    for k, v in pairs(modifiers) do
        if (value & v) == v then
            table.insert(answer, k)
        end
    end

    return answer

end

--------------------------------------------------------------------------------
-- REMOVE FILENAME FROM PATH:
--------------------------------------------------------------------------------
function removeFilenameFromPath(input)
	return (string.sub(input, 1, (string.find(input, "/[^/]*$"))))
end

--------------------------------------------------------------------------------
-- SLEEP:
--------------------------------------------------------------------------------
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

--------------------------------------------------------------------------------
-- CONVERT SECONDS TO TIMECODE:
--------------------------------------------------------------------------------
function secondsToTimecode(seconds, framerate)
	local seconds = tonumber(seconds)
	if framerate == nil then framerate = 25 end
	if framerate <= 0 then framerate = 25 end
	if seconds <= 0 then
		return "00:00:00:00";
	else
		hours 	= string.format("%02.f", math.floor(seconds/3600));
		mins 	= string.format("%02.f", math.floor(seconds/60 - (hours*60)));
		secs 	= string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
		frames 	= string.format("%02.f", (seconds % 1) * framerate);
		return hours..":"..mins..":"..secs..":"..frames
	end
end

-------------------------------------------------------------------------------
-- RETURNS MACOS VERSION:
-------------------------------------------------------------------------------
function macOSVersion()
	local osVersion = hs.host.operatingSystemVersion()
	local osVersionString = (tostring(osVersion["major"]) .. "." .. tostring(osVersion["minor"]) .. "." .. tostring(osVersion["patch"]))
	return osVersionString
end

--------------------------------------------------------------------------------
-- DOES DIRECTORY EXIST:
--------------------------------------------------------------------------------
function doesDirectoryExist(path)
    local attr = hs.fs.attributes(path)
    return attr and attr.mode == 'directory'
end

--------------------------------------------------------------------------------
-- SPLIT STRING:
--------------------------------------------------------------------------------
local function split(str, sep)
   local result = {}
   local regex = ("([^%s]+)"):format(sep)
   for each in str:gmatch(regex) do
      table.insert(result, each)
   end
   return result
end

--------------------------------------------------------------------------------
-- TRIM STRING:
--------------------------------------------------------------------------------
function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

--------------------------------------------------------------------------------
-- DISPLAY SMALL NUMBER TEXT BOX MESSAGE:
--------------------------------------------------------------------------------
function displaySmallNumberTextBoxMessage(whatMessage, whatErrorMessage, defaultAnswer)
	local returnToFinalCutPro = isFinalCutProFrontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = 'set whatErrorMessage to "' .. whatErrorMessage .. '"' .. '\n\n'
	local appleScriptC = 'set defaultAnswer to "' .. defaultAnswer .. '"' .. '\n\n'
	local appleScriptD = [[
		repeat
			try
				tell me to activate
				set dialogResult to (display dialog whatMessage default answer defaultAnswer buttons {"OK", "Cancel"} with icon fcpxIcon)
			on error
				-- Cancel Pressed:
				return false
			end try
			try
				set usersInput to (text returned of dialogResult) as number -- To accept only entries that coerce directly to class integer.
				if usersInput is not equal to missing value then
					if usersInput is not 0 then
						exit repeat
					end if
				end if
			end try
			display dialog whatErrorMessage buttons {"OK"} with icon fcpxIcon
		end repeat
		return usersInput
	]]
	a,result = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB .. appleScriptC .. appleScriptD)
	if returnToFinalCutPro then launchFinalCutPro() end
	return result
end

--------------------------------------------------------------------------------
-- DISPLAY TEXT BOX MESSAGE:
--------------------------------------------------------------------------------
function displayTextBoxMessage(whatMessage, whatErrorMessage, defaultAnswer)
	local returnToFinalCutPro = isFinalCutProFrontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = 'set whatErrorMessage to "' .. whatErrorMessage .. '"' .. '\n\n'
	local appleScriptC = 'set defaultAnswer to "' .. defaultAnswer .. '"' .. '\n\n'
	local appleScriptD = [[
		set allowedLetters to characters of (do shell script "printf \"%c\" {a..z}")
		set allowedNumbers to characters of (do shell script "printf \"%c\" {0..9}")
		set allowedAll to allowedLetters & allowedNumbers & space

		repeat
			try
				tell me to activate
				set response to text returned of (display dialog whatMessage default answer defaultAnswer buttons {"OK", "Cancel"} default button 1 with icon fcpxIcon)
			on error
				-- Cancel Pressed:
				return false
			end try
			try
				set invalidCharacters to false
				repeat with aCharacter in response
					if (aCharacter as text) is not in allowedAll then
						set invalidCharacters to true
					end if
				end repeat
				if length of response is 0 then
					set invalidCharacters to true
				end if
				if invalidCharacters is false then
					exit repeat
				end
			end try
			display dialog whatErrorMessage buttons {"OK"} with icon fcpxIcon
		end repeat
		return response
	]]
	a,result = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB .. appleScriptC .. appleScriptD)
	if returnToFinalCutPro then launchFinalCutPro() end
	return result
end

--------------------------------------------------------------------------------
-- DISPLAY ALERT MESSAGE:
--------------------------------------------------------------------------------
function displayAlertMessage(whatMessage)
	local returnToFinalCutPro = isFinalCutProFrontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		display dialog whatMessage buttons {"OK"} with icon stop
	]]
	hs.osascript.applescript(appleScriptA .. appleScriptB)
	if returnToFinalCutPro then launchFinalCutPro() end
end

--------------------------------------------------------------------------------
-- DISPLAY ERROR MESSAGE:
--------------------------------------------------------------------------------
function displayErrorMessage(whatError)
	local returnToFinalCutPro = isFinalCutProFrontmost()
	local appleScriptA = 'set whatError to "' .. whatError .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		display dialog commonErrorMessageStart & whatError & commonErrorMessageEnd buttons {"OK"} with icon fcpxIcon
	]]
	hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB)
	if returnToFinalCutPro then launchFinalCutPro() end
end

--------------------------------------------------------------------------------
-- DISPLAY MESSAGE:
--------------------------------------------------------------------------------
function displayMessage(whatMessage)
	local returnToFinalCutPro = isFinalCutProFrontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		display dialog whatMessage buttons {"OK"} with icon fcpxIcon
	]]
	hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB)
	if returnToFinalCutPro then launchFinalCutPro() end
end

--------------------------------------------------------------------------------
-- DISPLAY YES OR NO QUESTION:
--------------------------------------------------------------------------------
function displayYesNoQuestion(whatMessage) -- returns true or false

	local returnToFinalCutPro = isFinalCutProFrontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		display dialog whatMessage buttons {"Yes", "No"} default button 1 with icon fcpxIcon
		if the button returned of the result is "Yes" then
			return true
		else
			return false
		end if
	]]
	a,result = hs.osascript.applescript(commonErrorMessageAppleScript .. appleScriptA .. appleScriptB)
	if returnToFinalCutPro then launchFinalCutPro() end
	return result

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
	displayHighlightShape = hs.settings.get("fcpxHacks.displayHighlightShape")
	if displayHighlightShape == nil then displayHighlightShape = "Rectangle" end

	--------------------------------------------------------------------------------
	-- Get Highlight Colour Preferences:
	--------------------------------------------------------------------------------
	local displayHighlightColour = nil
	displayHighlightColour = hs.settings.get("fcpxHacks.displayHighlightColour")
	if displayHighlightColour == nil then 		displayHighlightColour = "Red" 												end
	if displayHighlightColour == "Red" then 	displayHighlightColour = {["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1} 	end
	if displayHighlightColour == "Blue" then 	displayHighlightColour = {["red"]=0,["blue"]=1,["green"]=0,["alpha"]=1}		end
	if displayHighlightColour == "Green" then 	displayHighlightColour = {["red"]=0,["blue"]=0,["green"]=1,["alpha"]=1}		end
	if displayHighlightColour == "Yellow" then 	displayHighlightColour = {["red"]=1,["blue"]=0,["green"]=1,["alpha"]=1}		end

	--------------------------------------------------------------------------------
    -- Highlight the FCPX Browser Playhead:
    --------------------------------------------------------------------------------
   	if displayHighlightShape == "Rectangle" then
		browserHighlight = hs.drawing.rectangle(hs.geometry.rect(mouseHighlightX, mouseHighlightY, mouseHighlightW, mouseHighlightH - 12))
		browserHighlight:setStrokeColor(displayHighlightColour)
		browserHighlight:setFill(false)
		browserHighlight:setStrokeWidth(5)
		browserHighlight:show()
	end
	if displayHighlightShape == "Circle" then
		browserHighlight = hs.drawing.circle(hs.geometry.rect((mouseHighlightX-(mouseHighlightH/2)+10), mouseHighlightY, mouseHighlightH-12, mouseHighlightH-12))
		browserHighlight:setStrokeColor(displayHighlightColour)
		browserHighlight:setFill(false)
		browserHighlight:setStrokeWidth(5)
		browserHighlight:show()
	end
	if displayHighlightShape == "Diamond" then
		browserHighlight = hs.drawing.circle(hs.geometry.rect(mouseHighlightX, mouseHighlightY, mouseHighlightW, mouseHighlightH - 12))
		browserHighlight:setStrokeColor(displayHighlightColour)
		browserHighlight:setFill(false)
		browserHighlight:setStrokeWidth(5)
		browserHighlight:show()
	end

	--------------------------------------------------------------------------------
    -- Set a timer to delete the circle after 3 seconds:
    --------------------------------------------------------------------------------
    browserHighlightTimer = hs.timer.doAfter(3, function() browserHighlight:delete() end)

end

--------------------------------------------------------------------------------
-- DELETE ALL HIGHLIGHTS:
--------------------------------------------------------------------------------
function deleteAllHighlights()
	--------------------------------------------------------------------------------
    -- Delete FCPX Browser Highlight:
    --------------------------------------------------------------------------------
    if browserHighlight then
        browserHighlight:delete()
        if browserHighlightTimer then
            browserHighlightTimer:stop()
        end
    end
end

--------------------------------------------------------------------------------
-- PRINT TABLE CONTENTS (USED FOR DEBUGGING):
--------------------------------------------------------------------------------
function print_r ( t )
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

--------------------------------------------------------------------------------
-- NOTIFICATION WATCHER ACTIONS:
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
		httpResponse, httpBody, httpHeader = hs.http.get(prowlAction, nil)

		if not string.match(httpBody, "success") then
			local xml = slaxdom:dom(tostring(httpBody))
			local errorMessage = xml['root']['el'][1]['kids'][1]['value'] or nil
			if errorMessage ~= nil then print("[FCPX Hacks] PROWL ERROR: " .. trim(tostring(errorMessage))) end
		end
	end

end

--------------------------------------------------------------------------------
-- CHECK TO SEE IF WE SHOULD ACTUALLY TURN ON THE SCROLLING TIMELINE:
--------------------------------------------------------------------------------
function checkScrollingTimelinePress()
	--------------------------------------------------------------------------------
	-- Variables:
	--------------------------------------------------------------------------------
	local useCache 			= false
	local whichGroup 		= nil
	local whichSplitGroup 	= nil

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	local fcpx 				= hs.application("Final Cut Pro")

	--------------------------------------------------------------------------------
	-- Don't activate scrollbar in fullscreen mode (no player controls visible):
	--------------------------------------------------------------------------------
	local fullscreenActive = false
	local fcpxElements = ax.applicationElement(fcpx)
	if fcpxElements[1][1] ~= nil then
		if fcpxElements[1][1]:attributeValue("AXDescription") == "Display Area" then
			if whichKey == 49 then
				if debugMode then print("[FCPX Hacks] Spacebar pressed in fullscreen mode whilst watching for scrolling timeline.") end
				fullscreenActive = true
			end
		end
	end

	--------------------------------------------------------------------------------
	-- Don't activate scrollbar in fullscreen mode (player controls visible):
	--------------------------------------------------------------------------------
	if fcpxElements[1][1] ~= nil then
		if fcpxElements[1][1][1] ~= nil then
			if fcpxElements[1][1][1][1] ~= nil then
				if fcpxElements[1][1][1][1]:attributeValue("AXDescription") == "Play Pause" then
					if whichKey == 49 then
						if debugMode then print("[FCPX Hacks] Spacebar pressed in fullscreen mode whilst watching for scrolling timeline.") end
						fullscreenActive = true
					end
				end
			end
		end
	end

	--------------------------------------------------------------------------------
	-- If not in fullscreen mode:
	--------------------------------------------------------------------------------
	if not fullscreenActive then

		--------------------------------------------------------------------------------
		-- Get all FCPX UI Elements:
		--------------------------------------------------------------------------------
		fcpxElements = ax.applicationElement(hs.application("Final Cut Pro"))[1]

		--------------------------------------------------------------------------------
		-- Check to see if the cache works, otherwise re-find the interface elements:
		--------------------------------------------------------------------------------
		if scrollingTimelineSplitGroupCache ~= nil and scrollingTimelineGroupCache ~= nil then
			if fcpxElements[scrollingTimelineSplitGroupCache] ~= nil then
				if fcpxElements[scrollingTimelineSplitGroupCache][scrollingTimelineGroupCache] ~= nil then
					if fcpxElements[scrollingTimelineSplitGroupCache][scrollingTimelineGroupCache][1][2] ~= nil then
						if fcpxElements[scrollingTimelineSplitGroupCache][scrollingTimelineGroupCache][1][2]:attributeValue("AXIdentifier") == "_NS:95" then
							whichSplitGroup = scrollingTimelineSplitGroupCache
							whichGroup = scrollingTimelineGroupCache
							useCache = true
						end
					end
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Cache failed - so need to re-gather interface elements:
		--------------------------------------------------------------------------------
		if not useCache then
			--------------------------------------------------------------------------------
			-- Which Split Group:
			--------------------------------------------------------------------------------
			for i=1, fcpxElements:attributeValueCount("AXChildren") do
				if whichSplitGroup == nil then
					if fcpxElements:attributeValue("AXChildren")[i]:attributeValue("AXRole") == "AXSplitGroup" then
						whichSplitGroup = i
						goto scrollingTimelineWatcherSplitGroupExit
					end
				end
			end
			if whichSplitGroup == nil then
				displayErrorMessage("Unable to locate Split Group.")
				return "Failed"
			end
			::scrollingTimelineWatcherSplitGroupExit::
			scrollingTimelineSplitGroupCache = whichSplitGroup

			--------------------------------------------------------------------------------
			-- Which Group:
			--------------------------------------------------------------------------------
			for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
				if whichGroup == nil then
					if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1] ~= nil then
						if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1]:attributeValue("AXRole") == "AXSplitGroup" then
							if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1]:attributeValue("AXIdentifier") == "_NS:11" then
								whichGroup = i
								goto performScrollingTimelineWatcherGroupExit
							end
						end
					end
				end
			end
			if whichGroup == nil then
				--------------------------------------------------------------------------------
				-- Can't find group so assuming we're in fullscreen mode:
				--------------------------------------------------------------------------------
				return "Failed"
			end
			::performScrollingTimelineWatcherGroupExit::
			scrollingTimelineGroupCache = whichGroup
		end -- useCache

		--------------------------------------------------------------------------------
		-- Check mouse is in timeline area:
		--------------------------------------------------------------------------------
		local mouseLocation = hs.mouse.getAbsolutePosition()
		local timelinePosition = fcpxElements[whichSplitGroup][whichGroup][1][2]:attributeValue("AXPosition")
		local timelineSize = fcpxElements[whichSplitGroup][whichGroup][1][2]:attributeValue("AXSize")
		local isMouseInTimelineArea = true
		if (mouseLocation['y'] <= timelinePosition['y']) then isMouseInTimelineArea = false end 							-- Too High
		if (mouseLocation['y'] >= (timelinePosition['y']+timelineSize['h'])) then isMouseInTimelineArea = false end 		-- Too Low
		if (mouseLocation['x'] <= timelinePosition['x']) then isMouseInTimelineArea = false end 							-- Too Left
		if (mouseLocation['x'] >= (timelinePosition['x']+timelineSize['w'])) then isMouseInTimelineArea = false end 		-- Too Right
		if isMouseInTimelineArea then

			--------------------------------------------------------------------------------
			-- Mouse is in the timeline area when spacebar pressed so LET'S DO IT!
			--------------------------------------------------------------------------------

				--------------------------------------------------------------------------------
				-- Which Value Indicator:
				--------------------------------------------------------------------------------
				local whichValueIndicator = nil
				for i=1, fcpxElements[whichSplitGroup][whichGroup][1][2][1]:attributeValueCount("AXChildren") do
					if fcpxElements[whichSplitGroup][whichGroup][1][2][1]:attributeValue("AXChildren")[i]:attributeValue("AXDescription") == "Playhead" then
						whichValueIndicator = i
						goto performScrollingTimelineValueIndicatorExit
					end
				end
				if whichValueIndicator == nil then
					displayErrorMessage("Unable to locate Value Indicator.")
					return "Failed"
				end
				::performScrollingTimelineValueIndicatorExit::

				local initialPlayheadXPosition = fcpxElements[whichSplitGroup][whichGroup][1][2][1][whichValueIndicator]:attributeValue("AXPosition")['x']

				performScrollingTimelineLoops(whichSplitGroup, whichGroup, whichValueIndicator, initialPlayheadXPosition)


		end --isMouseInTimelineArea
	end -- fullscreenActive
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                             W A T C H E R S                                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- AUTOMATICALLY DO THINGS WHEN FCPX IS LAUNCHED, CLOSED OR HIDDEN:
--------------------------------------------------------------------------------
function finalCutProWatcher(appName, eventType, appObject)
	if (appName == "Final Cut Pro") then
		if (eventType == hs.application.watcher.activated) then
			--------------------------------------------------------------------------------
	  		-- FCPX Active:
	  		--------------------------------------------------------------------------------

	  		-- Enable Hotkeys:
	  		hotkeys:enter()

	  		-- Enable Menubar Items:
	  		refreshMenuBar()

	  		-- Full Screen Keyboard Watcher:
	  		if hs.settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") == true then
		  		fullscreenKeyboardWatcherUp:start()
				fullscreenKeyboardWatcherDown:start()
			end

			-- Disable Scrolling Timeline Watcher:
			if hs.settings.get("fcpxHacks.scrollingTimelineActive") == true then
				if scrollingTimelineWatcherUp ~= nil then
					scrollingTimelineWatcherUp:start()
					scrollingTimelineWatcherDown:start()
				end
			end

		elseif (eventType == hs.application.watcher.deactivated) or (eventType == hs.application.watcher.terminated) then
			--------------------------------------------------------------------------------
			-- FCPX Lost Focus:
			--------------------------------------------------------------------------------

	   		-- Full Screen Keyboard Watcher:
	   		if hs.settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") == true then
		  		fullscreenKeyboardWatcherUp:stop()
				fullscreenKeyboardWatcherDown:stop()
			end

			-- Disable Scrolling Timeline Watcher:
			if hs.settings.get("fcpxHacks.scrollingTimelineActive") == true then
				if scrollingTimelineWatcherUp ~= nil then
					scrollingTimelineWatcherUp:stop()
					scrollingTimelineWatcherDown:stop()
				end
			end

			-- Disable hotkeys:
	  		hotkeys:exit()

	  		-- Disable Menubar Items:
	  		refreshMenuBar()

			-- Delete the Mouse Circle:
	  		deleteAllHighlights()

		end
	end
end

--------------------------------------------------------------------------------
-- AUTOMATICALLY RELOAD THIS CONFIG FILE WHEN UPDATED:
--------------------------------------------------------------------------------
function reloadConfig(files)
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
-- AUTOMATICALLY DO THINGS WHEN FCPX PLIST IS UPDATED:
--------------------------------------------------------------------------------
function finalCutProSettingsPlistChanged(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-24) == "com.apple.FinalCut.plist" then
            doReload = true
        end
    end
    if doReload then
    	--------------------------------------------------------------------------------
    	-- Refresh Menubar:
    	--------------------------------------------------------------------------------
    	refreshMenuBar(true)

    	--------------------------------------------------------------------------------
    	-- Update Menubar Icon:
    	--------------------------------------------------------------------------------
    	updateMenubarIcon()
    end
end

--------------------------------------------------------------------------------
-- DISABLE SHORTCUTS WHEN FCPX COMMAND EDITOR IS OPEN:
--------------------------------------------------------------------------------
function commandEditorWatcher()
	local commandEditorID = nil
	local filter = hs.window.filter.new(true)
	filter:subscribe(
	  hs.window.filter.windowCreated,
	  (function(window, applicationName)
		if applicationName == 'Final Cut Pro' then
			if (window:title() == 'Command Editor') then

				--------------------------------------------------------------------------------
				-- Command Editor is Open:
				--------------------------------------------------------------------------------
				commandEditorID = window:id()
				isCommandEditorOpen = true
				if debugMode then print("[FCPX Hacks] Command Editor Opened.") end
				--------------------------------------------------------------------------------

				--------------------------------------------------------------------------------
				-- Disable Hotkeys:
				--------------------------------------------------------------------------------
				if hotkeys ~= nil then -- For the rare case when Command Editor is open on load.
					hotkeys:exit()
				end
				--------------------------------------------------------------------------------

			end
		end
	  end),
	  true
	)
	filter:subscribe(
	  hs.window.filter.windowDestroyed,
	  (function(window, applicationName)
		if applicationName == 'Final Cut Pro' then
			if (window:id() == commandEditorID) then

				--------------------------------------------------------------------------------
				-- Command Editor is Closed:
				--------------------------------------------------------------------------------
				commandEditorID = nil
				isCommandEditorOpen = false
				if debugMode then print("[FCPX Hacks] Command Editor Closed.") end
				--------------------------------------------------------------------------------

				--------------------------------------------------------------------------------
				-- Refresh Keyboard Shortcuts:
				--------------------------------------------------------------------------------
				local doOnce = true
				hs.timer.waitUntil(function() return doOnce end, function()
					bindKeyboardShortcuts()
					doOnce = false
				end, 0.00000001)
				--------------------------------------------------------------------------------

			end
		end
	  end),
	  true
	)

end

--------------------------------------------------------------------------------
-- ENABLE SHORTCUTS DURING FCPX FULLSCREEN PLAYBACK:
--------------------------------------------------------------------------------
function fullscreenKeyboardWatcher()
	fullscreenKeyboardWatcherWorking = false
	fullscreenKeyboardWatcherUp = hs.eventtap.new({ hs.eventtap.event.types.keyUp }, function(event)
		fullscreenKeyboardWatcherWorking = false
	end)
	fullscreenKeyboardWatcherDown = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)

		--------------------------------------------------------------------------------
		-- Don't repeat if key is held down:
		--------------------------------------------------------------------------------
		if fullscreenKeyboardWatcherWorking then return false end
		fullscreenKeyboardWatcherWorking = true

		--------------------------------------------------------------------------------
		-- Define Final Cut Pro:
		--------------------------------------------------------------------------------
		local fcpx = hs.application("Final Cut Pro")
		local fcpxElements = ax.applicationElement(fcpx)

		--------------------------------------------------------------------------------
		-- Only Continue if in Full Screen Playback Mode:
		--------------------------------------------------------------------------------
		if fcpxElements[1][1] ~= nil then
			if fcpxElements[1][1]:attributeValue("AXDescription") == "Display Area" then

				--------------------------------------------------------------------------------
				-- Get keypress information:
				--------------------------------------------------------------------------------
				local whichKey = event:getKeyCode()			-- EXAMPLE: keyCodeTranslator(whichKey) == "c"
				local whichModifier = event:getFlags()		-- EXAMPLE: whichFlags['cmd']

				--------------------------------------------------------------------------------
				-- Check all of these shortcut keys for presses:
				--------------------------------------------------------------------------------
				local fullscreenKeys = {"SetSelectionStart", "SetSelectionEnd", "AnchorWithSelectedMedia", "AnchorWithSelectedMediaAudioBacktimed", "InsertMedia", "AppendWithSelectedMedia" }
				for x, whichShortcutKey in pairs(fullscreenKeys) do
					if finalCutProShortcutKey[whichShortcutKey]['characterString'] ~= nil then
						if finalCutProShortcutKey[whichShortcutKey]['characterString'] ~= "" then
							if whichKey == finalCutProShortcutKey[whichShortcutKey]['characterString'] and modifierMatch(whichModifier, finalCutProShortcutKey[whichShortcutKey]['modifiers']) then
								hs.eventtap.keyStroke({""}, "escape")
								hs.eventtap.keyStroke(convertModifiersKeysForEventTap(finalCutProShortcutKey["GoToOrganizer"]['modifiers']), keycodes.map[finalCutProShortcutKey["GoToOrganizer"]['characterString']])
								hs.eventtap.keyStroke(convertModifiersKeysForEventTap(finalCutProShortcutKey[whichShortcutKey]['modifiers']), keycodes.map[finalCutProShortcutKey[whichShortcutKey]['characterString']])
								hs.eventtap.keyStroke(convertModifiersKeysForEventTap(finalCutProShortcutKey["PlayFullscreen"]['modifiers']), keycodes.map[finalCutProShortcutKey["PlayFullscreen"]['characterString']])
								return true
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
					if fcpxElements[1][1][1][1]:attributeValue("AXDescription") == "Play Pause" then

						--------------------------------------------------------------------------------
						-- Get keypress information:
						--------------------------------------------------------------------------------
						local whichKey = event:getKeyCode()			-- EXAMPLE: keyCodeTranslator(whichKey) == "c"
						local whichModifier = event:getFlags()		-- EXAMPLE: whichFlags['cmd']

						--------------------------------------------------------------------------------
						-- Check all of these shortcut keys for presses:
						--------------------------------------------------------------------------------
						local fullscreenKeys = {"SetSelectionStart", "SetSelectionEnd", "AnchorWithSelectedMedia", "AnchorWithSelectedMediaAudioBacktimed", "InsertMedia", "AppendWithSelectedMedia" }
						for x, whichShortcutKey in pairs(fullscreenKeys) do
							if finalCutProShortcutKey[whichShortcutKey]['characterString'] ~= nil then
								if finalCutProShortcutKey[whichShortcutKey]['characterString'] ~= "" then
									if whichKey == finalCutProShortcutKey[whichShortcutKey]['characterString'] and modifierMatch(whichModifier, finalCutProShortcutKey[whichShortcutKey]['modifiers']) then
										hs.eventtap.keyStroke({""}, "escape")
										hs.eventtap.keyStroke(convertModifiersKeysForEventTap(finalCutProShortcutKey["GoToOrganizer"]['modifiers']), keycodes.map[finalCutProShortcutKey["GoToOrganizer"]['characterString']])
										hs.eventtap.keyStroke(convertModifiersKeysForEventTap(finalCutProShortcutKey[whichShortcutKey]['modifiers']), keycodes.map[finalCutProShortcutKey[whichShortcutKey]['characterString']])
										hs.eventtap.keyStroke(convertModifiersKeysForEventTap(finalCutProShortcutKey["PlayFullscreen"]['modifiers']), keycodes.map[finalCutProShortcutKey["PlayFullscreen"]['characterString']])
										return true
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
-- WATCH THE FINAL CUT PRO CLIPBOARD FOR CHANGES:
--------------------------------------------------------------------------------
function clipboardWatcher()

	--------------------------------------------------------------------------------
	-- Get Clipboard History from Settings:
	--------------------------------------------------------------------------------
	clipboardHistory = settings.get("fcpxHacks.clipboardHistory") or {}

	--------------------------------------------------------------------------------
	-- Watch for Clipboard Changes:
	--------------------------------------------------------------------------------
	clipboardTimer = hs.timer.new(clipboardWatcherFrequency, function()
		clipboardCurrentChange = pasteboard.changeCount()
  		if (clipboardCurrentChange > clipboardLastChange) then

		 	local clipboardContent = pasteboard.allContentTypes()
		 	if clipboardContent[1][1] == finalCutProClipboardUTI then

		 		if debugMode then print("[FCPX Hacks] Something has been added to FCPX's Clipboard.") end

				--------------------------------------------------------------------------------
				-- Set Up Variables:
				--------------------------------------------------------------------------------
				local executeOutput 			= nil
				local executeStatus 			= nil
				local executeType 				= nil
				local executeRC 				= nil
				local addToClipboardHistory 	= true

				--------------------------------------------------------------------------------
				-- Save Clipboard Data:
				--------------------------------------------------------------------------------
				local currentClipboardData 		= pasteboard.readDataForUTI(finalCutProClipboardUTI)

				--------------------------------------------------------------------------------
				-- Define Temporary Files:
				--------------------------------------------------------------------------------
				local temporaryFileName 		= os.tmpname()
				local temporaryFileNameTwo	 	= os.tmpname()

				--------------------------------------------------------------------------------
				-- Write Clipboard Data to Temporary File:
				--------------------------------------------------------------------------------
				local temporaryFile = io.open(temporaryFileName, "w")
				temporaryFile:write(currentClipboardData)
				temporaryFile:close()

				--------------------------------------------------------------------------------
				-- Convert binary plist to XML then return in JSON:
				--------------------------------------------------------------------------------
				local executeOutput, executeStatus, executeType, executeRC = hs.execute([[
					plutil -convert xml1 ]] .. temporaryFileName .. [[ -o - |
					sed 's/data>/string>/g' |
					plutil -convert json - -o -
				]])
				if not executeStatus then
					print("[FCPX Hacks] ERROR: Failed to convert binary plist to XML.")
					addToClipboardHistory = false
				end

				--------------------------------------------------------------------------------
				-- Get data from 'ffpasteboardobject':
				--------------------------------------------------------------------------------
				local file = io.open(temporaryFileName, "w")
				file:write(json.decode(executeOutput)["ffpasteboardobject"])
				file:close()

				--------------------------------------------------------------------------------
				-- Convert base64 data to human readable:
				--------------------------------------------------------------------------------
				executeCommand = "openssl base64 -in " .. tostring(temporaryFileName) .. " -out " .. tostring(temporaryFileNameTwo) .. " -d"
				executeOutput, executeStatus, executeType, executeRC = hs.execute(executeCommand)
				if not executeStatus then
					print("[FCPX Hacks] ERROR: Failed to convert base64 data to human readable.")
					addToClipboardHistory = false
				end

				--------------------------------------------------------------------------------
				-- Convert from binary plist to human readable:
				--------------------------------------------------------------------------------
				executeOutput, executeStatus, executeType, executeRC = hs.execute("plutil -convert xml1 " .. tostring(temporaryFileNameTwo))
				if not executeStatus then
					print("[FCPX Hacks] ERROR: Failed to convert from binary plist to human readable.")
					addToClipboardHistory = false
				end

				--------------------------------------------------------------------------------
				-- Bring XML data into Hammerspoon:
				--------------------------------------------------------------------------------
				executeOutput, executeStatus, executeType, executeRC = hs.execute("cat " .. tostring(temporaryFileNameTwo))
				if not executeStatus then
					print("[FCPX Hacks] ERROR: Failed to cat the plist.")
					addToClipboardHistory = false
				end

				--------------------------------------------------------------------------------
				-- XML fun times!
				--------------------------------------------------------------------------------
				local xml = slaxdom:dom(tostring(executeOutput))
				local currentClipboardLabel = nil

					--------------------------------------------------------------------------------
					-- TO-DO: Work out the structure of the clipboard data then rewrite this:
					--------------------------------------------------------------------------------

					--------------------------------------------------------------------------------
					-- Clip copied from Primary Storyline:
					--------------------------------------------------------------------------------
					if xml['root']['kids'][2]['kids'][8]['kids'][24]['kids'][1]['value'] == "metadataImportToApp" then
						currentClipboardLabel = xml['root']['kids'][2]['kids'][8]['kids'][20]['kids'][1]['value']
					end

					--------------------------------------------------------------------------------
					-- Clip copied from Secondary Storyline:
					--------------------------------------------------------------------------------
					if xml['kids'][2]['el'][1]['el'][4]['el'][17]['kids'][1]['value'] == "metadataImportToApp" then
						currentClipboardLabel = xml['kids'][2]['el'][1]['el'][4]['el'][15]['kids'][1]['value']
					end

					--------------------------------------------------------------------------------
					-- Clip copied from Browser:
					--------------------------------------------------------------------------------
					if xml['root']['kids'][2]['kids'][8]['kids'][30]['kids'][1]['value'] == "metadataImportToApp" then
						currentClipboardLabel = xml['root']['kids'][2]['kids'][8]['kids'][18]['kids'][1]['value']
					end

					--------------------------------------------------------------------------------
					-- Unknown item in clipboard:
					--------------------------------------------------------------------------------
					if currentClipboardLabel == nil then
						currentClipboardLabel = os.date()
					end

				--------------------------------------------------------------------------------
				-- Clean up temporary files:
				--------------------------------------------------------------------------------
				executeOutput, executeStatus, executeType, executeRC = hs.execute("rm " .. tostring(temporaryFileName))
				executeOutput, executeStatus, executeType, executeRC = hs.execute("rm " .. tostring(temporaryFileNameTwo))

				--------------------------------------------------------------------------------
				-- If all is good then...
				--------------------------------------------------------------------------------
				if addToClipboardHistory then

					local currentClipboardItem = {currentClipboardData, currentClipboardLabel}

					while (#clipboardHistory >= clipboardHistoryMaximumSize) do
						table.remove(clipboardHistory,1)
					end
					table.insert(clipboardHistory, currentClipboardItem)

					--------------------------------------------------------------------------------
					-- Update Settings:
					--------------------------------------------------------------------------------
					settings.set("fcpxHacks.clipboardHistory", clipboardHistory)

					--------------------------------------------------------------------------------
					-- Refresh Menubar:
					--------------------------------------------------------------------------------
					refreshMenuBar()

				end
		 	end
  			clipboardLastChange = clipboardCurrentChange
  		end

	end)
	clipboardTimer:start()

end

--------------------------------------------------------------------------------
-- FCPX SCROLLING TIMELINE WATCHER:
--------------------------------------------------------------------------------
function scrollingTimelineWatcher()

	--------------------------------------------------------------------------------
	-- Key Press Up Watcher:
	--------------------------------------------------------------------------------
	scrollingTimelineWatcherUp = hs.eventtap.new({ hs.eventtap.event.types.keyUp }, function(event)
		scrollingTimelineWatcherWorking = false
	end)

	--------------------------------------------------------------------------------
	-- Key Press Down Watcher:
	--------------------------------------------------------------------------------
	scrollingTimelineWatcherDown = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
		--------------------------------------------------------------------------------
		-- Don't repeat if key is held down:
		--------------------------------------------------------------------------------
		if scrollingTimelineWatcherWorking then
			return false
		else
			--------------------------------------------------------------------------------
			-- Prevent Key Being Held Down:
			--------------------------------------------------------------------------------
			scrollingTimelineWatcherWorking = true

			--------------------------------------------------------------------------------
			-- Spacebar Pressed:
			--------------------------------------------------------------------------------
			if event:getKeyCode() == 49 then
				--------------------------------------------------------------------------------
				-- Make sure the Command Editor is closed:
				--------------------------------------------------------------------------------
				if not isCommandEditorOpen then

					--------------------------------------------------------------------------------
					-- Toggle Scrolling Timeline Spacebar Pressed Variable:
					--------------------------------------------------------------------------------
					scrollingTimelineSpacebarPressed = not scrollingTimelineSpacebarPressed

					--------------------------------------------------------------------------------
					-- Either stop or start the Scrolling Timeline:
					--------------------------------------------------------------------------------
					if scrollingTimelineSpacebarPressed then
						scrollingTimelineSpacebarCheck = true
						hs.timer.waitUntil(function() return scrollingTimelineSpacebarCheck end, function() checkScrollingTimelinePress() end, 0.0000000000001)
					else
						if scrollingTimelineTimer ~= nil then scrollingTimelineTimer:stop() end
						if scrollingTimelineScrollbarTimer ~= nil then scrollingTimelineScrollbarTimer:stop() end
					end

				end
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- NOTIFICATION WATCHER:
--------------------------------------------------------------------------------
function notificationWatcher()

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
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                L E T ' S     D O     T H I S     T H I N G !               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

loadScript()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------