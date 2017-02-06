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
												["enableHacksShortcutsInFinalCutPro"] 			= false,
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
												["displayMenubarAsIcon"]						= true,
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

		local preferences = plugins("cp.plugins.menu.preferences")
		preferences:addItems(10000, function() return generatePreferencesMenuBar() end)

		local menubarPrefs = plugins("cp.plugins.menu.preferences.menubar")
		menubarPrefs:addItems(10000, function() return generateMenubarPrefsMenuBar() end)
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
	mod.debugMode = metadata.get("debugMode", false)
	debugMessage("Debug Mode Activated.")

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
	writeToConsole("Successfully loaded.")
	dialog.displayNotification(metadata.scriptName .. " (v" .. metadata.scriptVersion .. ") " .. i18n("hasLoaded"))

	--------------------------------------------------------------------------------
	-- Check for Script Updates:
	--------------------------------------------------------------------------------
	local checkForUpdatesInterval = metadata.get("checkForUpdatesInterval")
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

        FCPXAddNoteToSelectedClip	 								= { characterString = "",                                   modifiers = {},                                     fn = function() addNoteToSelectedClip() end,                        releasedFn = nil,                                                       repeatFn = nil },

        FCPXHackMoveToPlayhead                                      = { characterString = "",                                   modifiers = {},                                     fn = function() moveToPlayhead() end,                               releasedFn = nil,                                                       repeatFn = nil },

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
		local enableHacksShortcutsInFinalCutPro = metadata.get("enableHacksShortcutsInFinalCutPro", false)

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

		--------------------------------------------------------------------------------
		-- Get Menubar Settings:
		--------------------------------------------------------------------------------
		local menubarToolsEnabled = 		metadata.get("menubarToolsEnabled")
		local menubarHacksEnabled = 		metadata.get("menubarHacksEnabled")

		local settingsHUDButtons = {
			{ title = i18n("button") .. " " .. i18n("one") .. hudButtonOne, 							fn = function() hackshud.assignButton(1) end },
			{ title = i18n("button") .. " " .. i18n("two") .. hudButtonTwo, 							fn = function() hackshud.assignButton(2) end },
			{ title = i18n("button") .. " " .. i18n("three") .. hudButtonThree, 						fn = function() hackshud.assignButton(3) end },
			{ title = i18n("button") .. " " .. i18n("four") .. hudButtonFour, 							fn = function() hackshud.assignButton(4) end },
		}
		-- The main menu
		local menuTable = {
		}

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
		local advancedTable = {
			{ title = "-" },
			{ title = i18n("enableHacksShortcuts"), 													fn = toggleEnableHacksShortcutsInFinalCutPro, 						checked = enableHacksShortcutsInFinalCutPro},
			{ title = "-" },
			{ title = i18n("enableTimecodeOverlay"), 													fn = toggleTimecodeOverlay, 										checked = mod.FFEnableGuards },
			{ title = i18n("enableMovingMarkers"), 														fn = toggleMovingMarkers, 											checked = mod.allowMovingMarkers },
			{ title = i18n("enableRenderingDuringPlayback"),											fn = togglePerformTasksDuringPlayback, 								checked = not mod.FFSuspendBGOpsDuringPlay },
			{ title = "-" },
			{ title = i18n("changeBackupInterval") .. " (" .. tostring(mod.FFPeriodicBackupInterval) .. " " .. i18n("mins") .. ")", fn = changeBackupInterval },
			{ title = i18n("changeSmartCollectionLabel"),												fn = changeSmartCollectionsLabel },
		}
		local hacksTable = {
			{ title = "-" },
			{ title = string.upper(i18n("adminTools")) .. ":", 											disabled = true },
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
		-- Enable Check for Updates:
		--------------------------------------------------------------------------------
		local enableCheckForUpdates = metadata.get("enableCheckForUpdates", false)

		--------------------------------------------------------------------------------
		-- Setup Menu:
		--------------------------------------------------------------------------------
		local settingsMenuTable = {
			{ title = "-" },
			{ title = i18n("checkForUpdates"), 															fn = toggleCheckforUpdates, 								checked = hammerspoonCheckForUpdates	},
			{ title = i18n("launchAtStartup"), 															fn = toggleLaunchOnStartup, 										checked = startHammerspoonOnLaunch		},
			{ title = "-" },
			{ title = i18n("console") .. "...", 														fn = openConsole },
			{ title = i18n("trashPreferences"), 														fn = resetSettings },
			{ title = i18n("enableDebugMode"), 															fn = toggleDebugMode, 												checked = mod.debugMode},
		}

		return settingsMenuTable
	end

	function generateMenubarPrefsMenuBar()
		--------------------------------------------------------------------------------
		-- Get Menubar Settings:
		--------------------------------------------------------------------------------
		local menubarToolsEnabled = 		metadata.get("menubarToolsEnabled")
		local menubarHacksEnabled = 		metadata.get("menubarHacksEnabled")

		--------------------------------------------------------------------------------
		-- Get Enable Proxy Menu Item:
		--------------------------------------------------------------------------------
		local enableProxyMenuIcon = metadata.get("enableProxyMenuIcon", false)

		--------------------------------------------------------------------------------
		-- Get Menubar Display Mode from Settings:
		--------------------------------------------------------------------------------
		local displayMenubarAsIcon = metadata.get("displayMenubarAsIcon", false)

		local settingsMenubar = {
			{ title = i18n("showAdminTools"), 															fn = function() toggleMenubarDisplay("Hacks") end, 					checked = menubarHacksEnabled},
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
	-- TOGGLE DEBUG MODE:
	--------------------------------------------------------------------------------
	function toggleDebugMode()
		metadata.set("debugMode", not mod.debugMode)
		hs.reload()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE MENUBAR DISPLAY:
	--------------------------------------------------------------------------------
	function toggleMenubarDisplay(value)
		local menubarEnabled = metadata.get("menubar" .. value .. "Enabled")
		metadata.set("menubar" .. value .. "Enabled", not menubarEnabled)
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
	-- TOGGLE LAUNCH HAMMERSPOON ON START:
	--------------------------------------------------------------------------------
	function toggleLaunchOnStartup()
		local originalValue = hs.autoLaunch()
		hs.autoLaunch(not originalValue)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HAMMERSPOON CHECK FOR UPDATES:
	--------------------------------------------------------------------------------
	function toggleCheckforUpdates()
		local originalValue = hs.automaticallyCheckForUpdates()
		hs.automaticallyCheckForUpdates(not originalValue)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE ENABLE PROXY MENU ICON:
	--------------------------------------------------------------------------------
	function toggleEnableProxyMenuIcon()
		local enableProxyMenuIcon = metadata.get("enableProxyMenuIcon")
		if enableProxyMenuIcon == nil then
			metadata.set("enableProxyMenuIcon", true)
			enableProxyMenuIcon = true
		else
			metadata.set("enableProxyMenuIcon", not enableProxyMenuIcon)
		end

		updateMenubarIcon()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE HACKS SHORTCUTS IN FINAL CUT PRO:
	--------------------------------------------------------------------------------
	function toggleEnableHacksShortcutsInFinalCutPro()
		plugins("cp.plugins.hacks.shortcuts").toggleEditable()
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

		local displayMenubarAsIcon = metadata.get("displayMenubarAsIcon")


		if displayMenubarAsIcon == nil then
			 metadata.set("displayMenubarAsIcon", true)
		else
			if displayMenubarAsIcon then
				metadata.set("displayMenubarAsIcon", false)
			else
				metadata.set("displayMenubarAsIcon", true)
			end
		end

		updateMenubarIcon()
	end

--------------------------------------------------------------------------------
-- OTHER:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- OPEN HAMMERSPOON CONSOLE:
	--------------------------------------------------------------------------------
	function openConsole()
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
		plugins("cp.plugins.hacks.shortcuts").disableHacksShortcuts()

		--------------------------------------------------------------------------------
		-- Trash all Script Settings:
		--------------------------------------------------------------------------------
		metadata.reset()

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
		deleteAllHighlights()

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
		local axutils = require("cp.finalcutpro.axutils")
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

				local recentNotes = metadata.get("recentNotes", {})
				if selectedRow == 1 then
					table.insert(recentNotes, 1, result)
					metadata.set("recentNotes", recentNotes)
				else
					table.remove(recentNotes, selectedRow)
					table.insert(recentNotes, 1, result)
					metadata.set("recentNotes", recentNotes)
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
			local recentNotes = metadata.get("recentNotes", {})

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
		local clipboardManager = plugins("cp.plugins.clipboard.manager")

		clipboardManager.stopWatching()

		if not fcp:performShortcut("Cut") then
			dialog.displayErrorMessage("Failed to trigger the 'Cut' Shortcut.\n\nError occurred in moveToPlayhead().")
			goto moveToPlayheadEnd
		end

		if not fcp:performShortcut("Paste") then
			dialog.displayErrorMessage("Failed to trigger the 'Paste' Shortcut.\n\nError occurred in moveToPlayhead().")
			goto moveToPlayheadEnd
		end

		::moveToPlayheadEnd::
		timer.doAfter(2, function() clipboardManager.startWatching() end)
	end

	--------------------------------------------------------------------------------
	-- HIGHLIGHT FINAL CUT PRO BROWSER PLAYHEAD:
	--------------------------------------------------------------------------------
	function highlightFCPXBrowserPlayhead()
		plugins("cp.plugins.browser.playhead").highlight()
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
	-- DELETE ALL HIGHLIGHTS:
	--------------------------------------------------------------------------------
	function deleteAllHighlights()
		plugins("cp.plugins.browser.playhead").deleteHighlight()
	end

	--------------------------------------------------------------------------------
	-- CHECK FOR SCRIPT UPDATES:
	--------------------------------------------------------------------------------
	function checkForUpdates()

		local enableCheckForUpdates = metadata.get("enableCheckForUpdates")
		if enableCheckForUpdates then
			debugMessage("Checking for updates.")
			latestScriptVersion = nil

			http.asyncGet(metadata.checkUpdateURL, nil, function(responseCode, responseBody, _)
				if responseCode < 0 then
					log.ef(responseBody)
					return
				end
				local responseJSON = hs.json.decode(responseBody)
				local thisVersion = hs.processInfo.version
				local remoteVersion = responseJSON.tag_name

				-- Remove the "v":
				if remoteVersion ~= nil then
					if string.sub(remoteVersion, 1, 1) == "v" then
						remoteVersion = string.sub(remoteVersion, 2)
					end
				end

				if thisVersion and remoteVersion then
					log.df("thisVersion: " .. thisVersion)
					log.df("remoteVersion: " .. remoteVersion)

					--------------------------------------------------------------------------------
					-- macOS Notification:
					--------------------------------------------------------------------------------
					if not mod.shownUpdateNotification then
						if remoteVersion > thisVersion then
							updateNotification = notify.new(function() hs.checkForUpdates() end):setIdImage(image.imageFromPath(metadata.iconPath))
																:title(metadata.scriptName .. " Update Available")
																:subTitle("Version " .. remoteVersion)
																:informativeText("Do you wish to install?")
																:hasActionButton(true)
																:actionButtonTitle("Install")
																:otherButtonTitle("Not Yet")
																:send()
							mod.shownUpdateNotification = true
						end
					end

				end
			end)
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
		deleteAllHighlights()

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
    	timer.doAfter(0.0000000000001, function() updateMenubarIcon() end)

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
