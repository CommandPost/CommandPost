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
        cpSelectColorBoardPuckOne                             = { characterString = shortcut.textToKeyCode("m"),            modifiers = controlOptionCommand,                   fn = function() colorBoardSelectPuck("*", "global") end,            releasedFn = nil,                                                       repeatFn = nil },
        cpSelectColorBoardPuckTwo                             = { characterString = shortcut.textToKeyCode(","),            modifiers = controlOptionCommand,                   fn = function() colorBoardSelectPuck("*", "shadows") end,           releasedFn = nil,                                                       repeatFn = nil },
        cpSelectColorBoardPuckThree                           = { characterString = shortcut.textToKeyCode("."),            modifiers = controlOptionCommand,                   fn = function() colorBoardSelectPuck("*", "midtones") end,          releasedFn = nil,                                                       repeatFn = nil },
        cpSelectColorBoardPuckFour                            = { characterString = shortcut.textToKeyCode("/"),            modifiers = controlOptionCommand,                   fn = function() colorBoardSelectPuck("*", "highlights") end,        releasedFn = nil,                                                       repeatFn = nil },

        cpRestoreKeywordPresetOne                             = { characterString = shortcut.textToKeyCode("1"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(1) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetTwo                             = { characterString = shortcut.textToKeyCode("2"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(2) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetThree                           = { characterString = shortcut.textToKeyCode("3"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(3) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetFour                            = { characterString = shortcut.textToKeyCode("4"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(4) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetFive                            = { characterString = shortcut.textToKeyCode("5"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(5) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetSix                             = { characterString = shortcut.textToKeyCode("6"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(6) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetSeven                           = { characterString = shortcut.textToKeyCode("7"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(7) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetEight                           = { characterString = shortcut.textToKeyCode("8"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(8) end,                      releasedFn = nil,                                                       repeatFn = nil },
        cpRestoreKeywordPresetNine                            = { characterString = shortcut.textToKeyCode("9"),            modifiers = controlOptionCommand,                   fn = function() restoreKeywordSearches(9) end,                      releasedFn = nil,                                                       repeatFn = nil },

        cpHUD                                                 = { characterString = shortcut.textToKeyCode("a"),            modifiers = controlOptionCommand,                   fn = function() toggleEnableHacksHUD() end,                         releasedFn = nil,                                                       repeatFn = nil },

        cpChangeTimelineClipHeightUp                          = { characterString = shortcut.textToKeyCode("+"),            modifiers = controlOptionCommand,                   fn = function() changeTimelineClipHeight("up") end,                 releasedFn = function() changeTimelineClipHeightRelease() end,          repeatFn = nil },
        cpChangeTimelineClipHeightDown                        = { characterString = shortcut.textToKeyCode("-"),            modifiers = controlOptionCommand,                   fn = function() changeTimelineClipHeight("down") end,               releasedFn = function() changeTimelineClipHeightRelease() end,          repeatFn = nil },

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

        FCPXAddNoteToSelectedClip	 								= { characterString = "",                                   modifiers = {},                                     fn = function() addNoteToSelectedClip() end,                        releasedFn = nil,                                                       repeatFn = nil },

        cpColorPuckOne                                        = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global") end,                    releasedFn = nil,                                           repeatFn = nil },
        cpColorPuckTwo                                        = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "shadows") end,                   releasedFn = nil,                                           repeatFn = nil },
        cpColorPuckThree                                      = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "midtones") end,                  releasedFn = nil,                                           repeatFn = nil },
        cpColorPuckFour                                       = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "highlights") end,                releasedFn = nil,                                           repeatFn = nil },

        cpSaturationPuckOne                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "global") end,               releasedFn = nil,                                           repeatFn = nil },
        cpSaturationPuckTwo                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "shadows") end,              releasedFn = nil,                                           repeatFn = nil },
        cpSaturationPuckThree                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "midtones") end,             releasedFn = nil,                                           repeatFn = nil },
        cpSaturationPuckFour                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "highlights") end,           releasedFn = nil,                                           repeatFn = nil },

        cpExposurePuckOne                                     = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "global") end,                 releasedFn = nil,                                           repeatFn = nil },
        cpExposurePuckTwo                                     = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "shadows") end,                releasedFn = nil,                                           repeatFn = nil },
        cpExposurePuckThree                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "midtones") end,               releasedFn = nil,                                           repeatFn = nil },
        cpExposurePuckFour                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "highlights") end,             releasedFn = nil,                                           repeatFn = nil },

        cpColorPuckOneUp                                      = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "up") end,              releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpColorPuckTwoUp                                      = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "shadows", "up") end,             releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpColorPuckThreeUp                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "midtones", "up") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpColorPuckFourUp                                     = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "highlights", "up") end,          releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        cpColorPuckOneDown                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "down") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpColorPuckTwoDown                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "shadows", "down") end,           releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpColorPuckThreeDown                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "midtones", "down") end,          releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpColorPuckFourDown                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "highlights", "down") end,        releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        cpColorPuckOneLeft                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "left") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpColorPuckTwoLeft                                    = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "left") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpColorPuckThreeLeft                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "left") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpColorPuckFourLeft                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "left") end,            releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        cpColorPuckOneRight                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "global", "right") end,           releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpColorPuckTwoRight                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "shadows", "right") end,          releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpColorPuckThreeRight                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "midtones", "right") end,         releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpColorPuckFourRight                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("color", "highlights", "right") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        cpSaturationPuckOneUp                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "global", "up") end,         releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpSaturationPuckTwoUp                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "shadows", "up") end,        releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpSaturationPuckThreeUp                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "midtones", "up") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpSaturationPuckFourUp                                = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "highlights", "up") end,     releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        cpSaturationPuckOneDown                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "global", "down") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpSaturationPuckTwoDown                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "shadows", "down") end,      releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpSaturationPuckThreeDown                             = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "midtones", "down") end,     releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpSaturationPuckFourDown                              = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("saturation", "highlights", "down") end,   releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        cpExposurePuckOneUp                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "global", "up") end,           releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpExposurePuckTwoUp                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "shadows", "up") end,          releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpExposurePuckThreeUp                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "midtones", "up") end,         releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpExposurePuckFourUp                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "highlights", "up") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        cpExposurePuckOneDown                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "global", "down") end,         releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpExposurePuckTwoDown                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "shadows", "down") end,        releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpExposurePuckThreeDown                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "midtones", "down") end,       releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },
        cpExposurePuckFourDown                                = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardSelectPuck("exposure", "highlights", "down") end,     releasedFn = function() colorBoardSelectPuckRelease() end,  repeatFn = nil },

        cpPuckOneMouse                                        = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("*", "global") end,             releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        cpPuckTwoMouse                                        = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("*", "shadows") end,            releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        cpPuckThreeMouse                                      = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("*", "midtones") end,           releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        cpPuckFourMouse                                       = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("*", "highlights") end,         releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },

        cpColorPuckOneMouse                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("color", "global") end,         releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        cpColorPuckTwoMouse                                   = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("color", "shadows") end,        releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        cpColorPuckThreeMouse                                 = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("color", "midtones") end,       releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        cpColorPuckFourMouse                                  = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("color", "highlights") end,     releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },

        cpSaturationPuckOneMouse                              = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("saturation", "global") end,    releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        cpSaturationPuckTwoMouse                              = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("saturation", "shadows") end,   releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        cpSaturationPuckThreeMouse                            = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("saturation", "midtones") end,  releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        cpSaturationPuckFourMouse                             = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("saturation", "highlights") end,releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },

        cpExposurePuckOneMouse                                = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("exposure", "global") end,      releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        cpExposurePuckTwoMouse                                = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("exposure", "shadows") end,     releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        cpExposurePuckThreeMouse                              = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("exposure", "midtones") end,    releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },
        cpExposurePuckFourMouse                               = { characterString = "",                                   modifiers = {},                                     fn = function() colorBoardMousePuck("exposure", "highlights") end,  releasedFn = function() colorBoardMousePuckRelease() end,               repeatFn = nil },

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
-- COLOR BOARD RELATED:
--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- COLOR BOARD - PUCK SELECTION:
	--------------------------------------------------------------------------------
	function colorBoardSelectPuck(aspect, property, whichDirection)

		--------------------------------------------------------------------------------
		-- Delete any pre-existing highlights:
		--------------------------------------------------------------------------------
		plugins("cp.plugins.browser.playhead").deleteHighlight()

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
		plugins("cp.plugins.browser.playhead").deleteHighlight()

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
		plugins("cp.plugins.browser.playhead").deleteHighlight()

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