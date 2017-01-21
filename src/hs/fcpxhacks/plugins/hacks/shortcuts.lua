-- Imports

local fcp			= require("hs.finalcutpro")
local settings		= require("hs.settings")
local dialog		= require("hs.fcpxhacks.modules.dialog")
local kc			= require("hs.fcpxhacks.modules.shortcuts.keycodes")
local metadata		= require("hs.fcpxhacks.metadata")
local tools			= require("hs.fcpxhacks.modules.tools")

local log			= require("hs.logger").new("shortcuts")

-- Constants

local PRIORITY 		= 1000

local mod = {}

-- Local Functions

--------------------------------------------------------------------------------
-- Switches to or from having FCPX Hacks commands editible inside FCPX.
--------------------------------------------------------------------------------
local function updateFCPXCommands(editable)
	--------------------------------------------------------------------------------
	-- Are we enabling or disabling?
	--------------------------------------------------------------------------------
	local enableOrDisableText = nil
	if not editable then
		enableOrDisableText = "Disabling"
	else
		enableOrDisableText = "Enabling"
	end

	--------------------------------------------------------------------------------
	-- If Final Cut Pro is running...
	--------------------------------------------------------------------------------
	local restartStatus = false
	if fcp:isRunning() then
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
	local result = nil
	if not editable then
		--------------------------------------------------------------------------------
		-- Disable Hacks Shortcut in Final Cut Pro:
		--------------------------------------------------------------------------------
		result = disableHacksShortcuts()
	else
		--------------------------------------------------------------------------------
		-- Enable Hacks Shortcut in Final Cut Pro:
		--------------------------------------------------------------------------------
		result = enableHacksShortcuts()
	end
	
	if not result then
		return result
	end

	--------------------------------------------------------------------------------
	-- Restart Final Cut Pro:
	--------------------------------------------------------------------------------
	if restartStatus and not fcp:restart() then
		--------------------------------------------------------------------------------
		-- Failed to restart Final Cut Pro:
		--------------------------------------------------------------------------------
		dialog.displayErrorMessage(i18n("failedToRestart"))
	end
	
	-- Reload Hammerspoon to reset shortcuts to defaults if necessary.
	hs.reload()
	
	return true
end

--------------------------------------------------------------------------------
-- ENABLE HACKS SHORTCUTS:
--------------------------------------------------------------------------------
local function enableHacksShortcuts()

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
	
	if type(result) == "string" then
		dialog.displayErrorMessage(result)
		mod.setEditable(false, true)
		return false
	elseif result == false then
		--------------------------------------------------------------------------------
		-- NOTE: When Cancel is pressed whilst entering the admin password, let's
		-- just leave the old Hacks Shortcut Plist files in place.
		--------------------------------------------------------------------------------
		return false
	end
	-- Success!
	return true
end

--------------------------------------------------------------------------------
-- DISABLE HACKS SHORTCUTS:
--------------------------------------------------------------------------------
local function disableHacksShortcuts()

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
	
	if type(result) == "string" then
		dialog.displayErrorMessage(result)
		mod.setEditable(true, true)
		return false
	elseif result == false then
		--------------------------------------------------------------------------------
		-- NOTE: When Cancel is pressed whilst entering the admin password, let's
		-- just leave the old Hacks Shortcut Plist files in place.
		--------------------------------------------------------------------------------
		return false
	end
	
	-- success!
	return true
end

local function applyShortcut(cmd, fcpxCmd)
	local modifiers = nil
	local keyCode = nil
	local keypadModifier = false

	if fcpxCmd["modifiers"] ~= nil then
		if string.find(fcpxCmd["modifiers"], "keypad") then keypadModifier = true end
		modifiers = kc.translateKeyboardModifiers(fcpxCmd["modifiers"])
	elseif fcpxCmd["modifierMask"] ~= nil then
		modifiers = kc.translateModifierMask(fcpxCmd["modifierMask"])
	end

	if fcpxCmd["characterString"] ~= nil then
		keyCode = kc.translateKeyboardCharacters(fcpxCmd["characterString"])
	elseif fcpxHacks["character"] ~= nil then
		if keypadModifier then
			keyCode = kc.translateKeyboardKeypadCharacters(fcpxCmd["character"])
		else
			keyCode = kc.translateKeyboardCharacters(fcpxCmd["character"])
		end
	end
	
	cmd:activatedBy(modifiers, keyCode)
end

