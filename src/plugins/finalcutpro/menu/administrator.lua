--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     A D M I N I S T R A T O R    M E N U                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- The AUTOMATION menu section.

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
local PRIORITY 					= 5000
local PREFERENCES_PRIORITY		= 25
local SETTING 					= "menubarAdministratorEnabled"

--------------------------------------------------------------------------------
-- LOCAL FUNCTIONS:
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
	shortcuts:setDisabledFn(isSectionDisabled)

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
	dependencies.prefs:addCheckbox(PREFERENCES_PRIORITY,
		{
			label = i18n("showAdminTools"),
			onchange = toggleSectionDisabled,
			checked = not isSectionDisabled()
		}
	)

	return shortcuts
end

return plugin