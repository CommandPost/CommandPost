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
local plugin = {}

plugin.dependencies = {
	["cp.plugins.finalcutpro.commands.fcpx"]	= "fcpxCmds",
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