--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 P R E F E R E N C E S    P L U G I N                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("preferences")

local application		= require("hs.application")
local console			= require("hs.console")

local metadata			= require("cp.config")
local fcp				= require("cp.finalcutpro")
local dialog			= require("cp.dialog")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local DEFAULT_DISPLAY_MENUBAR_AS_ICON 	= true
local DEFAULT_ENABLE_PROXY_MENU_ICON 	= false

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	--------------------------------------------------------------------------------
	-- RESET SETTINGS:
	--------------------------------------------------------------------------------
	function mod.resetSettings()

		local finalCutProRunning = fcp:isRunning()

		local resetMessage = i18n("trashPreferences")
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
		plugins("cp.plugins.finalcutpro.hacks.shortcuts").disableHacksShortcuts()

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
		console.clearConsole()
		hs.reload()

	end

	--------------------------------------------------------------------------------
	-- TOGGLE DEVELOPER MODE:
	--------------------------------------------------------------------------------
	function mod.toggleDeveloperMode()
		local debugMode = metadata.get("debugMode")
		metadata.set("debugMode", not debugMode)
		console.clearConsole()
		hs.reload()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE ENABLE PROXY MENU ICON:
	--------------------------------------------------------------------------------
	function mod.toggleEnableProxyMenuIcon()
		local enableProxyMenuIcon = metadata.get("enableProxyMenuIcon", DEFAULT_ENABLE_PROXY_MENU_ICON)
		metadata.set("enableProxyMenuIcon", not enableProxyMenuIcon)
		mod.menuManager:updateMenubarIcon()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE DISPLAY MENUBAR AS ICON:
	--------------------------------------------------------------------------------
	function mod.toggleDisplayMenubarAsIcon()
		local displayMenubarAsIcon = metadata.get("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON)
		metadata.set("displayMenubarAsIcon", not displayMenubarAsIcon)
		mod.menuManager:updateMenubarIcon()
	end

	--------------------------------------------------------------------------------
	-- GET DEVELOPER MODE VALUE:
	--------------------------------------------------------------------------------
	function mod.getDeveloperMode()
		return metadata.get("debugMode")
	end

	--------------------------------------------------------------------------------
	-- GET ENABLE PROXY MENU ICON VALUE:
	--------------------------------------------------------------------------------
	function mod.getEnableProxyMenuIcon()
		return metadata.get("enableProxyMenuIcon", DEFAULT_ENABLE_PROXY_MENU_ICON)
	end

	--------------------------------------------------------------------------------
	-- GET DISPLAY MENUBAR AS ICON VALUE:
	--------------------------------------------------------------------------------
	function mod.getDisplayMenubarAsIcon()
		return metadata.get("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE AUTO LAUNCH:
	--------------------------------------------------------------------------------
	function mod.toggleAutoLaunch()
		hs.autoLaunch(not mod._autoLaunch)
		mod._autoLaunch = not mod._autoLaunch
	end

--------------------------------------------------------------------------------
--- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.preferences.general",
	group			= "core",
	dependencies	= {
		["core.preferences.panels.general"]	= "general",
		["core.preferences.panels.menubar"]	= "menubar",
		["core.menu.manager"]				= "menuManager",
	}
}
	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)

		mod.menuManager = deps.menuManager

		--------------------------------------------------------------------------------
		-- Cache Auto Launch:
		--------------------------------------------------------------------------------
		mod._autoLaunch = hs.autoLaunch()

		--------------------------------------------------------------------------------
		-- Setup General Preferences Panel:
		--------------------------------------------------------------------------------
		deps.general:addHeading(1, function()
			return { title = "General:" }
		end)

		:addCheckbox(3, function()
			return { title = i18n("launchAtStartup"), fn = mod.toggleAutoLaunch, checked = mod._autoLaunch }
		end)

		:addHeading(50, function()
			return { title = "<br />Developer:" }
		end)

		:addCheckbox(51, function()
			return { title = i18n("enableDeveloperMode"),	fn = mod.toggleDeveloperMode, checked = mod.getDeveloperMode() }
		end)

		:addButton(52, function()
			return { title = i18n("openErrorLog"),	fn = function() hs.openConsole() end }
		end)

		:addButton(53, function()
			return { title = i18n("trashPreferences"),	fn = mod.resetSettings }
		end)

		--------------------------------------------------------------------------------
		-- Setup Menubar Preferences Panel:
		--------------------------------------------------------------------------------
		deps.menubar:addHeading(20, function()
			return { title = "Appearance:" }
		end)

		:addCheckbox(21, function()
			return { title = i18n("displayThisMenuAsIcon"),	fn = mod.toggleDisplayMenubarAsIcon, checked = mod.getDisplayMenubarAsIcon() }
		end)

		:addHeading(24, function()
			return { title = "<br />Sections:" }
		end)

		:addHeading(30, function()
			return { title = "<br />Final Cut Pro:" }
		end)

		:addCheckbox(31, function()
			return { title = i18n("displayProxyOriginalIcon"),	fn = mod.toggleEnableProxyMenuIcon, checked = mod.getEnableProxyMenuIcon() }
		end)

	end

return plugin