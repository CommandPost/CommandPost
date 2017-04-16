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
	config.set("displayMenubarAsIcon", not mod.getDisplayMenubarAsIcon())
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

	--------------------------------------------------------------------------------
	-- Cache Values:
	--------------------------------------------------------------------------------
	mod._autoLaunch 		= hs.autoLaunch()
	mod._uploadCrashData 	= hs.uploadCrashData()

	--------------------------------------------------------------------------------
	-- Setup General Preferences Panel:
	--------------------------------------------------------------------------------
	deps.general:addHeading(1, i18n("general") .. ":")

	:addCheckbox(3,
		{ 
			label		= i18n("launchAtStartup"),
			checked		= hs.autoLaunch,
			onchange	= function(id, params) hs.autoLaunch(params.checked) end,
		}
	)

	:addHeading(50, i18n("privacy") .. ":" )

	:addCheckbox(51,
		{
			label		= i18n("sendCrashData"),	
			checked		= hs.uploadCrashData,
			onchange	= function(id, params) hs.uploadCrashData(params.checked) end,
		}
	)

	:addButton(52,
		{
			label 		= i18n("openPrivacyPolicy"),
			width		= 150,
			onclick		= mod.openPrivacyPolicy,
		}
	)

	-- --------------------------------------------------------------------------------
	-- -- Setup Menubar Preferences Panel:
	-- --------------------------------------------------------------------------------
	deps.menubar:addHeading(20, i18n("appearance") .. ":")

	:addCheckbox(21,
		{
			label = i18n("displayThisMenuAsIcon"),	
			onchange = mod.toggleDisplayMenubarAsIcon,
			checked = mod.getDisplayMenubarAsIcon,
		}
	)

	:addHeading(24, i18n("sections") .. ":")
	
	return mod

end

return plugin