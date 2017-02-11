-- Includes:

local timer								= require("hs.timer")
local eventtap							= require("hs.eventtap")

local fcp								= require("cp.finalcutpro")

local log								= require("hs.logger").new("height")

-- The Module:

local mod = {}

mod.changeTimelineClipHeightAlreadyInProgress = false

local function shiftClipHeight(direction)
	--------------------------------------------------------------------------------
	-- Find the Timeline Appearance Button:
	--------------------------------------------------------------------------------
	local appearance = fcp:timeline():toolbar():appearance()
	if appearance then
		appearance:show()
		if direction == "up" then
			appearance:clipHeight():increment()
		else
			appearance:clipHeight():decrement()
		end
		return true
	else
		return false
	end
end

local function changeTimelineClipHeightRelease()
	mod.changeTimelineClipHeightAlreadyInProgress = false
	fcp:timeline():toolbar():appearance():hide()
end

function mod.changeTimelineClipHeight(direction)

	--------------------------------------------------------------------------------
	-- Prevent multiple keypresses:
	--------------------------------------------------------------------------------
	if mod.changeTimelineClipHeightAlreadyInProgress then return end
	mod.changeTimelineClipHeightAlreadyInProgress = true

	--------------------------------------------------------------------------------
	-- Change Value of Zoom Slider:
	--------------------------------------------------------------------------------
	local result = shiftClipHeight(direction)

	--------------------------------------------------------------------------------
	-- Keep looping it until the key is released.
	--------------------------------------------------------------------------------
	if result then
		timer.doUntil(function() return not mod.changeTimelineClipHeightAlreadyInProgress end, function()
			shiftClipHeight(direction)
		end, eventtap.keyRepeatInterval())
	end

end

-- The Plugin:

local plugin = {}

plugin.dependencies = {
	["cp.plugins.commands.fcpx"]	= "fcpxCmds",
}

function plugin.init(deps)

	deps.fcpxCmds:add("cpChangeTimelineClipHeightUp")
		:whenActivated(function() mod.changeTimelineClipHeight("up") end)
		:whenReleased(function() changeTimelineClipHeightRelease() end)
		:activatedBy():ctrl():option():cmd("+")

	deps.fcpxCmds:add("cpChangeTimelineClipHeightDown")
		:whenActivated(function() mod.changeTimelineClipHeight("down") end)
		:whenReleased(function() changeTimelineClipHeightRelease() end)
		:activatedBy():ctrl():option():cmd("-")

	return mod
end

return plugin