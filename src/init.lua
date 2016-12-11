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
--  USING SNIPPETS OF CODE FROM:
--------------------------------------------------------------------------------
--
--  > http://www.hammerspoon.org/go/
--  > https://github.com/Hammerspoon/hammerspoon/issues/272
--  > https://github.com/asmagill/hs._asm.axuielement
--  > https://github.com/Hammerspoon/hammerspoon/issues/1021#issuecomment-251827969
--  > https://github.com/Hammerspoon/hammerspoon/issues/1027#issuecomment-252024969
--
--------------------------------------------------------------------------------
--  HUGE SPECIAL THANKS TO THESE AMAZING DEVELOPERS FOR ALL THEIR HELP:
--------------------------------------------------------------------------------
--
--  > A-Ron (https://github.com/asmagill)
--  > Chris Jones (https://github.com/cmsj)
--  > Bill Cheeseman (http://pfiddlesoft.com)
--  > Yvan Koenig (http://macscripter.net/viewtopic.php?id=45148)
--  > Tim Webb (https://twitter.com/_timwebb_)
--
--------------------------------------------------------------------------------
--  VERY SPECIAL THANKS TO THESE AWESOME TESTERS & SUPPORTERS:
--------------------------------------------------------------------------------
--
--  > Андрей Смирнов
--  > FCPX Editors InSync Facebook Group
--  > Alex Gollner (http://alex4d.com)
--  > Scott Simmons (http://www.scottsimmons.tv)
--  > Isaac J. Terronez (https://twitter.com/ijterronez)
--  > Shahin Shokoui, Ilyas Akhmedov & Tim Webb
--
--------------------------------------------------------------------------------
--  FEATURE TO-DO LIST:
--------------------------------------------------------------------------------
--
--  > Shortcut to go to full screen mode.
--  > Move Storyline Up & Down Shortcut
--  > Add Audio Fade Handles Shortcut
--  > Select clip on Secondary Storyline Shortcut
--  > Transitions, Titles, Generators & Themes Shortcuts
--  > Remember Last Project & Layout when restarting FCPX
--  > Timeline Index HUD on Mouseover
--  > Watch Folders for Compressor
--  > Favourites folder for Effects, Transitions, Titles, Generators & Themes
--  > Clipboard History (https://github.com/victorso/.hammerspoon/blob/master/tools/clipboard.lua)
--  > Mouse Rewind History (as someone suggested on FCPX Grill)
--
--------------------------------------------------------------------------------
--  BUGS & ISSUES TO-DO LIST:
--------------------------------------------------------------------------------
--
--  > Rewrite bindKeyboardShortcuts() to use smarter loops and arrays.
--  > updateEffectsList() needs to be faster.
--  > translateKeyboardCharacters() could be done better.
--  > Work out a way to allow custom shortcuts for languages other than English.
--  > Scrolling Timeline should do some proper maths instead of bad guesses.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------





-------------------------------------------------------------------------------
-- SCRIPT VERSION:
-------------------------------------------------------------------------------
local scriptVersion = "0.37"
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
-- ENABLE DEVELOPMENT SHORTCUT (DISABLE BEFORE DISTRIBUTING):
--------------------------------------------------------------------------------
local enableDevelopmentShortcut = false
--------------------------------------------------------------------------------




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   T H E    M A I N    S C R I P T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- LOAD EXTENSIONS:
--------------------------------------------------------------------------------
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
ax 							= require("hs._asm.axuielement")

--------------------------------------------------------------------------------
-- LOCAL VARIABLES:
--------------------------------------------------------------------------------
local browserHighlight 		= nil
local browserHighlightTimer = nil
local clock 				= os.clock

--------------------------------------------------------------------------------
-- LOAD SCRIPT:
--------------------------------------------------------------------------------
function loadScript()

	--------------------------------------------------------------------------------
	-- Need Accessibility Activated:
	--------------------------------------------------------------------------------
	hs.accessibilityState(true)

	--------------------------------------------------------------------------------
	-- Clean the console to make it clean:
	--------------------------------------------------------------------------------
	hs.console.clearConsole()

	--------------------------------------------------------------------------------
	-- Display Welcome Message in the Console:
	--------------------------------------------------------------------------------
	print("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
	print("FCPX HACKS (Version " .. scriptVersion .. ")")
	print("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
	print("If you have any problems with this script, please email a screenshot")
	print("of your entire screen with this console open to:")
	print("")
	print("chris@latenitefilms.com")
	print("")
	print("Thanks for testing!")
	print("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
	print("")

	--------------------------------------------------------------------------------
	-- Is Final Cut Pro Installed:
	--------------------------------------------------------------------------------
	if isFinalCutProInstalled() then

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
		local settingsDebug15 = hs.settings.get("fcpxHacks.scrollingTimelineStatus") or ""
		local settingsDebug16 = hs.settings.get("fcpxHacks.scrollingTimelineOffget") or ""
		print("[FCPX Hacks] Settings: " .. tostring(settingsDebug1) .. ";" .. tostring(settingsDebug2) .. ";"  .. tostring(settingsDebug3) .. ";"  .. tostring(settingsDebug4) .. ";"  .. tostring(settingsDebug5) .. ";"  .. tostring(settingsDebug6) .. ";"  .. tostring(settingsDebug7) .. ";"  .. tostring(settingsDebug8) .. ";"  .. tostring(settingsDebug9) .. ";"  .. tostring(settingsDebug10) .. ";"  .. tostring(settingsDebug11) .. ";"  .. tostring(settingsDebug12) .. ";"  .. tostring(settingsDebug13) .. ";"  .. tostring(settingsDebug14) .. ";"  .. tostring(settingsDebug15) .. ";"  .. tostring(settingsDebug16) .. ".")

		--------------------------------------------------------------------------------
		-- Set Hotkey Console Messages To Warnings Only:
		--------------------------------------------------------------------------------
		hotkey.setLogLevel("warning")

		-------------------------------------------------------------------------------
		-- Common Error Messages:
		-------------------------------------------------------------------------------
		commonErrorMessageStart = "I'm sorry, but the following error has occurred:\n\n"
		commonErrorMessageEnd = "\n\nmacOS Version: " .. macOSVersion() .. "\nFCPX Version: " .. finalCutProVersion() .. "\nScript Version: " .. scriptVersion .. "\n\nPlease take a screenshot of your entire screen and email it to the below address so that we can try and come up with a fix:\n\nchris@latenitefilms.com\n\nThank you for testing!"
		commonErrorMessageAppleScript = 'set fcpxIcon to ((path to "apps" as Unicode text) & ("Final Cut Pro.app:Contents:Resources:Final Cut.icns" as Unicode text)) as alias\n\nset commonErrorMessageStart to "' .. commonErrorMessageStart .. '"\nset commonErrorMessageEnd to "' .. commonErrorMessageEnd .. '"\n'

		-------------------------------------------------------------------------------
		-- Check Final Cut Pro Version Compatibility:
		-------------------------------------------------------------------------------
		if finalCutProVersion() ~= "10.2.3" then
			hs.osascript.applescript(commonErrorMessageAppleScript .. [[
				display dialog ("Please be aware that this script has only been tested on Final Cut Pro 10.2.3 and MAY not work correctly on other versions.") buttons {"Ok"} with icon fcpxIcon
			]])
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
		-- Watch For Hammerspoon Script Updates:
		--------------------------------------------------------------------------------
		hammerspoonWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

		--------------------------------------------------------------------------------
		-- Watch for Final Cut Pro plist changes:
		--------------------------------------------------------------------------------
		preferencesWatcher = hs.pathwatcher.new("~/Library/Preferences/", finalCutProSettingsPlistChanged):start()

		--------------------------------------------------------------------------------
		-- Watch for Final Cut Pro Active Command Set changes:
		--------------------------------------------------------------------------------
		local activeCommandSet = getFinalCutProActiveCommandSet()
		if activeCommandSet ~= nil then
			activeCommandSetWatcher = hs.pathwatcher.new(activeCommandSet, finalCutProActiveCommandSetChanged):start()
		else
			print("[FCPX HACKS] ERROR: Wasn't able to retrieve the Active Command Set.")
		end

		--------------------------------------------------------------------------------
		-- Set up Menubar:
		--------------------------------------------------------------------------------
		fcpxMenubar = hs.menubar.newWithPriority(1)

		--------------------------------------------------------------------------------
		-- Work out Menubar Display Mode:
		--------------------------------------------------------------------------------
		updateMenubarIcon()

		--------------------------------------------------------------------------------
		-- Populate the Menubar for the first time:
		--------------------------------------------------------------------------------
		refreshMenuBar(true)

		--------------------------------------------------------------------------------
		-- Bind Keyboard Shortcuts:
		--------------------------------------------------------------------------------
		bindKeyboardShortcuts()

		--------------------------------------------------------------------------------
		-- Create and start the application event watcher:
		--------------------------------------------------------------------------------
		watcher = hs.application.watcher.new(finalCutProWatcher)
		watcher:start()

		--------------------------------------------------------------------------------
		-- Full Screen Keyboard Watcher:
		--------------------------------------------------------------------------------
		fullscreenKeyboardWatcher()

		--------------------------------------------------------------------------------
		-- Command Editor Watcher:
		--------------------------------------------------------------------------------
		commandEditorWatcher()

		--------------------------------------------------------------------------------
		-- Activate the correct modal state:
		--------------------------------------------------------------------------------
		if isFinalCutProFrontmost() then
			hotkeys:enter()
			if hs.settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback") == true then
				fullscreenKeyboardWatcherUp:start()
				fullscreenKeyboardWatcherDown:start()
			end
		else
			hotkeys:exit()
			fullscreenKeyboardWatcherUp:stop()
			fullscreenKeyboardWatcherDown:stop()
		end

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
	print(underMouse:path())
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

	if enableHacksShortcutsInFinalCutPro then
		--------------------------------------------------------------------------------
		-- Get Shortcut Keys from plist:
		--------------------------------------------------------------------------------
		finalCutProShortcutKey = nil
		finalCutProShortcutKey =
		{
			FCPXHackLaunchFinalCutPro 									= { characterString = "", modifiers = {} },
			FCPXHackShowListOfShortcutKeys 								= { characterString = "", modifiers = {} },
			FCPXHackHighlightBrowserPlayhead 							= { characterString = "", modifiers = {} },
			FCPXHackRevealInBrowserAndHighlight 						= { characterString = "", modifiers = {} },
			FCPXHackSingleMatchFrameAndHighlight 						= { characterString = "", modifiers = {} },
			FCPXHackRevealMulticamClipInBrowserAndHighlight 			= { characterString = "", modifiers = {} },
			FCPXHackRevealMulticamClipInAngleEditorAndHighlight 		= { characterString = "", modifiers = {} },
			FCPXHackBatchExportFromBrowser 								= { characterString = "", modifiers = {} },
			FCPXHackChangeBackupInterval 								= { characterString = "", modifiers = {} },
			FCPXHackToggleTimecodeOverlays 								= { characterString = "", modifiers = {} },
			FCPXHackToggleMovingMarkers 								= { characterString = "", modifiers = {} },
			FCPXHackAllowTasksDuringPlayback 							= { characterString = "", modifiers = {} },
			FCPXHackSelectColorBoardPuckOne 							= { characterString = "", modifiers = {} },
			FCPXHackSelectColorBoardPuckTwo 							= { characterString = "", modifiers = {} },
			FCPXHackSelectColorBoardPuckThree 							= { characterString = "", modifiers = {} },
			FCPXHackSelectColorBoardPuckFour 							= { characterString = "", modifiers = {} },
			FCPXHackRestoreKeywordPresetOne 							= { characterString = "", modifiers = {} },
			FCPXHackRestoreKeywordPresetTwo 							= { characterString = "", modifiers = {} },
			FCPXHackRestoreKeywordPresetThree 							= { characterString = "", modifiers = {} },
			FCPXHackRestoreKeywordPresetFour 							= { characterString = "", modifiers = {} },
			FCPXHackRestoreKeywordPresetFive 							= { characterString = "", modifiers = {} },
			FCPXHackRestoreKeywordPresetSix 							= { characterString = "", modifiers = {} },
			FCPXHackRestoreKeywordPresetSeven 							= { characterString = "", modifiers = {} },
			FCPXHackRestoreKeywordPresetEight 							= { characterString = "", modifiers = {} },
			FCPXHackRestoreKeywordPresetNine 							= { characterString = "", modifiers = {} },
			FCPXHackSaveKeywordPresetOne 								= { characterString = "", modifiers = {} },
			FCPXHackSaveKeywordPresetTwo 								= { characterString = "", modifiers = {} },
			FCPXHackSaveKeywordPresetThree 								= { characterString = "", modifiers = {} },
			FCPXHackSaveKeywordPresetFour 								= { characterString = "", modifiers = {} },
			FCPXHackSaveKeywordPresetFive 								= { characterString = "", modifiers = {} },
			FCPXHackSaveKeywordPresetSix 								= { characterString = "", modifiers = {} },
			FCPXHackSaveKeywordPresetSeven 								= { characterString = "", modifiers = {} },
			FCPXHackSaveKeywordPresetEight 								= { characterString = "", modifiers = {} },
			FCPXHackSaveKeywordPresetNine 								= { characterString = "", modifiers = {} },
			FCPXHackEffectsOne			 								= { characterString = "", modifiers = {} },
			FCPXHackEffectsTwo			 								= { characterString = "", modifiers = {} },
			FCPXHackEffectsThree			 							= { characterString = "", modifiers = {} },
			FCPXHackEffectsFour			 								= { characterString = "", modifiers = {} },
			FCPXHackEffectsFive			 								= { characterString = "", modifiers = {} },
			FCPXHackScrollingTimeline	 								= { characterString = "", modifiers = {} },
		}
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
			FCPXHackLaunchFinalCutPro 									= { characterString = keyCodeTranslator("l"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackShowListOfShortcutKeys 								= { characterString = keyCodeTranslator("f1"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackHighlightBrowserPlayhead 							= { characterString = keyCodeTranslator("h"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackRevealInBrowserAndHighlight 						= { characterString = keyCodeTranslator("f"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackSingleMatchFrameAndHighlight 						= { characterString = keyCodeTranslator("s"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackRevealMulticamClipInBrowserAndHighlight 			= { characterString = keyCodeTranslator("d"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackRevealMulticamClipInAngleEditorAndHighlight 		= { characterString = keyCodeTranslator("g"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackBatchExportFromBrowser 								= { characterString = keyCodeTranslator("e"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackChangeBackupInterval 								= { characterString = keyCodeTranslator("b"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackToggleTimecodeOverlays 								= { characterString = keyCodeTranslator("t"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackToggleMovingMarkers 								= { characterString = keyCodeTranslator("y"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackAllowTasksDuringPlayback 							= { characterString = keyCodeTranslator("p"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackSelectColorBoardPuckOne 							= { characterString = keyCodeTranslator("m"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackSelectColorBoardPuckTwo 							= { characterString = keyCodeTranslator(","), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackSelectColorBoardPuckThree 							= { characterString = keyCodeTranslator("."), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackSelectColorBoardPuckFour 							= { characterString = keyCodeTranslator("/"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackRestoreKeywordPresetOne 							= { characterString = keyCodeTranslator("1"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackRestoreKeywordPresetTwo 							= { characterString = keyCodeTranslator("2"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackRestoreKeywordPresetThree 							= { characterString = keyCodeTranslator("3"),		modifiers = {"ctrl", "option", "command"} },
			FCPXHackRestoreKeywordPresetFour 							= { characterString = keyCodeTranslator("4"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackRestoreKeywordPresetFive 							= { characterString = keyCodeTranslator("5"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackRestoreKeywordPresetSix 							= { characterString = keyCodeTranslator("6"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackRestoreKeywordPresetSeven 							= { characterString = keyCodeTranslator("7"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackRestoreKeywordPresetEight 							= { characterString = keyCodeTranslator("8"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackRestoreKeywordPresetNine 							= { characterString = keyCodeTranslator("9"), 		modifiers = {"ctrl", "option", "command"} },
			FCPXHackSaveKeywordPresetOne 								= { characterString = keyCodeTranslator("1"), 		modifiers = {"ctrl", "option", "command", "shift"} },
			FCPXHackSaveKeywordPresetTwo 								= { characterString = keyCodeTranslator("2"), 		modifiers = {"ctrl", "option", "command", "shift"} },
			FCPXHackSaveKeywordPresetThree 								= { characterString = keyCodeTranslator("3"), 		modifiers = {"ctrl", "option", "command", "shift"} },
			FCPXHackSaveKeywordPresetFour 								= { characterString = keyCodeTranslator("4"), 		modifiers = {"ctrl", "option", "command", "shift"} },
			FCPXHackSaveKeywordPresetFive 								= { characterString = keyCodeTranslator("5"), 		modifiers = {"ctrl", "option", "command", "shift"} },
			FCPXHackSaveKeywordPresetSix 								= { characterString = keyCodeTranslator("6"), 		modifiers = {"ctrl", "option", "command", "shift"} },
			FCPXHackSaveKeywordPresetSeven 								= { characterString = keyCodeTranslator("7"), 		modifiers = {"ctrl", "option", "command", "shift"} },
			FCPXHackSaveKeywordPresetEight 								= { characterString = keyCodeTranslator("8"), 		modifiers = {"ctrl", "option", "command", "shift"} },
			FCPXHackSaveKeywordPresetNine 								= { characterString = keyCodeTranslator("9"), 		modifiers = {"ctrl", "option", "command", "shift"} },
			FCPXHackEffectsOne			 								= { characterString = keyCodeTranslator("1"), 		modifiers = {"ctrl", "shift"} },
			FCPXHackEffectsTwo			 								= { characterString = keyCodeTranslator("2"), 		modifiers = {"ctrl", "shift"} },
			FCPXHackEffectsThree			 							= { characterString = keyCodeTranslator("3"), 		modifiers = {"ctrl", "shift"} },
			FCPXHackEffectsFour			 								= { characterString = keyCodeTranslator("4"), 		modifiers = {"ctrl", "shift"} },
			FCPXHackEffectsFive			 								= { characterString = keyCodeTranslator("5"), 		modifiers = {"ctrl", "shift"} },
			FCPXHackScrollingTimeline	 								= { characterString = keyCodeTranslator("w"), 		modifiers = {"ctrl", "option", "command"} },
		}
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
	--  Global Shortcut Keys:
	--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Launch Final Cut Pro:
		--------------------------------------------------------------------------------
		if finalCutProShortcutKey['FCPXHackLaunchFinalCutPro']['characterString'] ~= "" then
			hs.hotkey.bind(finalCutProShortcutKey['FCPXHackLaunchFinalCutPro']['modifiers'], finalCutProShortcutKey['FCPXHackLaunchFinalCutPro']['characterString'], function() hs.application.launchOrFocus("Final Cut Pro") end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackLaunchFinalCutPro keyboard shortcut.")
		end

		--------------------------------------------------------------------------------
		-- Used for development:
		--------------------------------------------------------------------------------
		if enableDevelopmentShortcut then
			hs.hotkey.bind({"ctrl", "option", "command"}, "q", function() testingGround() end)
		end

	--------------------------------------------------------------------------------
	-- Final Cut Pro Specific Shortcut Keys:
	--------------------------------------------------------------------------------

		--------------------------------------------------------------------------------
		-- Create a modal hotkey object with an absurd triggering hotkey:
		--------------------------------------------------------------------------------
		hotkeys = hs.hotkey.modal.new({"command", "shift", "alt", "control"}, "F19")

		--------------------------------------------------------------------------------
		-- Help:
		--------------------------------------------------------------------------------
		if finalCutProShortcutKey['FCPXHackShowListOfShortcutKeys']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackShowListOfShortcutKeys']['modifiers'], finalCutProShortcutKey['FCPXHackShowListOfShortcutKeys']['characterString'], function() displayShortcutList() end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackShowListOfShortcutKeys keyboard shortcut.")
		end

		--------------------------------------------------------------------------------
		-- Scrolling Timeline:
		--------------------------------------------------------------------------------
		if finalCutProShortcutKey['FCPXHackScrollingTimeline']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackScrollingTimeline']['modifiers'], finalCutProShortcutKey['FCPXHackScrollingTimeline']['characterString'], function() activateScrollingTimeline() end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackScrollingTimeline keyboard shortcut.")
		end

		--------------------------------------------------------------------------------
		-- Match Frame Commands:
		--------------------------------------------------------------------------------
		if finalCutProShortcutKey['FCPXHackHighlightBrowserPlayhead']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackHighlightBrowserPlayhead']['modifiers'], finalCutProShortcutKey['FCPXHackHighlightBrowserPlayhead']['characterString'], function() highlightFCPXBrowserPlayhead() end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackBatchExportFromBrowser keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackRevealInBrowserAndHighlight']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackRevealInBrowserAndHighlight']['modifiers'], finalCutProShortcutKey['FCPXHackRevealInBrowserAndHighlight']['characterString'], function() matchFrameThenHighlightFCPXBrowserPlayhead() end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRevealInBrowserAndHighlight keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackSingleMatchFrameAndHighlight']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSingleMatchFrameAndHighlight']['modifiers'], finalCutProShortcutKey['FCPXHackSingleMatchFrameAndHighlight']['characterString'], function() singleMatchFrame() end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRevealInBrowserAndHighlight keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackRevealMulticamClipInBrowserAndHighlight']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackRevealMulticamClipInBrowserAndHighlight']['modifiers'], finalCutProShortcutKey['FCPXHackRevealMulticamClipInBrowserAndHighlight']['characterString'], function() multicamMatchFrame(true) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRevealMulticamClipInBrowserAndHighlight keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackRevealMulticamClipInAngleEditorAndHighlight']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackRevealMulticamClipInAngleEditorAndHighlight']['modifiers'], finalCutProShortcutKey['FCPXHackRevealMulticamClipInAngleEditorAndHighlight']['characterString'], function() multicamMatchFrame(false) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRevealMulticamClipInAngleEditorAndHighlight keyboard shortcut.")
		end

		--------------------------------------------------------------------------------
		-- Export Tools:
		--------------------------------------------------------------------------------
		if finalCutProShortcutKey['FCPXHackBatchExportFromBrowser']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackBatchExportFromBrowser']['modifiers'], finalCutProShortcutKey['FCPXHackBatchExportFromBrowser']['characterString'], function() batchExportToCompressor() end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackBatchExportFromBrowser keyboard shortcut.")
		end

		--------------------------------------------------------------------------------
		-- Plist Modification Features:
		--------------------------------------------------------------------------------
		if finalCutProShortcutKey['FCPXHackChangeBackupInterval']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackChangeBackupInterval']['modifiers'], finalCutProShortcutKey['FCPXHackChangeBackupInterval']['characterString'], function() changeBackupInterval() end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackChangeBackupInterval keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackToggleTimecodeOverlays']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackToggleTimecodeOverlays']['modifiers'], finalCutProShortcutKey['FCPXHackToggleTimecodeOverlays']['characterString'], function() toggleTimecodeOverlay() end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackToggleTimecodeOverlays keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackToggleMovingMarkers']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackToggleMovingMarkers']['modifiers'], finalCutProShortcutKey['FCPXHackToggleMovingMarkers']['characterString'], function() toggleMovingMarkers() end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackToggleMovingMarkers keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackAllowTasksDuringPlayback']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackAllowTasksDuringPlayback']['modifiers'], finalCutProShortcutKey['FCPXHackAllowTasksDuringPlayback']['characterString'], function() togglePerformTasksDuringPlayback() end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackToggleMovingMarkers keyboard shortcut.")
		end

		--------------------------------------------------------------------------------
		-- Color Board Selectors:
		--------------------------------------------------------------------------------
		if finalCutProShortcutKey['FCPXHackSelectColorBoardPuckOne']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSelectColorBoardPuckOne']['modifiers'], finalCutProShortcutKey['FCPXHackSelectColorBoardPuckOne']['characterString'], function() colorBoardSelectPuck(2) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRestoreKeywordPresetOne keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackSelectColorBoardPuckTwo']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSelectColorBoardPuckTwo']['modifiers'], finalCutProShortcutKey['FCPXHackSelectColorBoardPuckTwo']['characterString'], function() colorBoardSelectPuck(3) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackSelectColorBoardPuckTwo keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackSelectColorBoardPuckThree']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSelectColorBoardPuckThree']['modifiers'], finalCutProShortcutKey['FCPXHackSelectColorBoardPuckThree']['characterString'], function() colorBoardSelectPuck(4) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackSelectColorBoardPuckThree keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackSelectColorBoardPuckFour']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSelectColorBoardPuckFour']['modifiers'], finalCutProShortcutKey['FCPXHackSelectColorBoardPuckFour']['characterString'], function() colorBoardSelectPuck(5) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackSelectColorBoardPuckThree keyboard shortcut.")
		end

		--------------------------------------------------------------------------------
		-- Restore Keyword Searches:
		--------------------------------------------------------------------------------
		if finalCutProShortcutKey['FCPXHackRestoreKeywordPresetOne']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackRestoreKeywordPresetOne']['modifiers'], finalCutProShortcutKey['FCPXHackRestoreKeywordPresetOne']['characterString'], function() fcpxRestoreKeywordSearches(1) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRestoreKeywordPresetOne keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackRestoreKeywordPresetTwo']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackRestoreKeywordPresetTwo']['modifiers'], finalCutProShortcutKey['FCPXHackRestoreKeywordPresetTwo']['characterString'], function() fcpxRestoreKeywordSearches(2) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRestoreKeywordPresetTwo keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackRestoreKeywordPresetThree']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackRestoreKeywordPresetThree']['modifiers'], finalCutProShortcutKey['FCPXHackRestoreKeywordPresetThree']['characterString'], function() fcpxRestoreKeywordSearches(3) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRestoreKeywordPresetThree keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackRestoreKeywordPresetFour']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackRestoreKeywordPresetFour']['modifiers'], finalCutProShortcutKey['FCPXHackRestoreKeywordPresetFour']['characterString'], function() fcpxRestoreKeywordSearches(4) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRestoreKeywordPresetFour keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackRestoreKeywordPresetFive']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackRestoreKeywordPresetFive']['modifiers'], finalCutProShortcutKey['FCPXHackRestoreKeywordPresetFive']['characterString'], function() fcpxRestoreKeywordSearches(5) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRestoreKeywordPresetFive keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackRestoreKeywordPresetSix']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackRestoreKeywordPresetSix']['modifiers'], finalCutProShortcutKey['FCPXHackRestoreKeywordPresetSix']['characterString'], function() fcpxRestoreKeywordSearches(6) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRestoreKeywordPresetSix keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackRestoreKeywordPresetSeven']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackRestoreKeywordPresetSeven']['modifiers'], finalCutProShortcutKey['FCPXHackRestoreKeywordPresetSeven']['characterString'], function() fcpxRestoreKeywordSearches(7) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRestoreKeywordPresetSeven keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackRestoreKeywordPresetEight']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackRestoreKeywordPresetEight']['modifiers'], finalCutProShortcutKey['FCPXHackRestoreKeywordPresetEight']['characterString'], function() fcpxRestoreKeywordSearches(8) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRestoreKeywordPresetEight keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackRestoreKeywordPresetNine']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackRestoreKeywordPresetNine']['modifiers'], finalCutProShortcutKey['FCPXHackRestoreKeywordPresetNine']['characterString'], function() fcpxRestoreKeywordSearches(9) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackRestoreKeywordPresetNine keyboard shortcut.")
		end

		--------------------------------------------------------------------------------
		-- Save Keyword Searches:
		--------------------------------------------------------------------------------
		if finalCutProShortcutKey['FCPXHackSaveKeywordPresetOne']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSaveKeywordPresetOne']['modifiers'], finalCutProShortcutKey['FCPXHackSaveKeywordPresetOne']['characterString'], function() fcpxSaveKeywordSearches(1) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackSaveKeywordPresetOne keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackSaveKeywordPresetTwo']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSaveKeywordPresetTwo']['modifiers'], finalCutProShortcutKey['FCPXHackSaveKeywordPresetTwo']['characterString'], function() fcpxSaveKeywordSearches(2) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackSaveKeywordPresetTwo keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackSaveKeywordPresetThree']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSaveKeywordPresetThree']['modifiers'], finalCutProShortcutKey['FCPXHackSaveKeywordPresetThree']['characterString'], function() fcpxSaveKeywordSearches(3) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackSaveKeywordPresetThree keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackSaveKeywordPresetFour']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSaveKeywordPresetFour']['modifiers'], finalCutProShortcutKey['FCPXHackSaveKeywordPresetFour']['characterString'], function() fcpxSaveKeywordSearches(4) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackSaveKeywordPresetFour keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackSaveKeywordPresetFive']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSaveKeywordPresetFive']['modifiers'], finalCutProShortcutKey['FCPXHackSaveKeywordPresetFive']['characterString'], function() fcpxSaveKeywordSearches(5) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackSaveKeywordPresetFive keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackSaveKeywordPresetSix']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSaveKeywordPresetSix']['modifiers'], finalCutProShortcutKey['FCPXHackSaveKeywordPresetSix']['characterString'], function() fcpxSaveKeywordSearches(6) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackSaveKeywordPresetSix keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackSaveKeywordPresetSeven']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSaveKeywordPresetSeven']['modifiers'], finalCutProShortcutKey['FCPXHackSaveKeywordPresetSeven']['characterString'], function() fcpxSaveKeywordSearches(7) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackSaveKeywordPresetSeven keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackSaveKeywordPresetEight']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSaveKeywordPresetEight']['modifiers'], finalCutProShortcutKey['FCPXHackSaveKeywordPresetEight']['characterString'], function() fcpxSaveKeywordSearches(8) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackSaveKeywordPresetEight keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackSaveKeywordPresetNine']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackSaveKeywordPresetNine']['modifiers'], finalCutProShortcutKey['FCPXHackSaveKeywordPresetNine']['characterString'], function() fcpxSaveKeywordSearches(9) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackSaveKeywordPresetNine keyboard shortcut.")
		end

		--------------------------------------------------------------------------------
		-- Effects Shortcuts:
		--------------------------------------------------------------------------------
		if finalCutProShortcutKey['FCPXHackEffectsOne']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackEffectsOne']['modifiers'], finalCutProShortcutKey['FCPXHackEffectsOne']['characterString'], function() effectsShortcut(1) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackEffectsOne keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackEffectsTwo']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackEffectsTwo']['modifiers'], finalCutProShortcutKey['FCPXHackEffectsTwo']['characterString'], function() effectsShortcut(2) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackEffectsTwo keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackEffectsThree']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackEffectsThree']['modifiers'], finalCutProShortcutKey['FCPXHackEffectsThree']['characterString'], function() effectsShortcut(3) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackEffectsThree keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackEffectsFour']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackEffectsFour']['modifiers'], finalCutProShortcutKey['FCPXHackEffectsFour']['characterString'], function() effectsShortcut(4) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackEffectsFour keyboard shortcut.")
		end
		if finalCutProShortcutKey['FCPXHackEffectsFive']['characterString'] ~= "" then
			hotkeys:bind(finalCutProShortcutKey['FCPXHackEffectsFive']['modifiers'], finalCutProShortcutKey['FCPXHackEffectsFive']['characterString'], function() effectsShortcut(5) end)
		else
			print("[FCPX Hacks] WARNING: Failed to load FCPXHackEffectsFive keyboard shortcut.")
		end

	--------------------------------------------------------------------------------
	-- Enable Hotkeys!
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
		allowMovingMarkers = false
		local executeResult,executeStatus = hs.execute("/usr/libexec/PlistBuddy -c \"Print :TLKMarkerHandler:Configuration:'Allow Moving Markers'\" '/Applications/Final Cut Pro.app/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist'")
		if trim(executeResult) == "true" then allowMovingMarkers = true end

		--------------------------------------------------------------------------------
		-- Get plist values for FFPeriodicBackupInterval:
		--------------------------------------------------------------------------------
		FFPeriodicBackupInterval = "15"
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFPeriodicBackupInterval")
		if trim(executeResult) ~= "" then FFPeriodicBackupInterval = executeResult end

		--------------------------------------------------------------------------------
		-- Get plist values for FFSuspendBGOpsDuringPlay:
		--------------------------------------------------------------------------------
		FFSuspendBGOpsDuringPlay = false
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFSuspendBGOpsDuringPlay")
		if trim(executeResult) == "1" then FFSuspendBGOpsDuringPlay = true end

		--------------------------------------------------------------------------------
		-- Get plist values for FFEnableGuards:
		--------------------------------------------------------------------------------
		FFEnableGuards = false
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFEnableGuards")
		if trim(executeResult) == "1" then FFEnableGuards = true end

		--------------------------------------------------------------------------------
		-- Get plist values for FFImportCreateOptimizeMedia:
		--------------------------------------------------------------------------------
		FFCreateOptimizedMediaForMulticamClips = true
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFCreateOptimizedMediaForMulticamClips")
		if trim(executeResult) == "0" then FFCreateOptimizedMediaForMulticamClips = false end

		--------------------------------------------------------------------------------
		-- Get plist values for FFAutoStartBGRender:
		--------------------------------------------------------------------------------
		FFAutoStartBGRender = true
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFAutoStartBGRender")
		if trim(executeResult) == "0" then FFAutoStartBGRender = false end

		--------------------------------------------------------------------------------
		-- Get plist values for FFAutoRenderDelay:
		--------------------------------------------------------------------------------
		FFAutoRenderDelay = "0.3"
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFAutoRenderDelay")
		if executeStatus == true then FFAutoRenderDelay = trim(executeResult) end

		--------------------------------------------------------------------------------
		-- Get plist values for FFAutoStartBGRender:
		--------------------------------------------------------------------------------
		FFImportCopyToMediaFolder = true
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFImportCopyToMediaFolder")
		if trim(executeResult) == "0" then FFImportCopyToMediaFolder = false end

		--------------------------------------------------------------------------------
		-- Get plist values for FFImportCreateOptimizeMedia:
		--------------------------------------------------------------------------------
		FFImportCreateOptimizeMedia = false
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFImportCreateOptimizeMedia")
		if trim(executeResult) == "1" then FFImportCreateOptimizeMedia = true end

		--------------------------------------------------------------------------------
		-- Get plist values for FFImportCreateProxyMedia:
		--------------------------------------------------------------------------------
		local FFImportCreateProxyMedia = false
		local executeResult,executeStatus = hs.execute("defaults read ~/Library/Preferences/com.apple.FinalCut.plist FFImportCreateProxyMedia")
		if trim(executeResult) == "1" then FFImportCreateProxyMedia = true end

	end

	--------------------------------------------------------------------------------
	-- Get Menubar Display Mode from Settings:
	--------------------------------------------------------------------------------
	local displayMenubarAsIcon = nil
	displayMenubarAsIcon = hs.settings.get("fcpxHacks.displayMenubarAsIcon")
	if displayMenubarAsIcon == nil then displayMenubarAsIcon = false end

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
	local enableShortcutsDuringFullscreenPlayback = hs.settings.get("fcpxHacks.enableShortcutsDuringFullscreenPlayback")
	if enableShortcutsDuringFullscreenPlayback == nil then enableShortcutsDuringFullscreenPlayback = false end

	--------------------------------------------------------------------------------
	-- Get Enable Hacks Shortcuts in Final Cut Pro from Settings:
	--------------------------------------------------------------------------------
	local enableHacksShortcutsInFinalCutPro = hs.settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro")
	if enableHacksShortcutsInFinalCutPro == nil then enableHacksShortcutsInFinalCutPro = false end

	--------------------------------------------------------------------------------
	-- Get Effects List Updated from Settings:
	--------------------------------------------------------------------------------
	effectsListUpdated = hs.settings.get("fcpxHacks.effectsListUpdated")
	if effectsListUpdated == nil then effectsListUpdated = false end

	--------------------------------------------------------------------------------
	-- Get Enable Proxy Menu Item:
	--------------------------------------------------------------------------------
	local enableProxyMenuIcon = hs.settings.get("fcpxHacks.enableProxyMenuIcon")
	if enableProxyMenuIcon == nil then enableProxyMenuIcon = false end

	--------------------------------------------------------------------------------
	-- Hammerspoon Settings:
	--------------------------------------------------------------------------------
	local startHammerspoonOnLaunch = hs.autoLaunch()
	local hammerspoonCheckForUpdates = hs.automaticallyCheckForUpdates()
	local hammerspoonDockIcon = hs.dockIcon()
	local hammerspoonMenuIcon = hs.menuIcon()

	--------------------------------------------------------------------------------
	-- Setup Menu:
	--------------------------------------------------------------------------------
	local settingsShapeMenuTable = {
	   	{ title = "Rectangle", 	fn = changeHighlightShapeRectangle,	checked = displayHighlightShapeRectangle	},
	   	{ title = "Circle", 	fn = changeHighlightShapeCircle, 	checked = displayHighlightShapeCircle		},
	   	{ title = "Diamond", 	fn = changeHighlightShapeDiamond, 	checked = displayHighlightShapeDiamond		},
	}
	local settingsColourMenuTable = {
	   	{ title = "Red", 	fn = changeHighlightColourRed, 		checked = displayHighlightColourRed		},
	   	{ title = "Blue", 	fn = changeHighlightColourBlue, 	checked = displayHighlightColourBlue	},
	   	{ title = "Green", 	fn = changeHighlightColourGreen, 	checked = displayHighlightColourGreen	},
	   	{ title = "Yellow", fn = changeHighlightColourYellow, 	checked = displayHighlightColourYellow	},
	}
	local settingsHammerspoonSettings = {
		{ title = "Console...", fn = openHammerspoonConsole },
		{ title = "-" },
		{ title = "-" },
		{ title = "Show Dock Icon", 	fn = toggleHammerspoonDockIcon, 			checked = hammerspoonDockIcon		},
		{ title = "Show Menu Icon", 	fn = toggleHammerspoonMenuIcon, 			checked = hammerspoonMenuIcon		},
		{ title = "-" },
	   	{ title = "Launch at Startup", 	fn = toggleLaunchHammerspoonOnStartup, 		checked = startHammerspoonOnLaunch		},
	   	{ title = "Check for Updates", 	fn = toggleCheckforHammerspoonUpdates, 		checked = hammerspoonCheckForUpdates	},
	}
	local settingsMenuTable = {
		{ title = "Enable Hacks Shortcuts in Final Cut Pro", fn = toggleEnableHacksShortcutsInFinalCutPro, checked = enableHacksShortcutsInFinalCutPro},
	   	{ title = "Enable Shortcuts During Fullscreen Playback", fn = toggleEnableShortcutsDuringFullscreenPlayback, checked = enableShortcutsDuringFullscreenPlayback},
	   	{ title = "-" },
	   	{ title = "Adjust Scrolling Timeline Offset", fn = adjustScrollingTimelineOffset },
	   	{ title = "-" },
	   	{ title = "Highlight Playhead Colour", menu = settingsColourMenuTable},
	   	{ title = "Highlight Playhead Shape", menu = settingsShapeMenuTable},
       	{ title = "-" },
	   	{ title = "Display Proxy/Original Icon", fn = toggleEnableProxyMenuIcon, checked = enableProxyMenuIcon},
	   	{ title = "Display This Menu As Icon", fn = toggleMenubarDisplayMode, checked = displayMenubarAsIcon},
      	{ title = "-" },
		{ title = "Factory Reset FCPX Hacks", 	fn = resetSettings },
	}
	local settingsEffectsShortcutsTable = {
		{ title = "Update Effects List", 	fn = updateEffectsList, disabled = not fcpxActive },
		{ title = "-" },
		{ title = "Assign Effects Shortcut 1", 	fn = assignEffectsShortcutOne, disabled = not effectsListUpdated },
		{ title = "Assign Effects Shortcut 2", 	fn = assignEffectsShortcutTwo, disabled = not effectsListUpdated },
		{ title = "Assign Effects Shortcut 3", 	fn = assignEffectsShortcutThree, disabled = not effectsListUpdated },
		{ title = "Assign Effects Shortcut 4", 	fn = assignEffectsShortcutFour, disabled = not effectsListUpdated },
		{ title = "Assign Effects Shortcut 5", 	fn = assignEffectsShortcutFive, disabled = not effectsListUpdated },
	}
	local menuTable = {
	   	{ title = "Launch Final Cut Pro", fn = launchFinalCutPro, disabled = fcpxActive},

		{ title = "-" },
	   	{ title = "Show Keyboard Shortcuts", fn = displayShortcutList },
	    { title = "-" },
	    { title = "Background Render (" .. FFAutoRenderDelay .. " secs)", fn = toggleBackgroundRender, disabled = not fcpxActive, checked = FFAutoStartBGRender },
   	    { title = "-" },
	    { title = "Leave In Place On Import", fn = toggleLeaveInPlace, disabled = not fcpxActive, checked = not FFImportCopyToMediaFolder },
	    { title = "Create Optimized Media", fn = toggleCreateOptimizedMedia, disabled = not fcpxActive, checked = FFImportCreateOptimizeMedia },
	    { title = "Create Multicam Optimized Media", fn = toggleCreateMulticamOptimizedMedia, disabled = not fcpxActive, checked = FFCreateOptimizedMediaForMulticamClips },
	    { title = "Create Proxy Media", fn = toggleCreateProxyMedia, disabled = not fcpxActive, checked = FFImportCreateProxyMedia },
   	    { title = "-" },
   	   	{ title = "Change Backup Interval (" .. tostring(FFPeriodicBackupInterval) .. " mins)", fn = changeBackupInterval },
   	    { title = "-" },
	   	{ title = "Enable Timecode Overlay", fn = toggleTimecodeOverlay, checked = FFEnableGuards },
	   	{ title = "Enable Moving Markers", fn = toggleMovingMarkers, checked = allowMovingMarkers },
       	{ title = "Allow Tasks During Playback", fn = togglePerformTasksDuringPlayback, checked = FFSuspendBGOpsDuringPlay },
      	{ title = "-" },
      	{ title = "Effects Shortcuts", menu = settingsEffectsShortcutsTable },
        { title = "-" },
      	{ title = "FCPX Hacks Settings", menu = settingsMenuTable },
      	{ title = "Hammerspoon Settings", menu = settingsHammerspoonSettings},
    	{ title = "-" },
    	{ title = "Quit FCPX Hacks", fn = quitFCPXHacks},
    	{ title = "-" },
  	    { title = "Script Version " .. scriptVersion, disabled = true },
  	    { title = "Thrown Together by LateNite Films", disabled = true },
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
-- ADJUST SCROLLING TIMELINE OFFSET:
--------------------------------------------------------------------------------
function adjustScrollingTimelineOffset()

	local scrollingTimelineOffset
	if hs.settings.get("fcpxHacks.scrollingTimelineOffset") == nil then
		scrollingTimelineOffset = "1"
	else
		scrollingTimelineOffset = hs.settings.get("fcpxHacks.scrollingTimelineOffset")
	end

	local scrollingTimelineOffsetSelection = displaySmallNumberTextBoxMessage("Please enter a number below as the Scrolling Timeline Offset.\n\nThis number should be above zero but below 1 or 2. If the timeline is going too fast, try a value like 0.02. If the timeline is going too slow, try a value like 1.1. If you want no off-set applied, then enter 1.\n\nYou'll have to experiment! Good luck!", "What you entered looks incorrect.\n\nPlease try again.", scrollingTimelineOffset)
	if scrollingTimelineOffsetSelection ~= false then
		hs.settings.set("fcpxHacks.scrollingTimelineOffset", scrollingTimelineOffsetSelection)
	end

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
P = Toggle Allow Tasks during Playback

M = Select Color Board Puck 1
, = Select Color Board Puck 2
. = Select Color Board Puck 3
/ = Select Color Board Puck 4
1-9 = Restore Keyword Preset

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
-- RESET SETTINGS:
--------------------------------------------------------------------------------
function resetSettings()

	local enableHacksShortcutsInFinalCutPro = hs.settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro")
	local resetMessage = "Are you sure you want to factory reset FCPX Hacks?"

	if enableHacksShortcutsInFinalCutPro ~= nil then
		if enableHacksShortcutsInFinalCutPro then
			resetMessage = resetMessage .. "\n\nAs you have Hacks Shortcuts enabled, you will need to enter your Administrator password to reset these shortcuts."
		end
	end

	if displayYesNoQuestion(resetMessage) then

		--------------------------------------------------------------------------------
		-- Remove Hacks Shortcuts:
		--------------------------------------------------------------------------------

		local removeHacksResult = true
		if enableHacksShortcutsInFinalCutPro ~= nil then
			if enableHacksShortcutsInFinalCutPro then
				--------------------------------------------------------------------------------
				-- Disable Hacks Shortcut in Final Cut Pro:
				--------------------------------------------------------------------------------
				local appleScriptA = [[
					--------------------------------------------------------------------------------
					-- Replace Files:
					--------------------------------------------------------------------------------
					try
						tell me to activate
						do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist.BACKUP2' '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist'" with administrator privileges
					on error
						return "Failed"
					end try
					try
						do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommands.plist.BACKUP2' '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommands.plist'" with administrator privileges
					on error
						return "Failed"
					end try
					try
						do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset.BACKUP2' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset'" with administrator privileges
					on error
						return "Failed"
					end try
					try
						do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings.BACKUP2' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings'" with administrator privileges
					on error
						return "Failed"
					end try
					try
						do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings.BACKUP2' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings'" with administrator privileges
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
			end
		end

		if removeHacksResult then

			--------------------------------------------------------------------------------
			-- Trash settings:
			--------------------------------------------------------------------------------
			hs.settings.set("fcpxHacks.effectsShortcutThree", nil)
			hs.settings.set("fcpxHacks.enableHacksShortcutsInFinalCutPro", nil)
			hs.settings.set("fcpxHacks.allEffects", nil)
			hs.settings.set("fcpxHacks.enableShortcutsDuringFullscreenPlayback", nil)
			hs.settings.set("fcpxHacks.effectsListUpdated", nil)
			hs.settings.set("fcpxHacks.displayHighlightShape", nil)
			hs.settings.set("fcpxHacks.displayHighlightColour", nil)
			hs.settings.set("fcpxHacks.displayMenubarAsIcon", nil)
			hs.settings.set("fcpxHacks.effectsShortcutOne", nil)
			hs.settings.set("fcpxHacks.effectsShortcutTwo", nil)
			hs.settings.set("fcpxHacks.effectsShortcutThree", nil)
			hs.settings.set("fcpxHacks.effectsShortcutFour", nil)
			hs.settings.set("fcpxHacks.effectsShortcutFive", nil)
			hs.settings.set("fcpxHacks.enableProxyMenuIcon", nil)
			hs.settings.set("fcpxHacks.scrollingTimelineStatus", nil)
			hs.settings.set("fcpxHacks.scrollingTimelineOffset", nil)

			--------------------------------------------------------------------------------
			-- Reload Hammerspoon:
			--------------------------------------------------------------------------------
			hs.reload()

		end

	end

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
function assignEffectsShortcutOne() 	assignEffectsShortcut(1) end
function assignEffectsShortcutTwo() 	assignEffectsShortcut(2) end
function assignEffectsShortcutThree() 	assignEffectsShortcut(3) end
function assignEffectsShortcutFour() 	assignEffectsShortcut(4) end
function assignEffectsShortcutFive() 	assignEffectsShortcut(5) end
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

	local displayMenubarAsIcon = hs.settings.get("fcpxHacks.displayMenubarAsIcon")
	local enableProxyMenuIcon = hs.settings.get("fcpxHacks.enableProxyMenuIcon")
	local proxyMenuIcon = ""

	if enableProxyMenuIcon ~= nil then
		if enableProxyMenuIcon == true then
			if getProxyStatusIcon() ~= nil then
				proxyMenuIcon = " " .. getProxyStatusIcon()
			else
				proxyMenuIcon = ""
			end
		end
	end

	if displayMenubarAsIcon == nil then
		fcpxMenubar:setTitle("FCPX Hacks" .. proxyMenuIcon)
	else
		if displayMenubarAsIcon then
			fcpxMenubar:setTitle("🎬" .. proxyMenuIcon)
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
	-- Check Keyboard Layout before we begin:
	--------------------------------------------------------------------------------
	if hs.keycodes.currentLayout() ~= nil then
		local currentKeyboardLayout = hs.keycodes.currentLayout()
		local supportedKeyboardLayout = false
		if currentKeyboardLayout == "ABC" then supportedKeyboardLayout = true end
		if currentKeyboardLayout == "ABC Extended" then supportedKeyboardLayout = true end
		if currentKeyboardLayout == "Australian" then supportedKeyboardLayout = true end
		if currentKeyboardLayout == "British" then supportedKeyboardLayout = true end
		if currentKeyboardLayout == "British - PC" then supportedKeyboardLayout = true end
		if currentKeyboardLayout == "Canadian English" then supportedKeyboardLayout = true end
		if currentKeyboardLayout == "Colemak" then supportedKeyboardLayout = true end
		if currentKeyboardLayout == "Dvorak" then supportedKeyboardLayout = true end
		if currentKeyboardLayout == "Dvorak - Left" then supportedKeyboardLayout = true end
		if currentKeyboardLayout == "Dvorak - Qwerty ⌘" then supportedKeyboardLayout = true end
		if currentKeyboardLayout == "Dvorak - Right" then supportedKeyboardLayout = true end
		if currentKeyboardLayout == "Irish" then supportedKeyboardLayout = true end
		if currentKeyboardLayout == "U.S." then supportedKeyboardLayout = true end
		if currentKeyboardLayout == "U.S. International - PC" then supportedKeyboardLayout = true end
		if supportedKeyboardLayout == false then
			displayMessage("I'm sorry, but your current keyboard layout (" .. tostring(currentKeyboardLayout) .. ") isn't supported by this feature.\n\nTo use this feature, you'll need to use a Standard English keyboard layout.\n\nIf this is not possible, please email the below address to request support for your preferred keyboard layout:\n\nchris@latenitefilms.com")
			return "Failed"
		end
	end

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
		-- Disable Hacks Shortcut in Final Cut Pro:
		--------------------------------------------------------------------------------
		local appleScriptA = [[
			--------------------------------------------------------------------------------
			-- Replace Files:
			--------------------------------------------------------------------------------
			try
				tell me to activate
				do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist.BACKUP' '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to restore NSProCommandGroups.plist." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommands.plist.BACKUP' '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommands.plist'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to restore NSProCommands.plist." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset.BACKUP' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to restore Default.commandset." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings.BACKUP' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to restore NSProCommandDescriptions.strings." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings.BACKUP' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings'" with administrator privileges
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
		-- Enable Hacks Shortcut in Final Cut Pro:
		--------------------------------------------------------------------------------
		local appleScriptA = [[
			--------------------------------------------------------------------------------
			-- Backup Existing Files:
			--------------------------------------------------------------------------------
			try
				tell me to activate
				do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist' '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist.BACKUP'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to backup NSProCommandGroups.plist." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist' '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist.BACKUP2'" with administrator privileges
			on error
				-- do nothing
			end try


			try
				do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommands.plist' '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommands.plist.BACKUP'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to backup NSProCommands.plist." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommands.plist' '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommands.plist.BACKUP2'" with administrator privileges
			on error
				-- do nothing
			end try


			try
				do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset.BACKUP'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to backup Default.commandset." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset.BACKUP2'" with administrator privileges
			on error
				-- do nothing
			end try


			try
				do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings.BACKUP'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to backup NSProCommandDescriptions.strings." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings.BACKUP2'" with administrator privileges
			on error
				-- do nothing
			end try


			try
				do shell script "cp -f '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings.BACKUP'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to backup NSProCommandNames.strings." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings' '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings.BACKUP2'" with administrator privileges
			on error
				-- do nothing
			end try


			--------------------------------------------------------------------------------
			-- Replace Files:
			--------------------------------------------------------------------------------
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/NSProCommandGroups.plist '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to replace NSProCommandGroups.plist." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/NSProCommands.plist '/Applications/Final Cut Pro.app/Contents/Resources/NSProCommands.plist'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to replace NSProCommands.plist." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/en.lproj/Default.commandset '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/Default.commandset'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to replace Default.commandset." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/en.lproj/NSProCommandDescriptions.strings '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings'" with administrator privileges
			on error
				display dialog commonErrorMessageStart & "Failed to replace NSProCommandDescriptions.strings." & commonErrorMessageEnd buttons {"Close"} with icon caution
				return "Failed"
			end try
			try
				do shell script "cp -f ~/.hammerspoon/hs/fcpx/en.lproj/NSProCommandNames.strings '/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings'" with administrator privileges
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
-- CHANGE HIGHLIGHT SHAPE:
--------------------------------------------------------------------------------
function changeHighlightShapeRectangle()
	hs.settings.set("fcpxHacks.displayHighlightShape", "Rectangle")
	refreshMenuBar()
end
function changeHighlightShapeCircle()
	hs.settings.set("fcpxHacks.displayHighlightShape", "Circle")
	refreshMenuBar()
end
function changeHighlightShapeDiamond()
	hs.settings.set("fcpxHacks.displayHighlightShape", "Diamond")
	refreshMenuBar()
end

--------------------------------------------------------------------------------
-- CHANGE HIGHLIGHT COLOUR:
--------------------------------------------------------------------------------
function changeHighlightColourRed()
	hs.settings.set("fcpxHacks.displayHighlightColour", "Red")
	refreshMenuBar()
end
function changeHighlightColourBlue()
	hs.settings.set("fcpxHacks.displayHighlightColour", "Blue")
	refreshMenuBar()
end
function changeHighlightColourGreen()
	hs.settings.set("fcpxHacks.displayHighlightColour", "Green")
	refreshMenuBar()
end
function changeHighlightColourYellow()
	hs.settings.set("fcpxHacks.displayHighlightColour", "Yellow")
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
function toggleCreateMulticamOptimizedMedia()

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
function toggleCreateProxyMedia()

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
function toggleCreateOptimizedMedia()

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
function toggleLeaveInPlace()

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
function toggleBackgroundRender()

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
		if displayYesNoQuestion("Changing the Backup Interval requires Final Cut Pro to restart. Are you happy to restart Final Cut Pro now?") then
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
		if displayYesNoQuestion("Toggling Moving Markers requires Final Cut Pro to restart. Are you happy to restart Final Cut Pro now?") then
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
		if displayYesNoQuestion("Toggling the ability to perform Background Tasks during playback requires Final Cut Pro to restart. Are you happy to restart Final Cut Pro now?") then
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
		if displayYesNoQuestion("Toggling Timecode Overlays requires Final Cut Pro to restart. Are you happy to restart Final Cut Pro now?") then
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
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   S H O R T C U T   F E A T U R E S                        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ACTIVE SCROLLING TIMELINE WATCHER:
--------------------------------------------------------------------------------
function activateScrollingTimeline()

	--------------------------------------------------------------------------------
	-- Setup Scrolling Timeline Watcher:
	--------------------------------------------------------------------------------
	if scrollingTimelineWatcherUp == nil then scrollingTimelineWatcher() end

	--------------------------------------------------------------------------------
	-- Toggle Scrolling Timeline Watcher:
	--------------------------------------------------------------------------------
	if scrollingTimelineWatcherUp:isEnabled() then
		hs.settings.set("fcpxHacks.scrollingTimelineStatus", false)
		scrollingTimelineWatcherUp:stop()
		scrollingTimelineWatcherDown:stop()
		hs.alert.show("Scrolling Timeline Deactivated")
	else
		hs.settings.set("fcpxHacks.scrollingTimelineStatus", true)
		scrollingTimelineWatcherUp:start()
		scrollingTimelineWatcherDown:start()
		hs.alert.show("Scrolling Timeline Activated")
	end

end

--------------------------------------------------------------------------------
-- SCROLLING TIMELINE FUNCTION:
--------------------------------------------------------------------------------
function performScrollingTimeline()

	if not scrollingTimelineActivated then return end

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	fcpx = hs.application("Final Cut Pro")

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
				goto performScrollingTimelineSplitGroupExit
			end
		end
	end
	if whichSplitGroup == nil then
		displayErrorMessage("Unable to locate Split Group.")
		return "Failed"
	end
	::performScrollingTimelineSplitGroupExit::

	--------------------------------------------------------------------------------
	-- Which Group:
	--------------------------------------------------------------------------------
	local whichGroup = nil
	for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
		if whichGroup == nil then
			if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1] ~= nil then
				if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1]:attributeValue("AXRole") == "AXSplitGroup" then
					if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1]:attributeValue("AXIdentifier") == "_NS:11" then
						whichGroup = i
						goto performScrollingTimelineGroupExit
					end
				end
			end
		end
	end
	if whichGroup == nil then
		displayErrorMessage("Unable to locate Group.")
		return "Failed"
	end
	::performScrollingTimelineGroupExit::

	--------------------------------------------------------------------------------
	-- Which Zoom Slider:
	--------------------------------------------------------------------------------
	local whichZoomSlider = nil
	for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i]:attributeValue("AXHelp") == "Adjust the Timeline zoom level" then
			whichZoomSlider = i
			goto performScrollingTimelineZoomSliderExit
		end
	end
	if whichZoomSlider == nil then
		displayErrorMessage("Unable to locate Zoom Slider.")
		return "Failed"
	end
	::performScrollingTimelineZoomSliderExit::

	--------------------------------------------------------------------------------
	-- TIMELINE PLAYHEAD PATH:
	-- 	Which Split Group = 1
	-- 	Which Scroll Area = 2
	-- 	Which Layout Area = 1
	-- 	Which Value Indicator = 2
	--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- TIMELINE SCROLLBAR PATH:
	-- 	Which Split Group = 1
	-- 	Which Scroll Area = 2
	-- 	Which Scroll Bar = 2
	-- 	Which Value Indicator = 1
	--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- Check mouse is in timeline area:
	--------------------------------------------------------------------------------
	local mouseLocation = hs.mouse.getAbsolutePosition()
	local timelinePosition = fcpxElements[whichSplitGroup][whichGroup][1][2]:attributeValue("AXPosition")
	local timelineSize = fcpxElements[whichSplitGroup][whichGroup][1][2]:attributeValue("AXSize")

	local isMouseInTimelineArea = true
	if (mouseLocation['y'] < timelinePosition['y']) then
		-- Too High:
		isMouseInTimelineArea = false
	end
	if (mouseLocation['y'] > (timelinePosition['y']+timelineSize['h'])) then
		-- Too Low:
		isMouseInTimelineArea = false
	end
	if (mouseLocation['x'] < timelinePosition['x']) then
		-- Too Left:
		isMouseInTimelineArea = false
	end
	if (mouseLocation['x'] > (timelinePosition['x']+timelineSize['w'])) then
		-- Too Right:
		isMouseInTimelineArea = false
	end

	if not isMouseInTimelineArea then
		return false
	end

	--------------------------------------------------------------------------------
	-- Zoom Slider Value:
	--------------------------------------------------------------------------------
	local zoomSliderValue = fcpxElements[whichSplitGroup][whichZoomSlider]:attributeValue("AXValue") -- 0 to 10

	--------------------------------------------------------------------------------
	-- Timeline is full width so there's no scroll bar!
	--------------------------------------------------------------------------------
	if zoomSliderValue == 0 then return end

	--------------------------------------------------------------------------------
	-- Get UI Values:
	--------------------------------------------------------------------------------
    local timelineScrollbar = fcpxElements[whichSplitGroup][whichGroup][1][2][2][1]
	local timelinePlayhead = fcpxElements[whichSplitGroup][whichGroup][1][2][1][2]
    local initialTimelinePlayheadXPosition = timelinePlayhead:attributeValue("AXPosition")['x']
	local initialTimelineScrollbarValue = timelineScrollbar:attributeValue("AXValue")

	--------------------------------------------------------------------------------
	-- Because I'm not smart enough to do maths I'll do this manually...
	--------------------------------------------------------------------------------
	-- ZOOM: 				1 to 10
	-- SCROLL BAR: 			0 to 1

	local manualAdjustmentValue
	if zoomSliderValue > 0 and zoomSliderValue < 1 then
		--print("0 to 1")
		manualAdjustmentValue = 0.000005
	end
	if zoomSliderValue > 1 and zoomSliderValue < 2 then
		--print("1 to 2")
		manualAdjustmentValue = 0.000005
	end
	if zoomSliderValue > 2 and zoomSliderValue < 3 then
		--print("2 to 3")
		manualAdjustmentValue = 0.000005
	end
	if zoomSliderValue > 3 and zoomSliderValue < 4 then
		--print("3 to 4")
		manualAdjustmentValue = 0.000005
	end
	if zoomSliderValue > 4 and zoomSliderValue < 5 then
		--print("4 to 5")
		manualAdjustmentValue = 0.000004
	end
	if zoomSliderValue > 5 and zoomSliderValue < 6 then
		--print("5 to 6")
		manualAdjustmentValue = 0.000004
	end
	if zoomSliderValue > 6 and zoomSliderValue < 7 then
		--print("6 to 7")
		manualAdjustmentValue = 0.00000114
	end
	if zoomSliderValue > 7 and zoomSliderValue < 8 then
		--print("7 to 8")
		manualAdjustmentValue = 0.00000110
	end
	if zoomSliderValue > 8 and zoomSliderValue < 8.5 then
		--print("8 to 8.5")
		manualAdjustmentValue = 0.0000012
	end
	if zoomSliderValue > 8.5 and zoomSliderValue < 9 then
		--print("8.5 to 9")
		manualAdjustmentValue = 0.000003
	end
	if zoomSliderValue > 9 and zoomSliderValue < 9.5 then
		--print("9 to 9.5")
		manualAdjustmentValue = 0.00002
	end
	if zoomSliderValue > 9.5 and zoomSliderValue < 10 then
		--print("9.5 to 10")
		manualAdjustmentValue = 0.00002
	end

	--------------------------------------------------------------------------------
	-- Apply an Offset if Applicable:
	--------------------------------------------------------------------------------
	if hs.settings.get("fcpxHacks.scrollingTimelineOffset") ~= nil then
		manualAdjustmentValue = manualAdjustmentValue * hs.settings.get("fcpxHacks.scrollingTimelineOffset")
	end

	--------------------------------------------------------------------------------
	-- Scrolling Timeline Loop:
	--------------------------------------------------------------------------------
	local timelineAdjustmentValue = initialTimelineScrollbarValue
	hs.timer.doWhile(function() return scrollingTimelineActivated end, function()

		timelineAdjustmentValue = (timelineAdjustmentValue + manualAdjustmentValue)
		--timelineAdjustmentValue = timelineAdjustmentValue
		timelineScrollbar:setAttributeValue("AXValue", timelineAdjustmentValue)

	end, 0.000001)

end
function performScrollingTimelineWIP()

	if not scrollingTimelineActivated then return end

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	fcpx = hs.application("Final Cut Pro")

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
				goto performScrollingTimelineSplitGroupExit
			end
		end
	end
	if whichSplitGroup == nil then
		displayErrorMessage("Unable to locate Split Group.")
		return "Failed"
	end
	::performScrollingTimelineSplitGroupExit::

	--------------------------------------------------------------------------------
	-- Which Group:
	--------------------------------------------------------------------------------
	local whichGroup = nil
	for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
		if whichGroup == nil then
			if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1] ~= nil then
				if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1]:attributeValue("AXRole") == "AXSplitGroup" then
					if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i][1]:attributeValue("AXIdentifier") == "_NS:11" then
						whichGroup = i
						goto performScrollingTimelineGroupExit
					end
				end
			end
		end
	end
	if whichGroup == nil then
		displayErrorMessage("Unable to locate Group.")
		return "Failed"
	end
	::performScrollingTimelineGroupExit::

	--------------------------------------------------------------------------------
	-- Which Zoom Slider:
	--------------------------------------------------------------------------------
	local whichZoomSlider = nil
	for i=1, fcpxElements[whichSplitGroup]:attributeValueCount("AXChildren") do
		if fcpxElements[whichSplitGroup]:attributeValue("AXChildren")[i]:attributeValue("AXHelp") == "Adjust the Timeline zoom level" then
			whichZoomSlider = i
			goto performScrollingTimelineZoomSliderExit
		end
	end
	if whichZoomSlider == nil then
		displayErrorMessage("Unable to locate Zoom Slider.")
		return "Failed"
	end
	::performScrollingTimelineZoomSliderExit::

	--------------------------------------------------------------------------------
	-- TIMELINE PLAYHEAD PATH:
	-- 	Which Split Group = 1
	-- 	Which Scroll Area = 2
	-- 	Which Layout Area = 1
	-- 	Which Value Indicator = 2
	--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- TIMELINE SCROLLBAR PATH:
	-- 	Which Split Group = 1
	-- 	Which Scroll Area = 2
	-- 	Which Scroll Bar = 2
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

	--------------------------------------------------------------------------------
	-- Check mouse is in timeline area:
	--------------------------------------------------------------------------------
	local mouseLocation = hs.mouse.getAbsolutePosition()
	local timelinePosition = fcpxElements[whichSplitGroup][whichGroup][1][2]:attributeValue("AXPosition")
	local timelineSize = fcpxElements[whichSplitGroup][whichGroup][1][2]:attributeValue("AXSize")

	local isMouseInTimelineArea = true
	if (mouseLocation['y'] < timelinePosition['y']) then
		-- Too High:
		isMouseInTimelineArea = false
	end
	if (mouseLocation['y'] > (timelinePosition['y']+timelineSize['h'])) then
		-- Too Low:
		isMouseInTimelineArea = false
	end
	if (mouseLocation['x'] < timelinePosition['x']) then
		-- Too Left:
		isMouseInTimelineArea = false
	end
	if (mouseLocation['x'] > (timelinePosition['x']+timelineSize['w'])) then
		-- Too Right:
		isMouseInTimelineArea = false
	end

	if not isMouseInTimelineArea then
		print("OUTSIDE")
		return false
	end

	--------------------------------------------------------------------------------
	-- Zoom Slider Value:
	--------------------------------------------------------------------------------
	local zoomSliderValue = fcpxElements[whichSplitGroup][whichZoomSlider]:attributeValue("AXValue") -- 0 to 10

	--------------------------------------------------------------------------------
	-- Timeline is full width so there's no scroll bar!
	--------------------------------------------------------------------------------
	if zoomSliderValue == 0 then return end

	--------------------------------------------------------------------------------
	-- Get UI Values:
	--------------------------------------------------------------------------------
    local timelineScrollbar = fcpxElements[whichSplitGroup][whichGroup][1][2][2][1]
	local timelinePlayhead = fcpxElements[whichSplitGroup][whichGroup][1][2][1][whichValueIndicator]

    local initialTimelinePlayheadPosition = timelinePlayhead:attributeValue("AXPosition")['x']
	local initialTimelineScrollbarValue = timelineScrollbar:attributeValue("AXValue")
	local initialTimelineMax = timelinePosition['x'] + timelineSize['w']

	print("initialTimelinePlayheadPosition: " .. tostring(initialTimelinePlayheadPosition))
	print("timelineMax: " .. tostring(timelineMax))

	--------------------------------------------------------------------------------
	-- Apply an Offset if Applicable:
	--------------------------------------------------------------------------------
	--if hs.settings.get("fcpxHacks.scrollingTimelineOffset") ~= nil then
	--	manualAdjustmentValue = manualAdjustmentValue * hs.settings.get("fcpxHacks.scrollingTimelineOffset")
	--end

	--------------------------------------------------------------------------------
	-- Scrolling Timeline Loop:
	--------------------------------------------------------------------------------
	local timelineAdjustmentValue = initialTimelineScrollbarValue
	hs.timer.doWhile(function() return scrollingTimelineActivated end, function()

		local currentPlayheadPosition = fcpxElements[whichSplitGroup][whichGroup][1][2][1][whichValueIndicator]:attributeValue("AXPosition")['x']
		local howMuchPlayheadHasMoved = (currentPlayheadPosition - initialTimelinePlayheadPosition)

		local howMuchToAdjustScrollBar = (howMuchPlayheadHasMoved / hs.screen.mainScreen():fullFrame()['w']) / (zoomSliderValue/10)

		--print("currentPlayheadPosition: " .. tostring(currentPlayheadPosition))
		--print("howMuchToAdjustScrollBar: " .. tostring(howMuchToAdjustScrollBar))

		timelineScrollbar:setAttributeValue("AXValue", initialTimelineScrollbarValue + howMuchToAdjustScrollBar)

	end, 0.000001)

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
				hs.eventtap.keyStroke({"cmd"}, "e")

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
				hs.eventtap.keyStroke({"cmd"}, "e")

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
				hs.eventtap.keyStroke({"cmd"}, "e")

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
		hs.eventtap.keyStroke({"ctrl"}, "p")
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
		print_r(fcpxElements:attributeValue("AXChildren"))
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
	displayMessage("Your Keywords have been saved to Preset " .. tostring(whichButton) .. ".")

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
	displayMessage("Your Keywords have been restored to Preset " .. tostring(whichButton) .. ".")

end

--------------------------------------------------------------------------------
-- FCPX COLOR BOARD PUCK SELECTION:
--------------------------------------------------------------------------------
function colorBoardSelectPuck(whichPuck)
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
	-- Which Split Group:
	--------------------------------------------------------------------------------
	local whichSplitGroup = nil
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

	--------------------------------------------------------------------------------
	-- Which Group?
	--------------------------------------------------------------------------------
	local whichGroup = nil
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
			displayErrorMessage("Unable to find Group for a second time.")
			return "Failed"
		end
	end
	::colorBoardSelectPuckGroupExit::

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
	local originalMousePoint = hs.mouse.getAbsolutePosition()
	local colorBoardPosition = {}
	colorBoardPosition['x'] = fcpxElements[whichSplitGroup][whichGroup][whichPuckButton]:attributeValue("AXPosition")['x'] + (fcpxElements[whichSplitGroup][whichGroup][whichPuckButton]:attributeValue("AXSize")['w'] / 2)
	colorBoardPosition['y'] = fcpxElements[whichSplitGroup][whichGroup][whichPuckButton]:attributeValue("AXPosition")['y'] + (fcpxElements[whichSplitGroup][whichGroup][whichPuckButton]:attributeValue("AXSize")['h'] / 2)
	hs.eventtap.leftClick(colorBoardPosition)
	hs.mouse.setAbsolutePosition(originalMousePoint)

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
			for k, v in pairs(finalCutProShortcutKey) do

				local executeCommand = "/usr/libexec/PlistBuddy -c \"Print :" .. tostring(k) .. ":\" '" .. tostring(activeCommandSet) .. "'"
				local executeResult,executeStatus = hs.execute(executeCommand)
				if executeStatus == nil then
					--------------------------------------------------------------------------------
					-- Maybe there is nothing allocated to this command in the plist?
					--------------------------------------------------------------------------------
					finalCutProShortcutKey[k]['characterString'] = ""
					print("[FCPX Hacks] WARNING: Retrieving data from plist failed (" .. tostring(k) .. ").")
				else
					local x, lastDict = string.gsub(executeResult, "Dict {", "")
					lastDict = lastDict - 1
					local currentDict = ""
					if lastDict ~= 0 then currentDict = ":0" end -- Always use the first entry.

					local executeCommand = "/usr/libexec/PlistBuddy -c \"Print :" .. tostring(k) .. currentDict .. ":characterString\" '" .. tostring(activeCommandSet) .. "'"
					local executeResult,executeStatus,executeType,executeRC = hs.execute(executeCommand)

					if executeStatus == nil then
						if executeType == "exit" then
							--------------------------------------------------------------------------------
							-- Assuming that the plist was read fine, but contained no value:
							--------------------------------------------------------------------------------
							finalCutProShortcutKey[k]['characterString'] = ""
						else
							displayErrorMessage("Could not read the plist correctly when retrieving characterString information.")
							return "Failed"
						end
					else
						finalCutProShortcutKey[k]['characterString'] = translateKeyboardCharacters(trim(executeResult))
					end
				end
			end
			for k, v in pairs(finalCutProShortcutKey) do

				local executeCommand = "/usr/libexec/PlistBuddy -c \"Print :" .. tostring(k) .. ":\" '" .. tostring(activeCommandSet) .. "'"
				local executeResult,executeStatus = hs.execute(executeCommand)
				if executeStatus == nil then
					--------------------------------------------------------------------------------
					-- Maybe there is nothing allocated to this command in the plist?
					--------------------------------------------------------------------------------
					finalCutProShortcutKey[k]['modifiers'] = {}
					print("[FCPX Hacks] WARNING: Retrieving data from plist failed (" .. tostring(k) .. ").")
				else
					local x, lastDict = string.gsub(executeResult, "Dict {", "")
					lastDict = lastDict - 1
					local currentDict = ""
					if lastDict ~= 0 then currentDict = ":0" end -- Always use the first entry.

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
									finalCutProShortcutKey[k]['modifiers'] = {}
								else
									displayErrorMessage("Could not read the plist correctly when retrieving modifierMask information.")
									return "Failed"
								end
							else
								finalCutProShortcutKey[k]['modifiers'] = translateModifierMask(trim(executeResult))
							end
						else
							displayErrorMessage("Could not read the plist correctly when retrieving modifiers information.")
							return "Failed"
						end
					else
						finalCutProShortcutKey[k]['modifiers'] = translateKeyboardModifiers(executeResult)
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

	if hs.appfinder.appFromName("Final Cut Pro") == nil then
		return false
	else
		return hs.appfinder.appFromName("Final Cut Pro"):isFrontmost()
	end

end

--------------------------------------------------------------------------------
-- IS FINAL CUT PRO ACTIVE:
--------------------------------------------------------------------------------
function isFinalCutProRunning()

	if hs.appfinder.appFromName("Final Cut Pro") == nil then
		return false
	else
		return hs.appfinder.appFromName("Final Cut Pro"):isRunning()
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

	-- Put focus on FCPX:
	--hs.application.launchOrFocus("Final Cut Pro")

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
-- DISPLAY NUMBER TEXT BOX MESSAGE:
--------------------------------------------------------------------------------
function displayNumberTextBoxMessage(whatMessage, whatErrorMessage, defaultAnswer)
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
					if (class of usersInput is integer) then
						if usersInput is not 0 then
							exit repeat
						end if
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
-- DISPLAY ALERT MESSAGE:
--------------------------------------------------------------------------------
function displayAlertMessage(whatMessage)
	local returnToFinalCutPro = isFinalCutProFrontmost()
	local appleScriptA = 'set whatMessage to "' .. whatMessage .. '"' .. '\n\n'
	local appleScriptB = [[
		tell me to activate
		display dialog whatMessage buttons {"Close"} with icon stop
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
		display dialog commonErrorMessageStart & whatError & commonErrorMessageEnd buttons {"Close"} with icon fcpxIcon
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
		display dialog whatMessage buttons {"Close"} with icon fcpxIcon
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
		display dialog whatMessage buttons {"Yes", "No"} with icon fcpxIcon
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
--------------------------------------------------------------------------------





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                             W A T C H E R S                                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- DEFINE A CALLBACK FUNCTION TO BE CALLED WHEN APPLICATION EVENTS HAPPEN:
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
			if hs.settings.get("fcpxHacks.scrollingTimelineStatus") == true then
				if scrollingTimelineWatcherUp ~= nil then
					scrollingTimelineWatcherUp:start()
					scrollingTimelineWatcherDown:start()
					--print("Enabled Timeline Watcher as FCPX got focus.")
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
			if hs.settings.get("fcpxHacks.scrollingTimelineStatus") == true then
				if scrollingTimelineWatcherUp ~= nil then
					scrollingTimelineWatcherUp:stop()
					scrollingTimelineWatcherDown:stop()
					--print("Disabled Timeline Watcher as FCPX lost focus.")
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
-- AUTOMATICALLY DO THINGS WHEN FCPX ACTIVE COMMAND SET IS CHANGED:
--------------------------------------------------------------------------------
function finalCutProActiveCommandSetChanged(files)
    doReload = false
    for _,file in pairs(files) do
        if file:sub(-11) == ".commandset" then
            doReload = true
        end
    end
    if doReload then
    	--------------------------------------------------------------------------------
    	-- Refresh Keyboard Shortcuts:
    	--------------------------------------------------------------------------------
    	bindKeyboardShortcuts()
    end
end

--------------------------------------------------------------------------------
-- DISABLE SHORTCUTS WHEN COMMAND EDITOR IS OPEN:
--------------------------------------------------------------------------------
function commandEditorWatcher()

	--------------------------------------------------------------------------------
	-- Limit Error Messages for a clean console:
	--------------------------------------------------------------------------------
	hs.window.filter.setLogLevel(1)
	hs.window.filter.ignoreAlways['System Events'] = true

	isCommandEditorOpen = false
	commandEditorID = nil

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

				--------------------------------------------------------------------------------
				-- Disable Hotkeys:
				--------------------------------------------------------------------------------
				hotkeys:exit()
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

				--------------------------------------------------------------------------------
				-- Refresh Keyboard Shortcuts:
				--------------------------------------------------------------------------------
				bindKeyboardShortcuts()

				--------------------------------------------------------------------------------
				-- Enable Hotkeys:
				--------------------------------------------------------------------------------
				hotkeys:enter()
			end
		end
	  end),
	  true
	)

end

--------------------------------------------------------------------------------
-- ENABLE SHORTCUTS DURING FULLSCREEN PLAYBACK:
--------------------------------------------------------------------------------
function fullscreenKeyboardWatcher()
	fullscreenKeyboardWatcherWorking = false
	fullscreenKeyboardWatcherUp = hs.eventtap.new({ hs.eventtap.event.types.keyUp }, function(event)
		fullscreenKeyboardWatcherWorking = false
	end)
	fullscreenKeyboardWatcherDown = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)

		--------------------------------------------------------------------------------
		-- Just in case...
		--------------------------------------------------------------------------------
		if isFinalCutProRunning() == false then
			print("[FCPX Hacks] ERROR: Full Screen Watcher was running when FCPX was closed.")
			fullscreenKeyboardWatcherUp:stop()
			fullscreenKeyboardWatcherDown:stop()
			return "Failed"
		end

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
				local whichKey = event:getKeyCode()		-- EXAMPLE: keyCodeTranslator(whichKey) == "c"
				--local whichFlags = event:getFlags()	-- EXAMPLE: whichFlags['cmd']

				--------------------------------------------------------------------------------
				-- Mark In:
				--------------------------------------------------------------------------------
				if keyCodeTranslator(whichKey) == "i" then
					hs.eventtap.keyStroke({""}, "escape")
					hs.eventtap.keyStroke({"cmd"}, "1")
					hs.eventtap.keyStroke({""}, "i")
					hs.eventtap.keyStroke({"cmd", "shift"}, "f")
					return true
				end

				--------------------------------------------------------------------------------
				-- Mark Out:
				--------------------------------------------------------------------------------
				if keyCodeTranslator(whichKey) == "o" then
					hs.eventtap.keyStroke({""}, "escape")
					hs.eventtap.keyStroke({"cmd"}, "1")
					hs.eventtap.keyStroke({""}, "o")
					hs.eventtap.keyStroke({"cmd", "shift"}, "f")
					return true
				end

				--------------------------------------------------------------------------------
				-- Connect to Primary Storyline:
				--------------------------------------------------------------------------------
				if keyCodeTranslator(whichKey) == "q" then
					hs.eventtap.keyStroke({""}, "escape")
					hs.eventtap.keyStroke({"cmd"}, "1")
					hs.eventtap.keyStroke({""}, "q")
					hs.eventtap.keyStroke({"cmd", "shift"}, "f")
					return true
				end

				--------------------------------------------------------------------------------
				-- Insert:
				--------------------------------------------------------------------------------
				if keyCodeTranslator(whichKey) == "w" then
					hs.eventtap.keyStroke({""}, "escape")
					hs.eventtap.keyStroke({"cmd"}, "1")
					hs.eventtap.keyStroke({""}, "w")
					hs.eventtap.keyStroke({"cmd", "shift"}, "f")
					return true
				end

				--------------------------------------------------------------------------------
				-- Append to Storyline:
				--------------------------------------------------------------------------------
				if keyCodeTranslator(whichKey) == "e" then
					hs.eventtap.keyStroke({""}, "escape")
					hs.eventtap.keyStroke({"cmd"}, "1")
					hs.eventtap.keyStroke({""}, "e")
					hs.eventtap.keyStroke({"cmd", "shift"}, "f")
					return true
				end
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- SCROLLING TIMELINE WATCHER:
--------------------------------------------------------------------------------
function scrollingTimelineWatcher()

	scrollingTimelineWatcherWorking = false

	scrollingTimelineWatcherUp = hs.eventtap.new({ hs.eventtap.event.types.keyUp }, function(event)
		scrollingTimelineWatcherWorking = false
	end)

	scrollingTimelineWatcherDown = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)

		--------------------------------------------------------------------------------
		-- Just in case...
		--------------------------------------------------------------------------------
		if isFinalCutProRunning() == false then
			print("[FCPX Hacks] ERROR: Scrolling Timeline Watcher was running when FCPX was closed.")
			scrollingTimelineWatcherUp:stop()
			scrollingTimelineWatcherDown:stop()
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Don't repeat if key is held down:
		--------------------------------------------------------------------------------
		if scrollingTimelineWatcherWorking then return false end
		scrollingTimelineWatcherWorking = true

		--------------------------------------------------------------------------------
		-- Get keypress information:
		--------------------------------------------------------------------------------
		local whichKey = event:getKeyCode()		-- EXAMPLE: keyCodeTranslator(whichKey) == "c"

		--------------------------------------------------------------------------------
		-- Space Bar Pressed:
		--------------------------------------------------------------------------------
		if whichKey == 49 then

			if scrollingTimelineActivated == nil then
				scrollingTimelineActivated = true
			else
				scrollingTimelineActivated = not scrollingTimelineActivated
			end

			--------------------------------------------------------------------------------
			-- Let's do this!
			--------------------------------------------------------------------------------
			performScrollingTimeline()

		end

	end)
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