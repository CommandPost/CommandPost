--------------------------------------------------------------------------------
-- HELLO WORLD TEST PLUGIN
--------------------------------------------------------------------------------

local log					= require("hs.logger").new("hellodavid")

local mod = {}

mod.dependencies = { ["hs.fcpxhacks.plugins.helloworld"] = "helloworld" }

function mod.init(dependencies)
	local helloworld = dependencies.helloworld
	
	local hellodavid = function()
		helloworld("David")
	end
	
	log.d("Initialised hellodavid plugin.")
	
	return hellodavid
end

return mod