--- The AUTOMATION > 'Options' menu section

local PRIORITY = 8888888

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.tools"] = "tools"
}

function plugin.init(dependencies)
	return dependencies.tools:addMenu(PRIORITY, function() return i18n("options") end)
end

return plugin