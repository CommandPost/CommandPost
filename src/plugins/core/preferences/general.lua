--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 P R E F E R E N C E S    P L U G I N                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === core.preferences.general ===
---
--- General Preferences Panel.

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

<<<<<<< HEAD
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
	mod.fcpShortcuts.disableHacksShortcuts()

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
=======
--- core.preferences.general.toggleDisplayMenubarAsIcon() -> none
--- Function
--- Toggles the menubar display icon from icon to text value and vice versa.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
>>>>>>> develop
function mod.toggleDisplayMenubarAsIcon()
	local displayMenubarAsIcon = config.get("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON)
	config.set("displayMenubarAsIcon", not displayMenubarAsIcon)
	mod.menuManager:updateMenubarIcon()
end

<<<<<<< HEAD
--------------------------------------------------------------------------------
-- GET DEVELOPER MODE VALUE:
--------------------------------------------------------------------------------
function mod.getDeveloperMode()
	return config.get("debugMode")
end

--------------------------------------------------------------------------------
-- GET DISPLAY MENUBAR AS ICON VALUE:
--------------------------------------------------------------------------------
=======
--- core.preferences.general.getDisplayMenubarAsIcon() -> boolean
--- Function
--- Returns whether the menubar is display as an icon or not.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if set to display the menubar as an icon other `false` if displaying menubar as text.
>>>>>>> develop
function mod.getDisplayMenubarAsIcon()
	return config.get("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON)
end

<<<<<<< HEAD
--------------------------------------------------------------------------------
-- TOGGLE AUTO LAUNCH:
--------------------------------------------------------------------------------
=======
--- core.preferences.general.toggleAutoLaunch() -> boolean
--- Function
--- Toggles the "Launch on Login" status for CommandPost.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
>>>>>>> develop
function mod.toggleAutoLaunch()
	hs.autoLaunch(not mod._autoLaunch)
	mod._autoLaunch = not mod._autoLaunch
end
<<<<<<< HEAD
=======

--- core.preferences.general.toggleUploadCrashData() -> boolean
--- Function
--- Toggles the "Upload Crash Data" status for CommandPost.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleUploadCrashData()
	hs.uploadCrashData(not mod._uploadCrashData)
	mod._uploadCrashData = not mod._uploadCrashData
end

--- core.preferences.general.openPrivacyPolicy() -> none
--- Function
--- Opens the CommandPost Privacy Policy in your browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.openPrivacyPolicy()
	hs.execute("open 'https://help.commandpost.io/privacy-policy.html'")
end
>>>>>>> develop

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
<<<<<<< HEAD
		["finalcutpro.hacks.shortcuts"]		= "fcpShortcuts",
=======
		["finalcutpro.hacks.shortcuts"] 	= "hacksShortcuts",
>>>>>>> develop
	}
}
--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

<<<<<<< HEAD
	mod.menuManager = deps.menuManager
	mod.fcpShortcuts = deps.fcpShortcuts

	--------------------------------------------------------------------------------
	-- Cache Auto Launch:
	--------------------------------------------------------------------------------
	mod._autoLaunch = hs.autoLaunch()
=======
	--------------------------------------------------------------------------------
	-- Setup Dependencies:
	--------------------------------------------------------------------------------
	mod.menuManager 		= deps.menuManager
	mod.hacksShortcuts 		= deps.hacksShortcuts

	--------------------------------------------------------------------------------
	-- Cache Values:
	--------------------------------------------------------------------------------
	mod._autoLaunch 		= hs.autoLaunch()
	mod._uploadCrashData 	= hs.uploadCrashData()
>>>>>>> develop

	--------------------------------------------------------------------------------
	-- Setup General Preferences Panel:
	--------------------------------------------------------------------------------
	deps.general:addHeading(1, function()
<<<<<<< HEAD
		return { title = "General:" }
=======
		return { title = i18n("general") .. ":" }
>>>>>>> develop
	end)

	:addCheckbox(3, function()
		return { title = i18n("launchAtStartup"), fn = mod.toggleAutoLaunch, checked = mod._autoLaunch }
	end)

	:addHeading(50, function()
<<<<<<< HEAD
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
=======
		return { title = "<br />" .. i18n("privacy") .. ":" }
	end)

	:addCheckbox(51, function()
		return { title = i18n("sendCrashData"),	fn = mod.toggleUploadCrashData, checked = mod._uploadCrashData }
	end)

	:addButton(52, function()
		return { title = i18n("openPrivacyPolicy"),	fn = mod.openPrivacyPolicy }
>>>>>>> develop
	end, 150)

	--------------------------------------------------------------------------------
	-- Setup Menubar Preferences Panel:
	--------------------------------------------------------------------------------
	deps.menubar:addHeading(20, function()
<<<<<<< HEAD
		return { title = "Appearance:" }
=======
		return { title = i18n("appearance") .. ":" }
>>>>>>> develop
	end)

	:addCheckbox(21, function()
		return { title = i18n("displayThisMenuAsIcon"),	fn = mod.toggleDisplayMenubarAsIcon, checked = mod.getDisplayMenubarAsIcon() }
	end)

	:addHeading(24, function()
<<<<<<< HEAD
		return { title = "<br />Sections:" }
=======
		return { title = "<br />" .. i18n("sections") .. ":" }
>>>>>>> develop
	end)

end

return plugin