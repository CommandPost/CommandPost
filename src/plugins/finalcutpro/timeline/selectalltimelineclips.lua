-- Includes
local fcp								= require("cp.finalcutpro")
local dialog							= require("cp.dialog")

local log								= require("hs.logger").new("selectalltimelineclips")

-- Constants

-- The Module
local mod = {}

function mod.selectAllTimelineClips(forwards)

	local content = fcp:timeline():contents()
	local playheadX = content:playhead():getPosition()

	local clips = content:clipsUI(false, function(clip)
		local frame = clip:frame()
		if forwards then
			return playheadX <= frame.x
		else
			return playheadX >= frame.x
		end
	end)

	if clips then
		content:selectClips(clips)
		return true
	else
		log.df("No clips to select")
		return false
	end

end

-- The Plugin
local plugin = {
	id = "finalcutpro.timeline.selectalltimelineclips",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.commands"]	= "fcpxCmds",
	}
}

function plugin.init(deps)

	deps.fcpxCmds:add("cpSelectForward")
		:activatedBy():ctrl():option():cmd("right")
		:whenActivated(function() mod.selectAllTimelineClips(true) end)

	deps.fcpxCmds:add("cpSelectBackwards")
		:activatedBy():ctrl():option():cmd("left")
		:whenActivated(function() mod.selectAllTimelineClips(false) end)

	return mod

end

return plugin