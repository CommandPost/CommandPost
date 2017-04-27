--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     A D M I N I S T R A T O R    M E N U                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.administrator ===
---
--- Administrator Menu.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log						= require("hs.logger").new("adminMenu")

local config					= require("cp.config")
local fcp						= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 					= 5000
local PREFERENCES_PRIORITY		= 25
local SETTING 					= "menubarAdministratorEnabled"

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
	id				= "finalcutpro.menu.administrator",
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
	-- Create the Administrator section
	--------------------------------------------------------------------------------
	local shortcuts = dependencies.manager.addSection(PRIORITY)

	--------------------------------------------------------------------------------
	-- Disable the section if the Administrator option is disabled
	--------------------------------------------------------------------------------
	shortcuts:setDisabledFn(function()
		return not fcp:isInstalled() or not sectionEnabled()
	end)

	--------------------------------------------------------------------------------
	-- Add the separator and title for the section.
	--------------------------------------------------------------------------------
	shortcuts:addSeparator(0)
		:addItem(1, function()
			return { title = string.upper(i18n("adminTools")) .. ":", disabled = true }
		end)

	--------------------------------------------------------------------------------
	-- Add to General Preferences Panel:
	--------------------------------------------------------------------------------
	local prefs = dependencies.prefs
	prefs:addCheckbox(prefs.SECTIONS_HEADING + PREFERENCES_PRIORITY,
		{
			label = i18n("showAdminTools"),
			onchange = function(id, params)
				sectionEnabled(params.checked)
			end,
			checked = sectionEnabled,
		}
	)

	return shortcuts
end

return plugin