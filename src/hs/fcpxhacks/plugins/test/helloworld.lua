--------------------------------------------------------------------------------
-- HELLO WORLD TEST PLUGIN
--------------------------------------------------------------------------------

local log					= require("hs.logger").new("helloworld")

local mod = {}

function mod.init()
	local helloworld = function(subject)
		subject = subject or "world"
		print("Hello "..subject.."!")
	end
	
	log.d("Initialised helloworld plugin")
	
	return helloworld
end

return mod