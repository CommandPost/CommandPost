--- The AUTOMATION > 'Options' > 'Mobile Notifications' menu section

local PRIORITY = 10000

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.administrator"] = "administrator"
}

function plugin.init(dependencies)
	return dependencies.administrator:addMenu(PRIORITY, function() return i18n("advancedFeatures") end)
end

return plugin