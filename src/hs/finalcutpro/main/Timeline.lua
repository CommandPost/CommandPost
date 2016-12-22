local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local TimelineContent					= require("hs.finalcutpro.main.TimelineContent")
local Scroller							= require("hs.finalcutpro.main.TimelineScroller")

local Timeline = {}

function Timeline.isTimeline(element)
	return element:attributeValue("AXRole") == "AXGroup"
	   and axutils.childWith(element, "AXIdentifier", "_NS:237") ~= nil
end

function Timeline:new(parent, secondary)
	o = {_parent = parent, _secondary = secondary}
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

function Timeline:isOnSecondaryWindow()
	return self._secondary
end

function Timeline:isOnPrimaryWindow()
	return not self._secondary
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- TIMELINE UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Timeline:UI()
	return axutils.cache(self, "_ui", function()
		local top = self:parent():timelineGroupUI()
		if top then
			for i,child in ipairs(top) do
				if Timeline.isTimeline(child) then
					return child
				end
			end
		end
		return nil
	end)
end

function Timeline:isShowing()
	local ui = self:UI()
	return ui ~= nil and #ui > 0
end

function Timeline:show()
	local menuBar = self:app():menuBar()
	
	if self:isOnPrimaryWindow() then
		-- if the timeline is on the secondary, we need to turn it off before enabling in primary
		menuBar:uncheckMenu("Window", "Show in Secondary Display", "Timeline")
		-- Then enable it in the primary
		menuBar:checkMenu("Window", "Show in Workspace", "Timeline")
	else
		menuBar:checkMenu("Window", "Show in Secondary Display", "Timeline")
	end

	return self
end

function Timeline:hide()
	local menuBar = self:app():menuBar()
	-- Uncheck it from the primary workspace
	menuBar:uncheckMenu("Window", "Show in Secondary Display", "Timeline")
	menuBar:uncheckMenu("Window", "Show in Workspace", "Timeline")
	return self
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- MAIN UI
--- The Canvas is the main body of the timeline, containing the
--- Timeline Index, the canvas, and the Effects/Transitions panels.
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Timeline:mainUI()
	return axutils.cache(self, "_main", function()
		local ui = self:UI()
		if ui then
			for i,child in ipairs(ui) do
				if self:_isMain(child) then
					return child
				end
			end
		end
		return nil
	end)
end

function Timeline:_isMain(element)
	return element:attributeValue("AXIdentifier") == "_NS:237"
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- CONTENT
--- The Content is the main body of the timeline, containing the
--- Timeline Index, the Content, and the Effects/Transitions panels.
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Timeline:content()
	if not self._content then
		self._content = TimelineContent:new(self)
	end
	return self._content
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- PLAYHEAD
--- The timline Playhead.
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Timeline:playhead()
	return self:content():playhead()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- MAIN UI
--- The Canvas is the main body of the timeline, containing the
--- Timeline Index, the canvas, and the Effects/Transitions panels.
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Timeline:toolbarUI()
	return axutils.cache(self, "_toolbar", function()
		local ui = self:UI()
		if ui then
			for i,child in ipairs(ui) do
				if not self:_isMain(child) then
					return child
				end
			end
		end
		return nil
	end)
end

function Timeline:scroller()
	if not self._scroller then
		self._scroller = Scroller:new(self)
	end
	return self._scroller
end

function Timeline:setScrollingTimeline(enabled)
	if enabled then
		self:scroller():start()
	else
		self:scroller():stop()
	end
	return enabled
end

function Timeline:toggleScrollingTimeline()
	return self:setScrollingTimeline(not self:isScrollingTimeline())
end

function Timeline:isScrollingTimeline()
	return self._scroller and self._scroller:isRunning()
end

function Timeline:lockPlayhead()
	self:scroller():lockPlayhead()
end

function Timeline:unlockPlayhead()
	self:scroller():unlockPlayhead()
end

function Timeline:getScrollingTimelineLog()
	return self._scroller.log
end

return Timeline