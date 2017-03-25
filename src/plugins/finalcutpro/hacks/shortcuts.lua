--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                H A C K S     S H O R T C U T S     P L U G I N             --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log			= require("hs.logger").new("shortcuts")

local fs			= require("hs.fs")

local fcp			= require("cp.finalcutpro")
local dialog		= require("cp.dialog")
local metadata		= require("cp.config")
local tools			= require("cp.tools")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local PRIORITY 		= 5
local ADVANCED_FEATURES_PRIORITY = 1

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	--------------------------------------------------------------------------------
	-- ENABLE HACKS SHORTCUTS:
	--------------------------------------------------------------------------------
	local function enableHacksShortcuts()

		log.df("Enabling Hacks Shortcuts...")

		local finalCutProPath = fcp:getPath() .. "/Contents/Resources/"
		local finalCutProLanguages = fcp:getSupportedLanguages()
		local executeCommand = "cp -f '" .. metadata.scriptPath .. "cp/resources/plist/10.3/new/"

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
		local executeCommand = "cp -f '" .. metadata.scriptPath .. "cp/resources/plist/10.3/old/"

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

	function mod.isEditable()
		return metadata.get("enableHacksShortcutsInFinalCutPro", false)
	end

	function mod.setEditable(enabled, skipFCPXupdate)
		local editable = mod.isEditable()
		if editable ~= enabled then
			metadata.set("enableHacksShortcutsInFinalCutPro", enabled)
			if not skipFCPXUpdate then
				if not updateFCPXCommands(enabled) then
					metadata.set("enableHacksShortcutsInFinalCutPro", not enabled)
				end
			end
		end
	end

	-- Used by Trash Preferences menubar command:
	function mod.disableHacksShortcuts()
		disableHacksShortcuts()
	end

	function mod.enableHacksShortcuts()
		return enableHacksShortcuts()
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
		local lastVersion = metadata.get("lastScriptVersion")
		if lastVersion == nil then
			mod.setEditable(false)
		elseif tonumber(lastVersion) < tonumber(metadata.scriptVersion) then
			if mod.isEditable() then
				dialog.displayMessage(i18n("newKeyboardShortcuts"))
				updateFCPXCommands(true)
			end
		end

		metadata.set("lastScriptVersion", metadata.scriptVersion)

		mod.update()
	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.hacks.shortcuts",
	group			= "finalcutpro",
	dependencies	= {
		["core.menu.top"] 							= "top",
		["core.menu.helpandsupport"] 				= "helpandsupport",
		["core.commands.global"]					= "globalCmds",
		["finalcutpro.commands"]					= "fcpxCmds",
		["core.preferences.panels.shortcuts"]		= "shortcuts",
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

		deps.helpandsupport:addItem(1.1, function()
			if not mod.isEditable() then
				return { title = i18n("displayKeyboardShortcuts"), fn = mod.displayShortcutList }
			end
		end)

		--------------------------------------------------------------------------------
		-- Add Commands:
		--------------------------------------------------------------------------------
		deps.globalCmds:add("cpShowListOfShortcutKeys")
			:activatedBy():ctrl():option():cmd("f1")
			:whenActivated(mod.displayShortcutList)

		deps.fcpxCmds:add("cpOpenCommandEditor")
			:titled(i18n("openCommandEditor"))
			:whenActivated(mod.editCommands)

		deps.shortcuts:addCheckbox(ADVANCED_FEATURES_PRIORITY, function()
			return { title = i18n("enableHacksShortcuts"),	fn = function()
				mod.toggleEditable()
				mod._shortcuts.updateCustomShortcutsVisibility()
			end, checked=mod.isEditable() }
		end)

		return mod

	end

return plugin