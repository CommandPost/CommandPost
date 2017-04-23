--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--             G E N E R A L    P R E F E R E N C E S    P A N E L            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.panels.menubar ===
---
--- Menubar Preferences Panel

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
	id				= "core.preferences.panels.menubar",
	group			= "core",
	dependencies	= {
		["core.preferences.manager"]			= "manager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	return deps.manager.addPanel({
		priority 	= 2020,
		id			= "menubar",
		label		= i18n("menubarPanelLabel"),
		image		= image.imageFromPath("/System/Library/PreferencePanes/Appearance.prefPane/Contents/Resources/GeneralPrefsIcons.icns"),
		tooltip		= i18n("menubarPanelTooltip"),
		height		= 306,
	})
end

return plugin