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
local fcp						= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 					= 1000
local PREFERENCES_PRIORITY		= 2
local SETTING 					= "menubarMediaImportEnabled"

--------------------------------------------------------------------------------
-- LOCAL FUNCTIONS:
--------------------------------------------------------------------------------
local sectionEnabled = config.prop(SETTING, false) -- Chris deliberately changed the default to false, as very few people actually use these buttons.

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
	shortcuts:setDisabledFn(function() return not fcp:isInstalled() or not sectionEnabled() end)

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
	local prefs = dependencies.prefs
	prefs:addCheckbox(prefs.SECTIONS_HEADING + PREFERENCES_PRIORITY,
		{
			label = i18n("show") .. " " .. i18n("mediaImport"),
			onchange = function(id, params) sectionEnabled(params.checked) end,
			checked = sectionEnabled,
		}
	)

	return shortcuts
end

return plugin