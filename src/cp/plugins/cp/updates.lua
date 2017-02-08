local application		= require("hs.application")
local timer				= require("hs.timer")
local log				= require("hs.logger").new("updates")

local metadata			= require("cp.metadata")

--- The Function:

local UPDATE_BANNER_PRIORITY = 1
local UPDATE_PREFERENCES_PRIORITY = 5000
local CHECK_FOR_UPDATES_INTERVAL = 15 * 60

local function toggleCheckForUpdates()
	local automaticallyCheckForUpdates = hs.automaticallyCheckForUpdates()
	hs.automaticallyCheckForUpdates(not automaticallyCheckForUpdates)
	hs.checkForUpdates(true)
end

--- The Plugin:

local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.top"] = "top",
	["cp.plugins.menu.preferences"]	= "prefs",
}

function plugin.init(deps)

	if hs.automaticallyCheckForUpdates() then
		hs.checkForUpdates(true)
	end

	deps.top:addItem(UPDATE_BANNER_PRIORITY, function()
		if hs.updateAvailable() and hs.automaticallyCheckForUpdates() then
			return { title = "UPDATE AVAILABLE!",	fn = function() hs.checkForUpdates() end }
		end
	end)
	:addSeparator(2)

	deps.prefs:addSeparator(UPDATE_PREFERENCES_PRIORITY-1):addItem(UPDATE_PREFERENCES_PRIORITY, function()
		if hs.canCheckForUpdates() then
			return { title = i18n("checkForUpdates"),	fn = toggleCheckForUpdates, checked = hs.automaticallyCheckForUpdates() }
		end
	end)

end

return plugin