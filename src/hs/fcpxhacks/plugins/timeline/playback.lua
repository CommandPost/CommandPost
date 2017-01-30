-- Imports
local fcp							= require("hs.finalcutpro")


-- The Module
local mod = {}

function mod.play()
	fcp:performShortcut("PlayPause")
end

function mod.pause()
	mod.play()
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.commands.fcpx"]	= "fcpxCmds",
}

function plugin.init(deps)
	
	local cmds = deps.fcpxCmds
	
	cmds:add("FCPXHackPlay")
		:whenActivated(mod.play)
		
	cmds:add("FCPXHackPause")
		:whenActivated(mod.pause)
		
	
	return mod
end

return plugin