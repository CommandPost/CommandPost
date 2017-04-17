--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                        C L I P B O A R D    M E N U                        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.clipboard ===
---
--- The CLIPBOARD menu section.

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
local PRIORITY 					= 2500
local PREFERENCES_PRIORITY		= 26
local SETTING 					= "menubarClipboardEnabled"

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
	id				= "finalcutpro.menu.clipboard",
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
	-- Create the Clipboard section:
	--------------------------------------------------------------------------------
	local shortcuts = dependencies.manager.addSection(PRIORITY)

	--------------------------------------------------------------------------------
	-- Disable the section if the Clipboard option is disabled:
	--------------------------------------------------------------------------------
	shortcuts:setDisabledFn(isSectionDisabled)

	--------------------------------------------------------------------------------
	-- Add the separator and title for the section:
	--------------------------------------------------------------------------------
	shortcuts:addSeparator(0)
		:addItem(1, function()
			return { title = string.upper(i18n("clipboard")) .. ":", disabled = true }
		end)

	--------------------------------------------------------------------------------
	-- Add to General Preferences Panel:
	--------------------------------------------------------------------------------
	dependencies.prefs:addCheckbox(PREFERENCES_PRIORITY,
		{
			label = i18n("show") .. " " .. i18n("clipboard"),
			onchange = toggleSectionDisabled,
			checked = function() return not isSectionDisabled() end
		}
	)

	return shortcuts
end

return plugin