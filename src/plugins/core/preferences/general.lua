--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 P R E F E R E N C E S    P L U G I N                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("preferences")

local application		= require("hs.application")
local console			= require("hs.console")

local config			= require("cp.config")
local fcp				= require("cp.finalcutpro")
local dialog			= require("cp.dialog")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local DEFAULT_DISPLAY_MENUBAR_AS_ICON 	= true

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
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
		config.reset()

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
		local debugMode = config.get("debugMode")
		config.set("debugMode", not debugMode)
		console.clearConsole()
		hs.reload()
	end

	--------------------------------------------------------------------------------
	-- TOGGLE DISPLAY MENUBAR AS ICON:
	--------------------------------------------------------------------------------
	function mod.toggleDisplayMenubarAsIcon()
		local displayMenubarAsIcon = config.get("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON)
		config.set("displayMenubarAsIcon", not displayMenubarAsIcon)
		mod.menuManager:updateMenubarIcon()
	end

	--------------------------------------------------------------------------------
	-- GET DEVELOPER MODE VALUE:
	--------------------------------------------------------------------------------
	function mod.getDeveloperMode()
		return config.get("debugMode")
	end

	--------------------------------------------------------------------------------
	-- GET DISPLAY MENUBAR AS ICON VALUE:
	--------------------------------------------------------------------------------
	function mod.getDisplayMenubarAsIcon()
		return config.get("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON)
	end

	--------------------------------------------------------------------------------
	-- TOGGLE AUTO LAUNCH:
	--------------------------------------------------------------------------------
	function mod.toggleAutoLaunch()
		hs.autoLaunch(not mod._autoLaunch)
		mod._autoLaunch = not mod._autoLaunch
	end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
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
		end, 150)

		:addButton(53, function()
			return { title = i18n("trashPreferences"),	fn = mod.resetSettings }
		end, 150)

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

	end

return plugin