local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")
local timer								= require("hs.timer")

local TimelineContent					= require("hs.finalcutpro.main.TimelineContent")

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

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- PLAYHEAD LOCKING
--- If the playhead is locked, it will be kept as close to the middle
--- of the timeline view panel as possible at all times.
-----------------------------------------------------------------------
-----------------------------------------------------------------------

Timeline.lockActive = 0.01
Timeline.lockInactive = 0.1
Timeline.lockThreshold = 5

Timeline.LOCKED = 1
Timeline.TRACKING = 2
Timeline.DEADZONE = 3

function Timeline:lockPlayhead()
	local content = self:content()
	local playhead = content:playhead()
	local check = nil
	local status = 0

	-- Setting this to false unlocks the playhead.
	self._locked = true

	-- local playheadOffset = self.timeline:playhead():getX()
	local playheadStopped = 0
	
	check = function()
		if not self._locked then
			return
		end
		
		local viewWidth = content:viewWidth()
		if viewWidth == nil then
			debugMessage("nil viewWidth")
		end
			
		local playheadOffset = viewWidth ~= nil and viewWidth/2 or nil
		local playheadX = playhead:getX()
		if playheadX == nil then
			debugMessage("nil playheadX")
		end
		if playheadOffset == nil or playheadX == nil or playheadOffset == playheadX then
			-- it is on the offset or doesn't exist.
			playheadStopped = math.min(Timeline.lockThreshold, playheadStopped + 1)
			if playheadStopped == Timeline.lockThreshold and status ~= Timeline.LOCKED then
				status = Timeline.LOCKED
				debugMessage("Playhead locked.")
			end
		else
			-- it's moving
			local timelineFrame = content:timelineFrame()
			local scrollWidth = timelineFrame.w - viewWidth
			local scrollPoint = timelineFrame.x*-1 + playheadX - playheadOffset
			local scrollTarget = scrollPoint/scrollWidth
			local scrollValue = content:getScrollHorizontal()

			if scrollTarget < 0 and scrollValue == 0 or scrollTarget > 1 and scrollValue == 1 then
				if status ~= Timeline.DEADZONE then
					status = Timeline.DEADZONE
					debugMessage("In the deadzone.")
					-- debugMessage("Deadzone.")
				end
				playheadStopped = math.min(Timeline.lockThreshold, playheadStopped + 1)
			else
				if status ~= Timeline.TRACKING then
					status = Timeline.TRACKING
					debugMessage("Tracking the playhead.")
				end
				content:scrollHorizontalTo(scrollTarget)
				playheadStopped = 0
			end
		end

		local next = Timeline.lockActive
		if playheadStopped == Timeline.lockThreshold then
			next = Timeline.lockInactive
		end

		if next ~= nil then
			timer.doAfter(next, check)
		end
	end
	
	check()
end

function Timeline:unlockPlayhead()
	self._locked = false
end

return Timeline