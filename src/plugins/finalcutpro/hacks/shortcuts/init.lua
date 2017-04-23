--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                H A C K S     S H O R T C U T S     P L U G I N             --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.hacks.shortcuts ===
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

local fcp			= require("cp.apple.finalcutpro")
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

	local finalCutProVersion = fcp:getVersion()

	if not finalCutProVersion then
		dialog.displayMessage("The Final Cut Pro version could not be detected.\n\nThis shouldn't happen, so something has broken.")
		log.ef("No Final Cut Pro Version was detected. This shouldn't happen.")
		return nil
	end

	local whichVersion = "10.3.2"
	if v(finalCutProVersion) <= v("10.3.3") then
		whichVersion = "10.3.3"
	end

	local finalCutProPath = fcp:getPath() .. "/Contents/Resources/"
	local finalCutProLanguages = fcp:getSupportedLanguages()

	local executeStrings = {}

	--------------------------------------------------------------------------------
	-- First we copy the original Final Cut Pro files, just in case the user has
	-- previously removed them or used an old version of CommandPost or FCPX Hacks:
	--------------------------------------------------------------------------------

	local executeCommand = "cp -f '" .. mod.commandSetsPath .. "/" .. whichVersion .. "/original/"

	table.insert(executeStrings, executeCommand .. "NSProCommandGroups.plist' '" .. finalCutProPath .. "NSProCommandGroups.plist'")
	table.insert(executeStrings, executeCommand .. "NSProCommands.plist' '" .. finalCutProPath .. "NSProCommands.plist'")

	for _, whichLanguage in ipairs(finalCutProLanguages) do

		local whichDirectory = finalCutProPath .. whichLanguage .. ".lproj"
		if not tools.doesDirectoryExist(whichDirectory) then
			table.insert(executeStrings, "mkdir '" .. whichDirectory .. "'")
		end

		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/Default.commandset' '" .. finalCutProPath .. whichLanguage .. ".lproj/Default.commandset'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings' '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandDescriptions.strings'")
		table.insert(executeStrings, executeCommand .. whichLanguage .. ".lproj/NSProCommandNames.strings' '" .. finalCutProPath .. whichLanguage .. ".lproj/NSProCommandNames.strings'")
	end

	--------------------------------------------------------------------------------
	-- Only then do we copy the 'modified' files...
	--------------------------------------------------------------------------------

	local executeCommand = "cp -f '" .. mod.commandSetsPath .. "/" .. whichVersion .. "/modified/"

	table.insert(executeStrings, executeCommand .. "NSProCommandGroups.plist' '" .. finalCutProPath .. "NSProCommandGroups.plist'")
	table.insert(executeStrings, executeCommand .. "NSProCommands.plist' '" .. finalCutProPath .. "NSProCommands.plist'")

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

	if result == false then
		-- Cancel button pressed:
		return false
	end

	if type(result) == "string" then
		log.ef("The following error(s) occurred: %s", result)
		config.set("enableHacksShortcutsInFinalCutPro", false)
		return false
	end

	-- Success!
	config.set("enableHacksShortcutsInFinalCutPro", true)
	return true

end

--------------------------------------------------------------------------------
-- DISABLE HACKS SHORTCUTS:
--------------------------------------------------------------------------------
local function disableHacksShortcuts()

	log.df("Disabling Hacks Shortcuts...")

	local finalCutProVersion = fcp:getVersion()

	local whichVersion = "10.3.2"
	if v(finalCutProVersion) <= v("10.3.3") then
		whichVersion = "10.3.3"
	end

	log.df("Final Cut Pro Version: %s", whichVersion)

	local finalCutProPath = fcp:getPath() .. "/Contents/Resources/"
	local finalCutProLanguages = fcp:getSupportedLanguages()

	local executeCommand = "cp -f '" .. mod.commandSetsPath .. "/" .. whichVersion .. "/original/"

	local executeStrings = {}

	table.insert(executeStrings, executeCommand .. "NSProCommandGroups.plist' '" .. finalCutProPath .. "NSProCommandGroups.plist'")
	table.insert(executeStrings, executeCommand .. "NSProCommands.plist' '" .. finalCutProPath .. "NSProCommands.plist'")

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

	if result == false then
		-- Cancel button pressed:
		return false
	end

	if type(result) == "string" then
		log.ef("The following error(s) occurred: %s", result)
		config.set("enableHacksShortcutsInFinalCutPro", true)
		return false
	end

	-- Success!
	config.set("enableHacksShortcutsInFinalCutPro", false)
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

