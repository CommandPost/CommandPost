local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local Playhead							= require("hs.finalcutpro.main.Playhead")

local TimelineContent = {}

function TimelineContent:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

function TimelineContent:parent()
	return self._parent
end

function TimelineContent:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- TIMELINE CONTENT UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function TimelineContent:UI()
	local scrollArea = self:scrollAreaUI()
	if scrollArea then
		return axutils.childWith(scrollArea, "AXIdentifier", "_NS:16")
	end
	return nil
end

function TimelineContent:scrollAreaUI()
	local main = self:parent():mainUI()
	if main then
		return axutils.childWith(main, "AXIdentifier", "_NS:9")
	end
	return nil
end

function TimelineContent:isShowing()
	return self:UI() ~= nil
end

function TimelineContent:show()
	self:parent():show()
	return self
end

function TimelineContent:hide()
	self:parent():hide()
	return self
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- PLAYHEAD UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function TimelineContent:playheadUI()
	local ui = self:UI()
	if ui then
		return axutils.childWith(ui, "AXRole", "AXValueIndicator")
	end
	return nil
end

function TimelineContent:playhead()
	if not self._playhead then
		self._playhead = Playhead:new(self)
	end
	return self._playhead
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- PLAYHEAD UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function TimelineContent:selectedChildrenUI()
	local ui = self:UI()
	if ui then
		return ui:selectedChildren()
	end
	return nil
end


return TimelineContent