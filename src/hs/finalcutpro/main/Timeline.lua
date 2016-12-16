local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local Timeline = {}

function Timeline:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Timeline:parent()
	return self._parent
end

function Timeline:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- TIMELINE UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Timeline:UI()
	return self:parent():timelineUI()
end

function Timeline:isShowing()
	return self:UI() ~= nil
end

function Timeline:show()
	local parent = self:parent()
	-- show the parent.
	if parent:show() then
		local menuBar = self:app():menuBar()
		-- if the timeline is on the secondary, we need to turn it off before enabling in primary
		menuBar:uncheckMenu("Window", "Show in Secondary Display", "Timeline")
		-- Then enable it in the primary
		menuBar:checkMenu("Window", "Show in Workspace", "Timeline")
	end
	return self
end

function Timeline:hide()
	local menuBar = self:app():menuBar()
	-- Uncheck it from the primary workspace
	menuBar:uncheckMenu("Window", "Show in Workspace", "Timeline")
	return self
end


return Timeline