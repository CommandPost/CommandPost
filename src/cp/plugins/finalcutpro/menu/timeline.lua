--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      T I M E L I N E    M E N U                            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- The TIMEILNE menu section.

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local metadata					= require("cp.metadata")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local PRIORITY 					= 2000
local PREFERENCES_PRIORITY		= 28
local SETTING 					= "menubarTimelineEnabled"

--------------------------------------------------------------------------------
-- LOCAL FUNCTIONS:
--------------------------------------------------------------------------------
	local function isSectionDisabled()
		local setting = metadata.get(SETTING)
		if setting ~= nil then
			return not setting
		else
			return false
		end
	end

	local function toggleSectionDisabled()
		local menubarEnabled = metadata.get(SETTING)
		metadata.set(SETTING, not menubarEnabled)
	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.core.menu.manager"] 				= "manager",
		["cp.plugins.core.preferences.panels.menubar"]	= "menubar",
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
		shortcuts:setDisabledFn(isSectionDisabled)

		--------------------------------------------------------------------------------
		-- Add the separator and title for the section:
		--------------------------------------------------------------------------------
		shortcuts:addSeparator(0)
			:addItem(1, function()
				return { title = string.upper(i18n("timeline")) .. ":", disabled = true }
			end)

		--------------------------------------------------------------------------------
		-- Add to General Preferences Panel:
		--------------------------------------------------------------------------------
		dependencies.menubar:addCheckbox(PREFERENCES_PRIORITY, function()
			return { title = i18n("show") .. " " .. i18n("timeline"),	fn = toggleSectionDisabled, checked = not isSectionDisabled()}
		end)

		return shortcuts
	end

return plugin