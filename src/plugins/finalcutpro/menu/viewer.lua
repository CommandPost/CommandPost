--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                        V I E W E R     M E N U                             --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.viewer ===
---
--- The VIEWER menu section.

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
local PRIORITY 					= 2001
local PREFERENCES_PRIORITY		= 4
local SETTING 					= "menubarViewerEnabled"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local sectionEnabled = config.prop(SETTING, true)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.menu.viewer",
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
	-- Create the Timeline section:
	--------------------------------------------------------------------------------
	local shortcuts = dependencies.manager.addSection(PRIORITY)

	--------------------------------------------------------------------------------
	-- Disable the section if the Timeline option is disabled:
	--------------------------------------------------------------------------------
	shortcuts:setDisabledFn(function() return not fcp:isInstalled() or not sectionEnabled() end)

	--------------------------------------------------------------------------------
	-- Add the separator and title for the section:
	--------------------------------------------------------------------------------
	shortcuts:addSeparator(0)
		:addItem(1, function()
			return { title = string.upper(i18n("viewer")) .. ":", disabled = true }
		end)

	--------------------------------------------------------------------------------
	-- Add to General Preferences Panel:
	--------------------------------------------------------------------------------
	local prefs = dependencies.prefs
	prefs:addCheckbox(prefs.SECTIONS_HEADING + PREFERENCES_PRIORITY,
		{
			label = i18n("show") .. " " .. i18n("viewer"),
			onchange = function(id, params) sectionEnabled(params.checked) end,
			checked = sectionEnabled,
		}
	)

	return shortcuts
end

return plugin