local function applyCommandShortcut(cmd, commandSet)
	local id = cmd.id
	log.df("Processing '%s'...", id)
	-- First, remove existing hotkeys for the command
	cmd:clearHotkeys()
	
	-- Then see if we have a custom shortcut
	local csCmd = commandSet[id]
	if csCmd ~= nil then
		log.df("Applying FCPX shortcuts for '%s'", id)
		
		-- Then apply the new one(s)
		if type(csCmd[1]) == "table" then
			--------------------------------------------------------------------------------
			-- Multiple keyboard shortcuts for single function:
			--------------------------------------------------------------------------------
			for _,fcpxCmd in ipairs(csCmd) do
				applyShortcut(cmd, fcpxCmd)
			end
		else
			--------------------------------------------------------------------------------
			-- Single keyboard shortcut for a single function:
			--------------------------------------------------------------------------------
			applyShortcut(cmd, csCmd)
		end
	end
end

local function applyShortcuts(commands, commandSet)
	if commandSet ~= nil then
		log.df("Looping through all commands...")
		for id, cmd in pairs(commands:getAll()) do
			applyCommandShortcut(cmd, commandSet)
		end
		return true
	else
		return false
	end
end

local function applyCommandSetShortcuts()
	local commandSet = fcp:getActiveCommandSet(true)
	
	log.df("Applying FCPX Shortcuts to global commands...")
	applyShortcuts(mod.globalCmds, commandSet)
	log.df("Applying FCPX Shortcuts to FCPX commands...")
	applyShortcuts(mod.fcpxCmds, commandSet)
	
	mod.globalCmds:watch({
		add		= function(cmd) applyCommandShortcut(cmd, fcp:getActiveCommandSet()) end,
	})
	mod.fcpxCmds:watch({
		add		= function(cmd) applyCommandShortcut(cmd, fcp:getActiveCommandSet()) end,
	})
end

local function createMenuItem()
	--------------------------------------------------------------------------------
	-- Get Enable Hacks Shortcuts in Final Cut Pro from Settings:
	--------------------------------------------------------------------------------
	local hacksInFcpx = mod.isEditable()
	
	if hacksInFcpx then
		return { title = i18n("openCommandEditor"), fn = mod.editCommands, disabled = not fcp:isRunning() }
	else
		return { title = i18n("displayKeyboardShortcuts"), fn = mod.displayShortcutList }
	end
end

-- The Module

function mod.isEditable()
	return settings.get("fcpxHacks.enableHacksShortcutsInFinalCutPro") or false
end

function mod.setEditable(enabled, skipFCPXupdate)
	local editable = mod.isEditable()
	if editable ~= enabled then
		settings.set("fcpxHacks.enableHacksShortcutsInFinalCutPro", enabled)
		if not skipFCPXUpdate then
			if not updateFCPXCommands(enabled) then
				settings.set("fcpxHacks.enableHacksShortcutsInFinalCutPro", not enabled)
			end
		end
	end
end

function mod.toggleEditable()
	mod.setEditable(not mod.isEditable())
end

function mod.editCommands()
	fcp:launch()
	fcp:commandEditor():show()
end

--------------------------------------------------------------------------------
-- DISPLAY A LIST OF ALL SHORTCUTS:
--------------------------------------------------------------------------------
function mod.displayShortcutList()
	dialog.displayMessage(i18n("defaultShortcutsDescription"))
end

--------------------------------------------------------------------------------
-- READ SHORTCUT KEYS FROM FINAL CUT PRO PLIST:
--------------------------------------------------------------------------------
function mod.update()
	if mod.isEditable() then
		log.df("Applying FCPX Command Editor Shortcuts")
		applyCommandSetShortcuts()
	end
end

function mod.init()
	--------------------------------------------------------------------------------
	-- Check if we need to update the Final Cut Pro Shortcut Files:
	--------------------------------------------------------------------------------
	if settings.get("fcpxHacks.lastVersion") == nil then
		settings.set("fcpxHacks.lastVersion", metadata.scriptVersion)
		mod.setEditable(false)
	else
		if tonumber(settings.get("fcpxHacks.lastVersion")) < tonumber(metadata.scriptVersion) then
			if mod.isEditable() then
				dialog.displayMessage(i18n("newKeyboardShortcuts"))
				updateFCPXCommands(true)
			end
		end
		settings.set("fcpxHacks.lastVersion", metadata.scriptVersion)
	end
	
	mod.update()
end

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.top"] 			= "top",
	["hs.fcpxhacks.plugins.commands.global"]	= "globalCmds",
	["hs.fcpxhacks.plugins.commands.fcpx"]		= "fcpxCmds",
}

function plugin.init(deps)
	mod.globalCmds 	= deps.globalCmds
	mod.fcpxCmds	= deps.fcpxCmds
	
	mod.init()
	
	-- Add the menu item to the top section.
	deps.top:addItem(PRIORITY, createMenuItem)
	
	return mod
end

return plugin