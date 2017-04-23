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
local fcp						= require("cp.apple.finalcutpro")

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
local function isSectionEnabled()
	return config.get(SETTING, true)
end

local function setSectionEnabled(value)
	config.set(SETTING, value)
end

local function toggleSectionDisabled()
	setSectionEnabled(not isSectionEnabled())
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
	shortcuts:setDisabledFn(function() return not fcp:isInstalled() or not isSectionEnabled() end)

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
	dependencies.prefs:addCheckbox(PREFERENCES_PRIORITY,
		{
			label = i18n("showTools"),
			onchange = function(id, params) setSectionEnabled(params.checked) end,
			checked = isSectionEnabled,
		}
	)

	return shortcuts
end

return plugin