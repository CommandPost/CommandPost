--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--            A D V A N C E D    P R E F E R E N C E S    P A N E L           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.panels.advanced ===
---
--- Advanced Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsGeneral")

local image										= require("hs.image")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.preferences.panels.advanced",
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
		priority 	= 2090,
		id			= "advanced",
		label		= i18n("advancedPanelLabel"),
		image		= image.imageFromName("NSAdvanced"),
		tooltip		= i18n("advancedPanelTooltip"),
		height		= 385,
	})
end

return plugin