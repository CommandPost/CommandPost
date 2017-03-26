--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    P R O X Y    I C O N    P L U G I N                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === finalcutpro.menu.proxyicon ===
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

--- finalcutpro.menu.proxyicon.toggleEnableProxyMenuIcon() -> none
--- Toggles the Enable Proxy Menu Icon
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
---
function mod.toggleEnableProxyMenuIcon()
	local enableProxyMenuIcon = config.get("enableProxyMenuIcon", DEFAULT_ENABLE_PROXY_MENU_ICON)
	config.set("enableProxyMenuIcon", not enableProxyMenuIcon)
	mod.menuManager:updateMenubarIcon()
end

--- finalcutpro.menu.proxyicon.getEnableProxyMenuIcon() -> string
--- Generates the Proxy Title
---
--- Parameters:
---  * None
---
--- Returns:
---  * String containing the Proxy Title
---
function mod.getEnableProxyMenuIcon()
	return config.get("enableProxyMenuIcon", DEFAULT_ENABLE_PROXY_MENU_ICON)
end

--- finalcutpro.menu.proxyicon.generateProxyTitle() -> string
--- Generates the Proxy Title
---
--- Parameters:
---  * None
---
--- Returns:
---  * String containing the Proxy Title
---
function mod.generateProxyTitle()

	if mod.getEnableProxyMenuIcon() then
		local FFPlayerQuality = fcp:getPreference("FFPlayerQuality")
		if FFPlayerQuality == mod.PROXY_QUALITY then
			return " " .. mod.PROXY_ICON .. "  "
		else
			return " " .. mod.ORIGINAL_ICON .. "  "
		end
	end

	return ""

end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.menu.proxyicon",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.preferences.panels.finalcutpro"]	= "menubar",
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
	deps.menubar:addHeading(30, function()
		return { title = "<br />Menubar:" }
	end)

	:addCheckbox(31, function()
		return { title = i18n("displayProxyOriginalIcon"),	fn = mod.toggleEnableProxyMenuIcon, checked = mod.getEnableProxyMenuIcon() }
	end)

end

return plugin