--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 P R E F E R E N C E S    P L U G I N                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.advanced ===
---
--- Advanced Preferences Panel.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("prefadv")

local console			= require("hs.console")
local dialog			= require("hs.dialog")
local ipc				= require("hs.ipc")

local config			= require("cp.config")
local fcp				= require("cp.apple.finalcutpro")
local html				= require("cp.web.html")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.advanced.trashPreferences() -> none
--- Function
--- Resets all of the CommandPost Preferences to their default values.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.trashPreferences()

	dialog.webviewAlert(mod.manager.getWebview(), function(result)
		if result == i18n("yes") then
			config.reset()
		end
	end, i18n("trashPreferencesConfirmation"), "", i18n("yes"), i18n("no"), "informational")

end

--- plugins.core.preferences.advanced.developerMode <cp.prop: boolean>
--- Field
--- Enables or disables developer mode.
mod.developerMode = config.developerMode:watch(function()
	mod.manager.hide()
end)

--- plugins.core.preferences.advanced.toggleDeveloperMode() -> none
--- Function
--- Toggles the Developer Mode.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleDeveloperMode()

	dialog.webviewAlert(mod.manager.getWebview(), function(result)
		if result == i18n("yes") then
			mod.developerMode:toggle()
		end
		mod.manager.refresh()
	end, i18n("togglingDeveloperMode"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")

end

--- plugins.core.preferences.advanced.openErrorLog() -> none
--- Function
--- Opens the Error Log
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.openErrorLog()
	hs.openConsole()
end

--
-- Get Command Line Tool Title:
--
local function getCommandLineToolTitle()
	local cliStatus = ipc.cliStatus()
	if cliStatus then
		return i18n("uninstall")
	else
		return i18n("install")
	end
end

--- plugins.core.preferences.advanced.toggleCommandLineTool() -> none
--- Function
--- Toggles the Command Line Tool
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleCommandLineTool()

	local cliStatus = ipc.cliStatus()
	if cliStatus then
		--log.df("Uninstalling Command Line Tool")
		ipc.cliUninstall()
	else
		--log.df("Installing Command Line Tool")
		ipc.cliInstall()
	end

	local newCliStatus = ipc.cliStatus()
	if cliStatus == newCliStatus then
		if cliStatus then
			dialog.webviewAlert(mod.manager.getWebview(), function()
				mod.manager.refresh()
			end, i18n("cliUninstallError"), "", i18n("ok"), nil, "informational")
		else
			dialog.webviewAlert(mod.manager.getWebview(), function()
				mod.manager.refresh()
			end, i18n("cliInstallError"), "", i18n("ok"), nil, "informational")
		end
	else
		mod.manager.refresh()
	end

end

mod.openErrorLogOnDockClick = config.prop("openErrorLogOnDockClick", false)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.preferences.advanced",
	group			= "core",
	dependencies	= {
		["core.preferences.panels.advanced"]	= "advanced",
		["core.preferences.manager"]			= "manager",
		["core.commands.global"] 				= "global",
	}
}
--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	mod.manager = deps.manager

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	local global = deps.global
	global:add("cpOpenErrorLog")
		:whenActivated(mod.openErrorLog)
		:groupedBy("commandPost")

	global:add("cpTrashPreferences")
		:whenActivated(mod.trashPreferences)
		:groupedBy("commandPost")

	--------------------------------------------------------------------------------
	-- Create Dock Icon Click Callback:
	--------------------------------------------------------------------------------
	config.dockIconClickCallback:new("cp", function()
		if mod.openErrorLogOnDockClick() then hs.openConsole() end
	end)

	--------------------------------------------------------------------------------
	-- Setup General Preferences Panel:
	--------------------------------------------------------------------------------
	deps.advanced

		:addHeading(60, i18n("developer"))

		:addCheckbox(61,
			{
				label = i18n("enableDeveloperMode"),
				onchange = mod.toggleDeveloperMode,
				checked = mod.developerMode,
			}
		)

		:addHeading(62, i18n("errorLog"))

		:addCheckbox(63,
			{
				label = i18n("openErrorLogOnDockClick"),
				onchange = function() mod.openErrorLogOnDockClick:toggle() end,
				checked = mod.openErrorLogOnDockClick
			}
		)

		:addButton(64,
			{
				label = i18n("openErrorLog"),
				width = 150,
				onclick = mod.openErrorLog,
			}
		)

		:addHeading(70, i18n("commandLineTool"))
		:addButton(75,
			{
				label	= getCommandLineToolTitle(),
				width	= 150,
				onclick	= mod.toggleCommandLineTool,
				id		= "commandLineTool",
			}
		)
		:addParagraph(76, [[<span class="tip">]]  .. "<strong>" .. string.upper(i18n("tip")) .. ": </strong>" .. i18n("commandLineToolDescription") .. "</span>", true)

		:addHeading(80, i18n("advanced"))
		:addButton(85,
			{
				label	= i18n("trashPreferences"),
				width	= 150,
				onclick	= mod.trashPreferences,
			}
		)
		:addParagraph(85.1, [[<span class="tip">]]  .. "<strong>" .. string.upper(i18n("tip")) .. ": </strong>" ..  i18n("trashPreferencesDescription") .. "</span>", true)

end

return plugin