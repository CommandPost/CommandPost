--- The top menu section.

local log					= require("hs.logger").new("top")
local inspect				= require("hs.inspect")

local fcp					= require("hs.finalcutpro")

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.manager"] = "manager"
}

function plugin.init(dependencies)
	return dependencies.manager.addSection(0)
end

return plugin