--- plugins.finalcutpro.hacks.shortcuts.enabled() -> none
--- Function
--- Are Hacks Shortcuts Enabled?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Hacks Shortcuts are enabled otherwise `false`
function mod.enabled()

	if fcp:application() then
		local searchString = "<key>cpToggleMovingMarkers</key>"
		local filePathNSProCommands = fcp:getPath() .. "/Contents/Resources/NSProCommands.plist"

		if tools.doesFileExist(filePathNSProCommands) then

			local file = io.open(filePathNSProCommands, "r")
			if file then

				io.input(file)
				local fileContents = io.read("*a")
				io.close(file)

				local result = string.find(fileContents, searchString) ~= nil

				config.set("enableHacksShortcutsInFinalCutPro", result)
				return result

			end
		end

		log.ef("Could not find NSProCommands.plist. This shouldn't ever happen.")
		config.set("enableHacksShortcutsInFinalCutPro", false)
	end
	return false

end

--- plugins.finalcutpro.hacks.shortcuts.setEditable() -> none
--- Function
--- Enable Hacks Shortcuts
---
--- Parameters:
---  * enabled - True if you want to enable Hacks Shortcuts otherwise false
---  * skipFCPXupdate - Whether or not you want to skip reloading Final Cut Pro
---
--- Returns:
---  * None
function mod.setEnabled(enabled, skipFCPXupdate)
	local editable = mod.enabled()
	if editable ~= enabled then
		if not skipFCPXUpdate then
			updateFCPXCommands(enabled)
		end
	end
end

--- plugins.finalcutpro.hacks.shortcuts.disableHacksShortcuts() -> none
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

--- plugins.finalcutpro.hacks.shortcuts.enableHacksShortcuts() -> none
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

--- plugins.finalcutpro.hacks.shortcuts.toggleEditable() -> none
--- Function
--- Toggle Editable
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleEditable()
	mod.setEnabled(not mod.enabled())
end

--- plugins.finalcutpro.hacks.shortcuts.editCommands() -> none
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

--- plugins.finalcutpro.hacks.shortcuts.update() -> none
--- Function
--- Read shortcut keys from the Final Cut Pro Preferences.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
	if mod.enabled() then
		log.df("Applying FCPX Command Editor Shortcuts")
		applyCommandSetShortcuts()
	end
end

--- plugins.finalcutpro.hacks.shortcuts.init() -> none
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
		if mod.enabled() then
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
		["finalcutpro.preferences.panels.finalcutpro"]		= "prefs",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	mod.globalCmds 	= deps.globalCmds
	mod.fcpxCmds	= deps.fcpxCmds

	mod._shortcuts	= deps.shortcuts

	mod.commandSetsPath = env:pathToAbsolute("/") .. "/commandsets/"

	--------------------------------------------------------------------------------
	-- Add the menu item to the top section:
	--------------------------------------------------------------------------------
	deps.top:addItem(PRIORITY, function()
		if fcp:isInstalled()  then
			return { title = i18n("openCommandEditor"), fn = mod.editCommands, disabled = not fcp:isRunning() }
		end
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
	if deps.prefs.panel then
		deps.prefs.panel:addHeading(50, i18n("keyboardShortcuts"))

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
	end

	return mod

end

return plugin