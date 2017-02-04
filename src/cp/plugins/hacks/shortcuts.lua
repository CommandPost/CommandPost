-- Imports

local settings		= require("hs.settings")
local fs			= require("hs.fs")

local fcp			= require("cp.finalcutpro")
local dialog		= require("cp.dialog")
local metadata		= require("cp.metadata")
local tools			= require("cp.tools")

local log			= require("hs.logger").new("shortcuts")

-- Constants

local PRIORITY 		= 1000

local mod = {}

-- Local Functions

--------------------------------------------------------------------------------
-- ENABLE HACKS SHORTCUTS:
--------------------------------------------------------------------------------
local function enableHacksShortcuts()

	local finalCutProPath = fcp:getPath() .. "/Contents/Resources/"
	local finalCutProLanguages = fcp:getSupportedLanguages()
	local executeCommand = "cp -f " .. metadata.scriptPath .. "/cp/resources/plist/10.3/new/"

	local executeStrings = {
		executeCommand .. "NSProCommandGroups.plist '" .. finalCutProPath .. "NSProCommandGroups.plist'",
		executeCommand .. "NSProCommands.plist '" .. finalCutProPath .. "NSProCommands.plist'",
	}

	for _, whichLanguage in ipairs(finalCutProLanguages) do

		local whichDirectory = finalCutProPath .. whichLanguage .. ".lproj"
		if not tools.doesDirectoryExist(whichDirectory) then
			table.insert(executeStrings, "mkdir '" .. whichDirectory .. "'")
		end

		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/Default.commandset '" .. finalCutProPath .. whichLanguage .. ".lproj/Default.commandset'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandNames.strings '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandNames.strings'")
	end

	local result = tools.executeWithAdministratorPrivileges(executeStrings, false)

	if type(result) == "string" then
		log.wf("The following error(s) occurred:\n\n" .. result .. "However, Hacks Shortcuts were still enabled.")
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
	local executeCommand = "cp -f " .. metadata.scriptPath .. "/cp/resources/plist/10.3/old/"

	local executeStrings = {
		executeCommand .. "NSProCommandGroups.plist '" .. finalCutProPath .. "NSProCommandGroups.plist'",
		executeCommand .. "NSProCommands.plist '" .. finalCutProPath .. "NSProCommands.plist'",
	}

	for _, whichLanguage in ipairs(finalCutProLanguages) do

		local whichDirectory = finalCutProPath .. whichLanguage .. ".lproj"
		if not tools.doesDirectoryExist(whichDirectory) then
			table.insert(executeStrings, "mkdir '" .. whichDirectory .. "'")
		end

		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/Default.commandset '" .. finalCutProPath .. whichLanguage .. ".lproj/Default.commandset'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandNames.strings '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandNames.strings'")
	end

	local result = tools.executeWithAdministratorPrivileges(executeStrings, false)

	if type(result) == "string" then
		log.wf("The following error(s) occurred:\n\n" .. result .. "However, Hacks Shortcuts were still disabled.")
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
			return false
		end
	else
		if not dialog.displayYesNoQuestion(enableOrDisableText .. " " .. i18n("hacksShortcutAdminPassword") .. " " .. i18n("doYouWantToContinue")) then
			return false
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
	--hs.reload()

	return true
end

local function applyShortcuts(commands, commandSet)
	commands:deleteShortcuts()
	if commandSet ~= nil then
		for id, cmd in pairs(commands:getAll()) do
			local shortcuts = fcp:getCommandShortcuts(id)
			if shortcuts ~= nil then
				cmd:setShortcuts(shortcuts)
			end
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
	return settings.get(metadata.settingsPrefix .. ".enableHacksShortcutsInFinalCutPro") or false
end

function mod.setEditable(enabled, skipFCPXupdate)
	local editable = mod.isEditable()
	if editable ~= enabled then
		settings.set(metadata.settingsPrefix .. ".enableHacksShortcutsInFinalCutPro", enabled)
		if not skipFCPXUpdate then
			if not updateFCPXCommands(enabled) then
				settings.set(metadata.settingsPrefix .. ".enableHacksShortcutsInFinalCutPro", not enabled)
			end
		end
	end
end

-- Used by Trash Preferences menubar command:
function mod.disableHacksShortcuts()
	disableHacksShortcuts()
end

function mod.enableHacksShortcuts()
	enableHacksShortcuts()
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
	log.df("Initialising shortcuts...")
	--------------------------------------------------------------------------------
	-- Check if we need to update the Final Cut Pro Shortcut Files:
	--------------------------------------------------------------------------------
	if settings.get(metadata.settingsPrefix .. ".lastVersion") == nil then
		settings.set(metadata.settingsPrefix .. ".lastVersion", metadata.scriptVersion)
		mod.setEditable(false)
	else
		if tonumber(settings.get(metadata.settingsPrefix .. ".lastVersion")) < tonumber(metadata.scriptVersion) then
			if mod.isEditable() then
				dialog.displayMessage(i18n("newKeyboardShortcuts"))
				updateFCPXCommands(true)
			end
		end
		settings.set(metadata.settingsPrefix .. ".lastVersion", metadata.scriptVersion)
	end

	mod.update()
end

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.top"] 			= "top",
	["cp.plugins.commands.global"]	= "globalCmds",
	["cp.plugins.commands.fcpx"]		= "fcpxCmds",
}

function plugin.init(deps)
	mod.globalCmds 	= deps.globalCmds
	mod.fcpxCmds	= deps.fcpxCmds

	-- Add the menu item to the top section.
	deps.top:addItem(PRIORITY, createMenuItem)

	-- Add Commands
	deps.globalCmds:add("FCPXHackShowListOfShortcutKeys")
		:activatedBy():ctrl():option():cmd("f1")
		:whenActivated(mod.displayShortcutList)

	deps.fcpxCmds:add("FCPXHackOpenCommandEditor")
		:titled(i18n("openCommandEditor"))
		:whenActivated(mod.editCommands)

	return mod
end

function plugin.postInit(deps)
	mod.init()
end

return plugin