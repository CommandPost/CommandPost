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
local DEFAULT_ENABLE_PROXY_MENU_ICON 	= false

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	--------------------------------------------------------------------------------
	-- TOGGLE ENABLE PROXY MENU ICON:
	--------------------------------------------------------------------------------
	function mod.toggleEnableProxyMenuIcon()
		local enableProxyMenuIcon = metadata.get("enableProxyMenuIcon", DEFAULT_ENABLE_PROXY_MENU_ICON)
		metadata.set("enableProxyMenuIcon", not enableProxyMenuIcon)
		mod.menuManager:updateMenubarIcon()
	end

	--------------------------------------------------------------------------------
	-- GET ENABLE PROXY MENU ICON VALUE:
	--------------------------------------------------------------------------------
	function mod.getEnableProxyMenuIcon()
		return metadata.get("enableProxyMenuIcon", DEFAULT_ENABLE_PROXY_MENU_ICON)
	end

--------------------------------------------------------------------------------
--- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.preferences.general",
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

		mod.menuManager = deps.menuManager

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