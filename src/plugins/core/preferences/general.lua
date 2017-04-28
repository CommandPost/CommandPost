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
local prop				= require("cp.prop")
local fcp				= require("cp.apple.finalcutpro")
local dialog			= require("cp.dialog")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.general.autoLaunch <cp.prop: boolean>
--- Field
--- Controls if CommandPost will automatically launch when the user logs in.
mod.autoLaunch = prop.new(
	function() return hs.autoLaunch() end,
	function(value) hs.autoLaunch(value) end
)

--- plugins.core.preferences.general.autoLaunch <cp.prop: boolean>
--- Field
--- Controls if CommandPost will automatically upload crash data to the developer.
mod.uploadCrashData = prop.new(
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
	}
}
--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

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

	return mod

end

return plugin