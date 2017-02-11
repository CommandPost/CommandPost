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
local drawing 									= require("hs.drawing")
local eventtap									= require("hs.eventtap")
local fnutils 									= require("hs.fnutils")
local fs										= require("hs.fs")
local hotkey									= require("hs.hotkey")
local http										= require("hs.http")
local image										= require("hs.image")
local logger									= require("hs.logger")
local notify									= require("hs.notify")
local osascript									= require("hs.osascript")
local pathwatcher								= require("hs.pathwatcher")
local screen									= require("hs.screen")
local timer										= require("hs.timer")
local windowfilter								= require("hs.window.filter")

--------------------------------------------------------------------------------
-- EXTERNAL EXTENSIONS:
--------------------------------------------------------------------------------

local ax 										= require("hs._asm.axuielement")

--------------------------------------------------------------------------------
-- INTERNAL EXTENSIONS:
--------------------------------------------------------------------------------

local dialog									= require("cp.dialog")
local fcp										= require("cp.finalcutpro")
local just										= require("cp.just")
local metadata									= require("cp.metadata")
local plist										= require("cp.plist")
local tools										= require("cp.tools")

--------------------------------------------------------------------------------
-- PLUGINS:
--------------------------------------------------------------------------------

local hacksconsole								= require("cp.fcpx10-3.hacksconsole")
local hackshud									= require("cp.fcpx10-3.hackshud")
local shortcut									= require("cp.commands.shortcut")

--------------------------------------------------------------------------------
-- DEFAULT SETTINGS:
--------------------------------------------------------------------------------

local defaultSettings = {
												["chooserRememberLast"]							= true,
												["chooserShowShortcuts"] 						= true,
												["chooserShowHacks"] 							= true,
												["chooserShowVideoEffects"] 					= true,
												["chooserShowAudioEffects"] 					= true,
												["chooserShowTransitions"] 						= true,
												["chooserShowTitles"] 							= true,
												["chooserShowGenerators"] 						= true,
												["chooserShowMenuItems"]						= true,
												["hudShowInspector"]							= true,
												["hudShowDropTargets"]							= true,
												["hudShowButtons"]								= true,
}

--------------------------------------------------------------------------------
-- LOCAL VARIABLES:
--------------------------------------------------------------------------------

local execute									= hs.execute
local log										= logger.new("fcpx10-3")

--------------------------------------------------------------------------------
-- MODULE VARIABLES:
--------------------------------------------------------------------------------

mod.releaseColorBoardDown						= false											-- Color Board Shortcut Currently Being Pressed
mod.finalCutProShortcutKey 						= nil											-- Table of all Final Cut Pro Shortcuts
mod.finalCutProShortcutKeyPlaceholders 			= nil											-- Table of all needed Final Cut Pro Shortcuts
mod.lastCommandSet								= nil											-- Last Keyboard Shortcut Command Set
mod.hacksLoaded 								= false											-- Has FCPX Hacks Loaded Yet?
mod.isFinalCutProActive 						= false											-- Is Final Cut Pro Active? Used by Watchers.

--------------------------------------------------------------------------------
-- RETRIEVES THE PLUGINS MANAGER:
-- If `pluginPath` is provided, the named plugin will be returned. If not,
-- the plugins module is returned.
--------------------------------------------------------------------------------
function plugins(pluginPath)
	if not mod._plugins then
		mod._plugins = require("cp.plugins")
		mod._plugins.init("cp.plugins")
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
		mod._menuManager = plugins("cp.plugins.menu.manager")

		--- TODO: Remove this once all menu manaement is migrated to plugins.
		local manualSection = mod._menuManager.addSection(10000)
		manualSection:addItems(0, function() return generateMenuBar(true) end)

	end
	return mod._menuManager
end

