--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              W E B A P P    P R E F E R E N C E S    P A N E L             --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.panels.webapp ===
---
--- WebApp Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefWebApp")

local image										= require("hs.image")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.preferences.panels.webapp",
	group			= "core",
	dependencies	= {
		["core.preferences.manager"]	= "manager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	return deps.manager.addPanel({
		priority 	= 2049,
		id			= "webapp",
		label		= i18n("webappPanelLabel"),
		image		= image.imageFromName("NSNetwork"),
		tooltip		= i18n("webappPanelTooltip"),
		height		= 382,
	})
end

return plugin