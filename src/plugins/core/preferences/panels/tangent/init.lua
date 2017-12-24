--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--               T A N G E N T   P R E F E R E N C E S    P A N E L           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.panels.tangent ===
---
--- Tangent Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsTangent")

local image										= require("hs.image")

local tools										= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.preferences.panels.tangent",
	group			= "core",
	dependencies	= {
		["core.preferences.manager"]	= "manager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	return deps.manager.addPanel({
		priority 	= 2026,
		id			= "tangent",
		label		= i18n("tangentPanelLabel"),
		image		= image.imageFromPath(env:pathToAbsolute("/tangent.icns")),
		tooltip		= i18n("tangentPanelTooltip"),
		height		= 300,
	})
end

return plugin