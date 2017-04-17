--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     M E D I A    I M P O R T    M E N U                    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.mediaimport ===
---
--- The Media Import menu section.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local config					= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 					= 1000
local PREFERENCES_PRIORITY		= 27
local SETTING 					= "menubarMediaImportEnabled"

--------------------------------------------------------------------------------
-- LOCAL FUNCTIONS:
--------------------------------------------------------------------------------
local function isSectionEnabled()
	return config.get(SETTING, true)
end

local function setSectionEnabled(value)
	config.set(SETTING, value)
end

local function toggleSectionEnabled()
	setSectionEnabled(not isSectionEnabled())
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.menu.mediaimport",
	group			= "finalcutpro",
	dependencies	= {
		["core.menu.manager"] 				= "manager",
		["core.preferences.panels.menubar"]	= "prefs",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)

	--------------------------------------------------------------------------------
	-- Create the Media Import section:
	--------------------------------------------------------------------------------
	local shortcuts = dependencies.manager.addSection(PRIORITY)

	--------------------------------------------------------------------------------
	-- Disable the section if the Media Import option is disabled:
	--------------------------------------------------------------------------------
	shortcuts:setDisabledFn(function() return not isSectionEnabled() end)

	--------------------------------------------------------------------------------
	-- Add the separator and title for the section:
	--------------------------------------------------------------------------------
	shortcuts:addSeparator(0)
		:addItem(1, function()
			return { title = string.upper(i18n("mediaImport")) .. ":", disabled = true }
		end)

	--------------------------------------------------------------------------------
	-- Add to General Preferences Panel:
	--------------------------------------------------------------------------------
	dependencies.prefs:addCheckbox(PREFERENCES_PRIORITY,
		{
			label = i18n("show") .. " " .. i18n("mediaImport"),
			onchange = function(id, params) setSectionEnabled(params.checked) end,
			checked = isSectionEnabled,
		}
	)

	return shortcuts
end

return plugin