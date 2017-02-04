--- The AUTOMATION > 'Options' > 'Mobile Notifications' menu section

local PRIORITY = 10000

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.tools"] = "options"
}

function plugin.init(dependencies)
	return dependencies.options:addMenu(PRIORITY, function() return i18n("mobileNotifications") end)
end

return plugin