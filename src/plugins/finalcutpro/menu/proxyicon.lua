--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    P R O X Y    I C O N    P L U G I N                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.proxyicon ===
---
--- Final Cut Pro Proxy Icon Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("preferences")

local config			= require("cp.config")
local fcp				= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local ENABLED_DEFAULT 	= false

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.PROXY_QUALITY		= 4
mod.PROXY_ICON			= "🔴"
mod.ORIGINAL_QUALITY	= 5
mod.ORIGINAL_ICON		= "🔵"

--- plugins.finalcutpro.menu.proxyicon.procyMenuIconEnabled <cp.prop: boolean>
--- Constant
--- Toggles the Enable Proxy Menu Icon
mod.enabled = config.prop("enableProxyMenuIcon", ENABLED_DEFAULT):watch(
	function() mod.menuManager:updateMenubarIcon() end
)

--- plugins.finalcutpro.menu.proxyicon.generateProxyTitle() -> string
--- Function
--- Generates the Proxy Title
---
--- Parameters:
---  * None
---
--- Returns:
---  * String containing the Proxy Title
function mod.generateProxyTitle()

	if mod.enabled() then
		local FFPlayerQuality = fcp:getPreference("FFPlayerQuality")
		if FFPlayerQuality == mod.PROXY_QUALITY then
			return " " .. mod.PROXY_ICON
		else
			return " " .. mod.ORIGINAL_ICON
		end
	end

	return ""

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.menu.proxyicon",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.preferences.panels.finalcutpro"]	= "prefs",
		["core.menu.manager"]							= "menuManager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Add Title Suffix Function:
	--------------------------------------------------------------------------------
	mod.menuManager = deps.menuManager
	mod.menuManager.addTitleSuffix(mod.generateProxyTitle)

	--------------------------------------------------------------------------------
	-- Setup Menubar Preferences Panel:
	--------------------------------------------------------------------------------
	if deps.prefs.panel then
		deps.prefs.panel:addHeading(30, i18n("menubarHeading"))

		:addCheckbox(31,
			{
				label = i18n("displayProxyOriginalIcon"),
				onchange = function(_, params) mod.enabled(params.checked) end,
				checked = mod.enabled,
			}
		)
	end

	return mod

end

return plugin