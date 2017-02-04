-- The 'global' command collection.
-- These are always active.

local commands					= require("cp.commands")

local plugin = {}

function plugin.init()
	return commands:new("global"):enable()
end

return plugin