--------------------------------------------------------------------------------
-- LOAD SCRIPT:
--------------------------------------------------------------------------------
function loadScript()

	--------------------------------------------------------------------------------
	-- Apply Default Settings:
	--------------------------------------------------------------------------------
	for k, v in pairs(defaultSettings) do
		if metadata.get(k) == nil then
			metadata.get(k, v)
		end
	end

	--------------------------------------------------------------------------------
	-- Debug Mode:
	--------------------------------------------------------------------------------
	log.df("Debug Mode Activated.")

	--------------------------------------------------------------------------------
	-- Activate Menu Manager
	--------------------------------------------------------------------------------
	menuManager()

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
		-- Watch for Final Cut Pro plist Changes:
		--------------------------------------------------------------------------------
		preferencesWatcher = pathwatcher.new("~/Library/Preferences/", finalCutProSettingsWatcher):start()

	--------------------------------------------------------------------------------
	-- Bind Keyboard Shortcuts:
	--------------------------------------------------------------------------------
	mod.lastCommandSet = fcp:getActiveCommandSetPath()
	bindKeyboardShortcuts()

	--------------------------------------------------------------------------------
	-- Load Hacks HUD:
	--------------------------------------------------------------------------------
	if metadata.get("enableHacksHUD") then
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
		if metadata.get("enableHacksHUD") then
			hackshud.show()
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
	log.df("Successfully loaded.")
	dialog.displayNotification(metadata.scriptName .. " (v" .. metadata.scriptVersion .. ") " .. i18n("hasLoaded"))

	mod.hacksLoaded = true

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

        cpRestoreKeywordPresetOne                             = { characterString = shortcut.textToKeyCode("1"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(1) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetTwo                             = { characterString = shortcut.textToKeyCode("2"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(2) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetThree                           = { characterString = shortcut.textToKeyCode("3"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(3) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetFour                            = { characterString = shortcut.textToKeyCode("4"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(4) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetFive                            = { characterString = shortcut.textToKeyCode("5"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(5) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetSix                             = { characterString = shortcut.textToKeyCode("6"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(6) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetSeven                           = { characterString = shortcut.textToKeyCode("7"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(7) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetEight                           = { characterString = shortcut.textToKeyCode("8"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(8) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetNine                            = { characterString = shortcut.textToKeyCode("9"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(9) end,                      releasedFn = nil,                                                       repeatFn = nil },

        cpSaveKeywordPresetOne                                = { characterString = shortcut.textToKeyCode("1"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(1) end,                         releasedFn = nil,                                                       repeatFn = nil },
        cpSaveKeywordPresetTwo                                = { characterString = shortcut.textToKeyCode("2"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(2) end,                         releasedFn = nil,                                                       repeatFn = nil },
        cpSaveKeywordPresetThree                              = { characterString = shortcut.textToKeyCode("3"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(3) end,                         releasedFn = nil,                                                       repeatFn = nil },
        cpSaveKeywordPresetFour                               = { characterString = shortcut.textToKeyCode("4"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(4) end,                         releasedFn = nil,                                                       repeatFn = nil },
        cpSaveKeywordPresetFive                               = { characterString = shortcut.textToKeyCode("5"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(5) end,                         releasedFn = nil,                                                       repeatFn = nil },
        cpSaveKeywordPresetSix                                = { characterString = shortcut.textToKeyCode("6"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(6) end,                         releasedFn = nil,                                                       repeatFn = nil },
        cpSaveKeywordPresetSeven                              = { characterString = shortcut.textToKeyCode("7"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(7) end,                         releasedFn = nil,                                                       repeatFn = nil },
        cpSaveKeywordPresetEight                              = { characterString = shortcut.textToKeyCode("8"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(8) end,                         releasedFn = nil,                                                       repeatFn = nil },
        cpSaveKeywordPresetNine                               = { characterString = shortcut.textToKeyCode("9"),            modifiers = controlOptionCommandShift,              fn = function() saveKeywordSearches(9) end,                         releasedFn = nil,                                                       repeatFn = nil },

        cpConsole                                             = { characterString = shortcut.textToKeyCode("space"),        modifiers = control,                                fn = function() hacksconsole.show() end,							releasedFn = nil,                                     					repeatFn = nil },

        cpHUD                                                 = { characterString = shortcut.textToKeyCode("a"),            modifiers = controlOptionCommand,                   fn = function() toggleEnableHacksHUD() end,                         releasedFn = nil,                                                       repeatFn = nil },

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
	local enableHacksShortcutsInFinalCutPro = metadata.get("enableHacksShortcutsInFinalCutPro")
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
		-- only delete hotkeys which are not created by `cp.commands.shortcut`
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
	-- TEMPORARY - GENERATE MENU BAR:
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
		-- Enable Hacks HUD:
		--------------------------------------------------------------------------------
		local enableHacksHUD 		= metadata.get("enableHacksHUD", false)

		local hudButtonOne 			= metadata.get(currentLanguage .. ".hudButtonOne") 	or " (Unassigned)"
		local hudButtonTwo 			= metadata.get(currentLanguage .. ".hudButtonTwo") 	or " (Unassigned)"
		local hudButtonThree 		= metadata.get(currentLanguage .. ".hudButtonThree") 	or " (Unassigned)"
		local hudButtonFour 		= metadata.get(currentLanguage .. ".hudButtonFour") 	or " (Unassigned)"

		if hudButtonOne ~= " (Unassigned)" then		hudButtonOne = " (" .. 		tools.stringMaxLength(tools.cleanupButtonText(hudButtonOne["text"]),maxTextLength,"...") 	.. ")" end
		if hudButtonTwo ~= " (Unassigned)" then 	hudButtonTwo = " (" .. 		tools.stringMaxLength(tools.cleanupButtonText(hudButtonTwo["text"]),maxTextLength,"...") 	.. ")" end
		if hudButtonThree ~= " (Unassigned)" then 	hudButtonThree = " (" .. 	tools.stringMaxLength(tools.cleanupButtonText(hudButtonThree["text"]),maxTextLength,"...") 	.. ")" end
		if hudButtonFour ~= " (Unassigned)" then 	hudButtonFour = " (" .. 	tools.stringMaxLength(tools.cleanupButtonText(hudButtonFour["text"]),maxTextLength,"...") 	.. ")" end

		--------------------------------------------------------------------------------
		-- HUD Preferences:
		--------------------------------------------------------------------------------
		local hudShowInspector 		= metadata.get("hudShowInspector")
		local hudShowDropTargets 	= metadata.get("hudShowDropTargets")
		local hudShowButtons 		= metadata.get("hudShowButtons")

		local settingsHUDButtons = {
			{ title = i18n("button") .. " " .. i18n("one") .. hudButtonOne, 							fn = function() hackshud.assignButton(1) end },
			{ title = i18n("button") .. " " .. i18n("two") .. hudButtonTwo, 							fn = function() hackshud.assignButton(2) end },
			{ title = i18n("button") .. " " .. i18n("three") .. hudButtonThree, 						fn = function() hackshud.assignButton(3) end },
			{ title = i18n("button") .. " " .. i18n("four") .. hudButtonFour, 							fn = function() hackshud.assignButton(4) end },
		}

		-- The main menu
		local menuTable = {}

		local settingsHUD = {
			{ title = i18n("showInspector"), 															fn = function() toggleHUDOption("hudShowInspector") end, 			checked = hudShowInspector},
			{ title = i18n("showDropTargets"), 															fn = function() toggleHUDOption("hudShowDropTargets") end, 			checked = hudShowDropTargets},
			{ title = i18n("showButtons"), 																fn = function() toggleHUDOption("hudShowButtons") end, 				checked = hudShowButtons},
		}
		local hudMenu = {
			{ title = i18n("enableHacksHUD"), 															fn = toggleEnableHacksHUD, 											checked = enableHacksHUD},
			{ title = "-" },
			{ title = i18n("hudOptions"), 																menu = settingsHUD},
			{ title = i18n("assignHUDButtons"), 														menu = settingsHUDButtons },
		}
		local toolsTable = {
			{ title = i18n("hud"),																		menu = hudMenu },
		}

		--------------------------------------------------------------------------------
		-- Setup Menubar:
		--------------------------------------------------------------------------------
		local menubarToolsEnabled = 		metadata.get("menubarToolsEnabled")
		if menubarToolsEnabled then 		menuTable = fnutils.concat(menuTable, toolsTable)		end

		return menuTable
	end

--------------------------------------------------------------------------------
-- TOGGLE:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- TOGGLE ENABLE HACKS HUD:
	--------------------------------------------------------------------------------
	function toggleEnableHacksHUD()
		local enableHacksHUD = metadata.get("enableHacksHUD")
		metadata.set("enableHacksHUD", not enableHacksHUD)

		if enableHacksHUD then
			hackshud.hide()
		else
			if fcp:isFrontmost() then
				hackshud.show()
			end
		end
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HUD OPTION:
	--------------------------------------------------------------------------------
	function toggleHUDOption(value)
		local result = metadata.get(value)
		metadata.get(value, not result)
		hackshud.reload()
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
		plugins("cp.plugins.browser.playhead").deleteHighlight()

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
		local savedKeywords = metadata.get("savedKeywords")
		if savedKeywords == nil then savedKeywords = {} end
		for i=1, 9 do
			if savedKeywords['Preset ' .. tostring(whichButton)] == nil then
				savedKeywords['Preset ' .. tostring(whichButton)] = {}
			end
			savedKeywords['Preset ' .. tostring(whichButton)]['Item ' .. tostring(i)] = savedKeywordValues[i]
		end
		metadata.set("savedKeywords", savedKeywords)

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
		plugins("cp.plugins.browser.playhead").deleteHighlight()

		--------------------------------------------------------------------------------
		-- Get Values from Settings:
		--------------------------------------------------------------------------------
		local savedKeywords = metadata.get("savedKeywords")
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
-- OTHER SHORTCUTS:
--------------------------------------------------------------------------------

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
									if metadata.get("enableHacksHUD") then
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
					if metadata.get("enableHacksHUD") then
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
				log.df("Disabling Hotkeys")
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
			if metadata.get("enableHacksHUD") then
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
			if metadata.get("enableHacksHUD") then
				hackshud:show()
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
		-- Disable hotkeys:
		--------------------------------------------------------------------------------
		hotkeys:exit()

		--------------------------------------------------------------------------------
		-- Delete the Mouse Circle:
		--------------------------------------------------------------------------------
		plugins("cp.plugins.browser.playhead").deleteHighlight()

		-------------------------------------------------------------------------------
		-- If not focussed on Hammerspoon then hide HUD:
		--------------------------------------------------------------------------------
		if metadata.get("enableHacksHUD") then
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
    	timer.doAfter(0.0000000000001, function() menuManager():updateMenubarIcon() end)

 		--------------------------------------------------------------------------------
		-- Reload Hacks HUD:
		--------------------------------------------------------------------------------
		if metadata.get("enableHacksHUD") then
			timer.doAfter(0.0000000000001, function() hackshud:refresh() end)
		end

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