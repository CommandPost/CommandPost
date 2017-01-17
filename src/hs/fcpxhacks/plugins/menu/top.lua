--- The top menu section.

local log					= require("hs.logger").new("top")
local inspect				= require("hs.inspect")

local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.manager"] = "manager"
}

function plugin.init(dependencies)
	local section = dependencies.manager.addSection(0)
	return section
end

return plugin