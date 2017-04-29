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
local log										= require("hs.logger").new("menupref")

local image										= require("hs.image")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local APPEARANCE_HEADING = 100

local SECTIONS_HEADING = 200

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.preferences.panels.menubar",
	group			= "core",
	dependencies	= {
		["core.preferences.manager"]			= "prefsMgr",
		["core.menu.manager"]					= "menuMgr",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	local panel = deps.prefsMgr.addPanel({
		priority 	= 2020,
		id			= "menubar",
		label		= i18n("menubarPanelLabel"),
		image		= image.imageFromPath("/System/Library/PreferencePanes/Appearance.prefPane/Contents/Resources/GeneralPrefsIcons.icns"),
		tooltip		= i18n("menubarPanelTooltip"),
		height		= 306,
	})

	--------------------------------------------------------------------------------
	-- Setup Menubar Preferences Panel:
	--------------------------------------------------------------------------------
	panel:addHeading(APPEARANCE_HEADING, i18n("appearance"))

	:addCheckbox(APPEARANCE_HEADING + 10,
		{
			label = i18n("displayThisMenuAsIcon"),
			onchange = function(id, params) deps.menuMgr.displayMenubarAsIcon(params.checked) end,
			checked = deps.menuMgr.displayMenubarAsIcon,
		}
	)

	:addHeading(SECTIONS_HEADING, i18n("sections"))

	panel.APPEARANCE_HEADING	= APPEARANCE_HEADING
	panel.SECTIONS_HEADING		= SECTIONS_HEADING

	return panel
end

return plugin