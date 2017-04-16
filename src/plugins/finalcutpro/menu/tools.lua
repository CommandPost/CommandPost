--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                        T O O L S     M E N U                               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.tools ===
---
--- The TOOLS menu section.

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
local PRIORITY 					= 3000
local PREFERENCES_PRIORITY		= 29
local SETTING 					= "menubarToolsEnabled"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local function isSectionDisabled()
	local setting = config.get(SETTING)
	if setting ~= nil then
		return not setting
	else
		return false
	end
end

local function toggleSectionDisabled()
	local menubarEnabled = config.get(SETTING)
	config.set(SETTING, not menubarEnabled)
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.menu.tools",
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
	-- Create the Tools section:
	--------------------------------------------------------------------------------
	local shortcuts = dependencies.manager.addSection(PRIORITY)

	--------------------------------------------------------------------------------
	-- Disable the section if the Tools option is disabled:
	--------------------------------------------------------------------------------
	shortcuts:setDisabledFn(isSectionDisabled)

	--------------------------------------------------------------------------------
	-- Add the separator and title for the section:
	--------------------------------------------------------------------------------
	shortcuts:addSeparator(0)
		:addItem(1, function()
			return { title = string.upper(i18n("tools")) .. ":", disabled = true }
		end)

	--------------------------------------------------------------------------------
	-- Add to General Preferences Panel:
	--------------------------------------------------------------------------------
	dependencies.prefs:addCheckbox(PREFERENCES_PRIORITY, function()
		return { title = i18n("showTools"),	fn = toggleSectionDisabled, checked = not isSectionDisabled()}
	end)

	return shortcuts
end

return plugin