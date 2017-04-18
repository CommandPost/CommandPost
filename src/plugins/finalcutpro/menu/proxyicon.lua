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
local fcp				= require("cp.finalcutpro")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local DEFAULT_ENABLE_PROXY_MENU_ICON 	= false

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

--- plugins.finalcutpro.menu.proxyicon.toggleEnableProxyMenuIcon() -> none
--- Function
--- Toggles the Enable Proxy Menu Icon
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleEnableProxyMenuIcon()
	local enableProxyMenuIcon = config.get("enableProxyMenuIcon", DEFAULT_ENABLE_PROXY_MENU_ICON)
	config.set("enableProxyMenuIcon", not enableProxyMenuIcon)
	mod.menuManager:updateMenubarIcon()
end

--- plugins.finalcutpro.menu.proxyicon.getEnableProxyMenuIcon() -> string
--- Function
--- Generates the Proxy Title
---
--- Parameters:
---  * None
---
--- Returns:
---  * String containing the Proxy Title
function mod.getEnableProxyMenuIcon()
	return config.get("enableProxyMenuIcon", DEFAULT_ENABLE_PROXY_MENU_ICON)
end

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

	if mod.getEnableProxyMenuIcon() then
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
		deps.prefs:addHeading(30, i18n("menubarHeading"))

		:addCheckbox(31,
			{
				label = i18n("displayProxyOriginalIcon"),
				onchange = mod.toggleEnableProxyMenuIcon,
				checked = mod.getEnableProxyMenuIcon,
			}
		)
	end

end

return plugin