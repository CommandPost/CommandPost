--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                             U P D A T E S                                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("updates")

local application		= require("hs.application")
local timer				= require("hs.timer")

local config			= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local UPDATE_BANNER_PRIORITY 			= 1
local UPDATE_PREFERENCES_PRIORITY 		= 5000
local CHECK_FOR_UPDATES_INTERVAL 		= 15 * 60

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

	function mod.toggleCheckForUpdates()
		local automaticallyCheckForUpdates = hs.automaticallyCheckForUpdates()
		hs.automaticallyCheckForUpdates(not automaticallyCheckForUpdates)
		mod.automaticallyCheckForUpdates = not automaticallyCheckForUpdates

		if not automaticallyCheckForUpdates then
			hs.checkForUpdates(true)
		end
	end

	function mod.checkForUpdates()
		hs.checkForUpdates()
	end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.preferences.updates",
	group			= "core",
	dependencies	= {
		["core.menu.top"] 					= "top",
		["core.preferences.panels.general"]	= "general",
	}
}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)

		mod.automaticallyCheckForUpdates = hs.automaticallyCheckForUpdates()

		if hs.automaticallyCheckForUpdates() then
			hs.checkForUpdates(true)
		end

		deps.top:addItem(UPDATE_BANNER_PRIORITY, function()
			if hs.updateAvailable() and hs.automaticallyCheckForUpdates() then
				return { title = i18n("updateAvailable") .. " (" .. hs.updateAvailable() .. ")",	fn = mod.checkForUpdates }
			end
		end)
		:addSeparator(2)

		deps.general:addCheckbox(3, function()
			if hs.canCheckForUpdates() then
				return { title = i18n("checkForUpdates"),	fn = mod.toggleCheckForUpdates, checked = mod.automaticallyCheckForUpdates }
			end
		end)

	end

return plugin