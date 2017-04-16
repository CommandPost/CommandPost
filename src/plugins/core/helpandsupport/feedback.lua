--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                             F E E D B A C K                                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.helpandsupport.feedback ===
---
--- Feedback Menu Item.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local feedback			= require("cp.feedback")
local config			= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 			= 2

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.helpandsupport.feedback.showFeedback() -> nil
--- Function
--- Opens CommandPost Credits Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
	feedback.showFeedback()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.helpandsupport.feedback",
	group			= "core",
	dependencies	= {
		["core.menu.helpandsupport"]	= "helpandsupport",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	deps.helpandsupport:addItem(PRIORITY, function()
		return { title = i18n("provideFeedback"),	fn = mod.show }
	end)

	return mod
end

return plugin