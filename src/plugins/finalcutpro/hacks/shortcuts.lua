--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                H A C K S     S H O R T C U T S     P L U G I N             --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === finalcutpro.hacks.shortcuts ===
---
--- Plugin that allows the user to customise the CommandPost shortcuts
--- via the Final Cut Pro Command Editor.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log			= require("hs.logger").new("shortcuts")

local fs			= require("hs.fs")

local fcp			= require("cp.finalcutpro")
local dialog		= require("cp.dialog")
local config		= require("cp.config")
local tools			= require("cp.tools")

local v				= require("semver")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 		= 5

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- ENABLE HACKS SHORTCUTS:
--------------------------------------------------------------------------------
local function enableHacksShortcuts()

	log.df("Enabling Hacks Shortcuts...")

	local finalCutProPath = fcp:getPath() .. "/Contents/Resources/"
	local finalCutProLanguages = fcp:getSupportedLanguages()
	local executeCommand = "cp -f '" .. config.scriptPath .. "/cp/resources/plist/10.3/new/"

	local executeStrings = {
		executeCommand .. "NSProCommandGroups.plist' '" .. finalCutProPath .. "NSProCommandGroups.plist'",
		executeCommand .. "NSProCommands.plist' '" .. finalCutProPath .. "NSProCommands.plist'",
	}

	for _, whichLanguage in ipairs(finalCutProLanguages) do

		local whichDirectory = finalCutProPath .. whichLanguage .. ".lproj"
		if not tools.doesDirectoryExist(whichDirectory) then
			table.insert(executeStrings, "mkdir '" .. whichDirectory .. "'")
		end

		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/Default.commandset' '" .. finalCutProPath .. whichLanguage .. ".lproj/Default.commandset'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings' '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandNames.strings' '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandNames.strings'")
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
	local executeCommand = "cp -f '" .. config.scriptPath .. "/cp/resources/plist/10.3/old/"

	local executeStrings = {
		executeCommand .. "NSProCommandGroups.plist' '" .. finalCutProPath .. "NSProCommandGroups.plist'",
		executeCommand .. "NSProCommands.plist' '" .. finalCutProPath .. "NSProCommands.plist'",
	}

	for _, whichLanguage in ipairs(finalCutProLanguages) do

		local whichDirectory = finalCutProPath .. whichLanguage .. ".lproj"
		if not tools.doesDirectoryExist(whichDirectory) then
			table.insert(executeStrings, "mkdir '" .. whichDirectory .. "'")
		end

		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/Default.commandset' '" .. finalCutProPath .. whichLanguage .. ".lproj/Default.commandset'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings' '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandNames.strings' '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandNames.strings'")
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
-- UPDATE FINAL CUT PRO COMMANDS:
-- Switches to or from having CommandPost commands editible inside FCPX.
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

	return true
end

--------------------------------------------------------------------------------
-- APPLY SHORTCUTS:
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- APPLY COMMAND SET SHORTCUTS:
--------------------------------------------------------------------------------
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

--- finalcutpro.hacks.shortcuts.setEditable() -> none
--- Function
--- Enable Hacks Shortcuts
---
--- Parameters:
---  * enabled - True if you want to enable Hacks Shortcuts otherwise false
---  * skipFCPXupdate - Whether or not you want to skip reloading Final Cut Pro
---
--- Returns:
---  * `true` if Hacks Shortcuts are enabled otherwise `false`
function mod.isEditable()
	return config.get("enableHacksShortcutsInFinalCutPro", false)
end

--- finalcutpro.hacks.shortcuts.setEditable() -> none
--- Function
--- Enable Hacks Shortcuts
---
--- Parameters:
---  * enabled - True if you want to enable Hacks Shortcuts otherwise false
---  * skipFCPXupdate - Whether or not you want to skip reloading Final Cut Pro
---
--- Returns:
---  * None
function mod.setEditable(enabled, skipFCPXupdate)
	local editable = mod.isEditable()
	if editable ~= enabled then
		config.set("enableHacksShortcutsInFinalCutPro", enabled)
		if not skipFCPXUpdate then
			if not updateFCPXCommands(enabled) then
				config.set("enableHacksShortcutsInFinalCutPro", not enabled)
			end
		end
	end
end

--- finalcutpro.hacks.shortcuts.disableHacksShortcuts() -> none
--- Function
--- Disable Hacks Shortcuts
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
---
--- Notes:
---  * Used by Trash Preferences menubar command.
function mod.disableHacksShortcuts()
	disableHacksShortcuts()
end

--- finalcutpro.hacks.shortcuts.enableHacksShortcuts() -> none
--- Function
--- Enable Hacks Shortcuts
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.enableHacksShortcuts()
	return enableHacksShortcuts()
end

--- finalcutpro.hacks.shortcuts.toggleEditable() -> none
--- Function
--- Toggle Editable
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleEditable()
	mod.setEditable(not mod.isEditable())
end

--- finalcutpro.hacks.shortcuts.editCommands() -> none
--- Function
--- Launch the Final Cut Pro Command Editor
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.editCommands()
	fcp:launch()
	fcp:commandEditor():show()
end

--- finalcutpro.hacks.shortcuts.update() -> none
--- Function
--- Read shortcut keys from the Final Cut Pro Preferences.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
	if mod.isEditable() then
		log.df("Applying FCPX Command Editor Shortcuts")
		applyCommandSetShortcuts()
	end
end

--- finalcutpro.hacks.shortcuts.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()
	log.df("Initialising shortcuts...")
	--------------------------------------------------------------------------------
	-- Check if we need to update the Final Cut Pro Shortcut Files:
	--------------------------------------------------------------------------------
	local lastVersion = config.get("lastAppVersion")
	if lastVersion == nil or v(lastVersion) < v(config.appVersion) then
		if mod.isEditable() then
			dialog.displayMessage(i18n("newKeyboardShortcuts"))
			updateFCPXCommands(true)
		end
	end

	config.set("lastAppVersion", config.appVersion)

	mod.update()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.hacks.shortcuts",
	group			= "finalcutpro",
	dependencies	= {
		["core.menu.top"] 									= "top",
		["core.menu.helpandsupport"] 						= "helpandsupport",
		["core.commands.global"]							= "globalCmds",
		["finalcutpro.commands"]							= "fcpxCmds",
		["core.preferences.panels.shortcuts"]				= "shortcuts",
		["finalcutpro.preferences.panels.finalcutpro"]		= "finalcutpro",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	mod.globalCmds 	= deps.globalCmds
	mod.fcpxCmds	= deps.fcpxCmds

	mod._shortcuts	= deps.shortcuts

	--------------------------------------------------------------------------------
	-- Add the menu item to the top section:
	--------------------------------------------------------------------------------
	deps.top:addItem(PRIORITY, function()
		return { title = i18n("openCommandEditor"), fn = mod.editCommands, disabled = not fcp:isRunning() }
	end)

	--------------------------------------------------------------------------------
	-- Add Commands:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpOpenCommandEditor")
		:titled(i18n("openCommandEditor"))
		:whenActivated(mod.editCommands)

	--------------------------------------------------------------------------------
	-- Add Preferences:
	--------------------------------------------------------------------------------
	deps.finalcutpro:addHeading(50, i18n("keyboardShortcuts") .. ":")

	:addCheckbox(51,
		{
			label		= i18n("enableHacksShortcuts"),
			onchange	= function()
				mod.toggleEditable()
				mod._shortcuts.updateCustomShortcutsVisibility()
			end,
			checked=mod.isEditable
		}
	)

	return mod

end

return plugin