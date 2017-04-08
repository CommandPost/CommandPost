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

--- core.preferences.general.toggleDisplayMenubarAsIcon() -> none
--- Function
--- Toggles the menubar display icon from icon to text value and vice versa.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleDisplayMenubarAsIcon()
	local displayMenubarAsIcon = config.get("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON)
	config.set("displayMenubarAsIcon", not displayMenubarAsIcon)
	mod.menuManager:updateMenubarIcon()
end

--- core.preferences.general.getDisplayMenubarAsIcon() -> boolean
--- Function
--- Returns whether the menubar is display as an icon or not.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if set to display the menubar as an icon other `false` if displaying menubar as text.
function mod.getDisplayMenubarAsIcon()
	return config.get("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON)
end

--- core.preferences.general.toggleAutoLaunch() -> boolean
--- Function
--- Toggles the "Launch on Login" status for CommandPost.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleAutoLaunch()
	hs.autoLaunch(not mod._autoLaunch)
	mod._autoLaunch = not mod._autoLaunch
end

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
		["finalcutpro.hacks.shortcuts"] 	= "hacksShortcuts",
	}
}
--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

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

	--------------------------------------------------------------------------------
	-- Setup General Preferences Panel:
	--------------------------------------------------------------------------------
	deps.general:addHeading(1, function()
		return { title = i18n("general") .. ":" }
	end)

	:addCheckbox(3, function()
		return { title = i18n("launchAtStartup"), fn = mod.toggleAutoLaunch, checked = mod._autoLaunch }
	end)

	:addHeading(50, function()
		return { title = "<br />" .. i18n("privacy") .. ":" }
	end)

	:addCheckbox(51, function()
		return { title = i18n("sendCrashData"),	fn = mod.toggleUploadCrashData, checked = mod._uploadCrashData }
	end)

	:addButton(52, function()
		return { title = i18n("openPrivacyPolicy"),	fn = mod.openPrivacyPolicy }
	end, 150)

	--------------------------------------------------------------------------------
	-- Setup Menubar Preferences Panel:
	--------------------------------------------------------------------------------
	deps.menubar:addHeading(20, function()
		return { title = i18n("appearance") .. ":" }
	end)

	:addCheckbox(21, function()
		return { title = i18n("displayThisMenuAsIcon"),	fn = mod.toggleDisplayMenubarAsIcon, checked = mod.getDisplayMenubarAsIcon() }
	end)

	:addHeading(24, function()
		return { title = "<br />" .. i18n("sections") .. ":" }
	end)

end

return plugin