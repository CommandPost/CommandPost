--- The AUTOMATION > 'Options' menu section

local PRIORITY = 8888888

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.timeline"] = "automation"
}

function plugin.init(dependencies)
	return dependencies.automation:addMenu(PRIORITY, function() return i18n("assignShortcuts") end)
end

return plugin