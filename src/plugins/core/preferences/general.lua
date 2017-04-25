--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 P R E F E R E N C E S    P L U G I N                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.general ===
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
local is				= require("cp.is")
local fcp				= require("cp.apple.finalcutpro")
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

--- plugins.core.preferences.general.displayMenubarAsIcon
--- Is Value
--- Toggles the menubar display icon from icon to text value and vice versa.
mod.displayMenubarAsIcon = config.is("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON):watch(
	function(value)
		if mod.menuManager then mod.menuManager:updateMenubarIcon() end
	end
)

--- plugins.core.preferences.general.autoLaunch
--- Is Value
--- A `cp.is` value to control if CommandPost will automatically launch when the user logs in.
mod.autoLaunch = is.new(
	function() return hs.autoLaunch() end,
	function(value) hs.autoLaunch(value) end
)

--- plugins.core.preferences.general.autoLaunch
--- Is Value
--- A `cp.is` value to control if CommandPost will automatically upload crash data to the developer.
mod.uploadCrashData = is.new(
	function() return hs.uploadCrashData() end,
	function(value) hs.uploadCrashData(value) end
)

--- plugins.core.preferences.general.openPrivacyPolicy() -> none
--- Function
--- Opens the CommandPost Privacy Policy in your browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.openPrivacyPolicy()
	hs.execute("open '" .. config.privacyPolicyURL .. "'")
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
	deps.general:addHeading(1, i18n("general"))

	:addCheckbox(3,
		{
			label		= i18n("launchAtStartup"),
			checked		= mod.autoLaunch,
			onchange	= function(id, params) mod.autoLaunch(params.checked) end,
		}
	)

	:addHeading(50, i18n("privacy"))

	:addCheckbox(51,
		{
			label		= i18n("sendCrashData"),
			checked		= mod.uploadCrashData,
			onchange	= function(id, params) mod.uploadCrashData(params.checked) end,
		}
	)

	:addButton(52,
		{
			label 		= i18n("openPrivacyPolicy"),
			width		= 150,
			onclick		= mod.openPrivacyPolicy,
		}
	)

	--------------------------------------------------------------------------------
	-- Setup Menubar Preferences Panel:
	--------------------------------------------------------------------------------
	deps.menubar:addHeading(20, i18n("appearance"))

	:addCheckbox(21,
		{
			label = i18n("displayThisMenuAsIcon"),
			onchange = function(id, params) mod.displayMenubarAsIcon(params.checked) end,
			checked = mod.displayMenubarAsIcon,
		}
	)

	:addHeading(24, i18n("sections"))

	return mod

end

return plugin