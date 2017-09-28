--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       H E L P   &   S U P P O R T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.menu.helpandsupport ===
---
--- The 'Help & Support' menu section.

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 8888888

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.menu.helpandsupport",
	group			= "core",
	dependencies	= {
		["core.menu.bottom"] = "bottom",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)
	local section = dependencies.bottom
	
		:addItem(PRIORITY, function()
			return { title = string.upper(i18n("helpAndSupport")) .. ":", disabled = true }
		end)

		:addSection(PRIORITY + 0.2)
			:addMenu(0, function() return i18n("appName") end)
		return section
end

return plugin