--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.zoomtoselection ===
---
--- Zoom the Timeline to fit the currently-selected clips.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("zoomtoselection")

local fcp								= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- The number of pixels of buffer space to allow the selection zoom to fit.
mod.SELECTION_BUFFER = 70

mod.FULL_ZOOM = 5.34

function mod._zoomToFit(minClip, maxClip, shift)
	local zoomAmount = mod.zoomAmount
	-- zoom in until it fits
	repeat
		-- The current width of the selected clips
		local selectedWidth = maxClip:position().x + maxClip:size().w - minClip:frame().x + mod.SELECTION_BUFFER*2
		-- The dimensions of the view frame
		local viewFrame = mod.contents:viewFrame()

		if selectedWidth < viewFrame.w then
			zoomAmount:value(zoomAmount:value() + shift)
		end
	until (selectedWidth >= viewFrame.w)
	
	zoomAmount:value(zoomAmount:value() - shift)
end

--- plugins.finalcutpro.timeline.zoomtoselection.zoomToSelection() -> boolean
--- Method
--- Zooms the view to fit the currently-selected clips.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if there is selected content in the timeline and zooming was successful.
function mod.zoomToSelection()
	local selectedClips = mod.contents:selectedClipsUI()
	if not selectedClips or #selectedClips == 0 then
		return false
	end
	
	-- Find the min/max clip and 'x' value for selected clips.
	local minClip, maxClip, minX, maxX
	for _,clip in ipairs(selectedClips) do
		local frame = clip:frame()
		if minX == nil or minX > frame.x then
			minX = frame.x
			minClip = clip
		end
		if maxX == nil or maxX < (frame.x + frame.w) then
			maxX = frame.x + frame.w
			maxClip = clip
		end
	end
	
	-- find the right zoom amount
	local appearance = mod.appearance
	local zoomAmount = mod.zoomAmount

	-- set to 'full project'
	appearance:show()
	zoomAmount:value(mod.FULL_ZOOM)
	
	-- zoom in until it fits, getting more precise as we go
	mod._zoomToFit(minClip, maxClip, 1.0)
	mod._zoomToFit(minClip, maxClip, 0.5)
	mod._zoomToFit(minClip, maxClip, 0.1)
	mod._zoomToFit(minClip, maxClip, 0.05)
	
	-- move to the first clip position
	mod.contents:scrollHorizontalToX(minClip:position().x - mod.SELECTION_BUFFER)
	
	-- hide the appearance popup again
	appearance:hide()
	
	return true
end

function mod.init()
	mod.appearance = fcp:timeline():toolbar():appearance()
	mod.zoomAmount = mod.appearance:zoomAmount()
	mod.contents = fcp:timeline():contents()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.timeline.zoomtoselection",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.commands"]	= "fcpxCmds",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	
	mod.init()

	deps.fcpxCmds:add("cpZoomToSelection")
		:activatedBy():option():shift("z")
		:whenActivated(mod.zoomToSelection)

	return mod

end

return plugin