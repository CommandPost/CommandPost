--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--          F I N A L    C U T    P R O   W A T C H    F O L D E R S          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.watchfolders.panels.finalcutpro ===
---
--- Final Cut Pro Watch Folders Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsGeneral")

local image										= require("hs.image")
local fcp										= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.watchfolders.panels.finalcutpro",
	group			= "finalcutpro",
	dependencies	= {
		["core.watchfolders.manager"]	= "manager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	local mod = {}

	if fcp:isInstalled() then
		mod.panel = deps.manager.addPanel({
			priority 	= 2040,
			id			= "finalcutpro",
			label		= i18n("finalCutProPanelLabel"),
			image		= image.imageFromPath(fcp:getPath() .. "/Contents/Resources/Final Cut.icns"),
			tooltip		= i18n("finalCutProPanelTooltip"),
			height		= 298,
		})
	end

	return mod
end

return plugin