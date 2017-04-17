--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--      M O B I L E   N O T I F I C A T I O N S   M E N U   S E C T I O N     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.tools.notifications ===
---
--- The AUTOMATION > 'Options' > 'Mobile Notifications' menu section.

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 10000

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.menu.tools.notifications",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.menu.tools"] = "tools"
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)
	return dependencies.tools:addMenu(PRIORITY, function() return i18n("mobileNotifications") end)
end

return plugin