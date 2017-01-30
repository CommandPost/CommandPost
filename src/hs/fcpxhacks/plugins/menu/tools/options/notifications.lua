--- The AUTOMATION > 'Options' > 'Mobile Notifications' menu section

local PRIORITY = 10000

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.tools.options"] = "options"
}

function plugin.init(dependencies)
	return dependencies.options:addMenu(PRIORITY, function() return i18n("enableMobileNotifications") end)
end

return plugin