-- Imports
local fcp							= require("cp.finalcutpro")


-- The Module
local mod = {}

function mod.play()
	fcp:performShortcut("PlayPause")
end

function mod.pause()
	mod.play()
end

-- The Plugin
local plugin = {
	id = "finalcutpro.timeline.playback",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.commands"]	= "fcpxCmds",
	}
}

function plugin.init(deps)

	local cmds = deps.fcpxCmds

	cmds:add("cpPlay")
		:whenActivated(mod.play)

	cmds:add("cpPause")
		:whenActivated(mod.pause)


	return mod
end

return plugin