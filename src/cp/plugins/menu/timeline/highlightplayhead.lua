--- The AUTOMATION > 'Options' menu section

local PRIORITY = 30000

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.timeline"] = "timeline"
}

function plugin.init(dependencies)
	return dependencies.timeline:addMenu(PRIORITY, function() return i18n("highlightPlayhead") end)
end

return plugin