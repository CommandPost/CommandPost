local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")
local timer								= require("hs.timer")

local TimelineContent					= require("hs.finalcutpro.main.TimelineContent")
local PrimaryWindow						= require("hs.finalcutpro.main.PrimaryWindow")
local SecondaryWindow					= require("hs.finalcutpro.main.SecondaryWindow")

local Timeline = {}

function Timeline.matches(element)
	return element:attributeValue("AXRole") == "AXGroup"
	   and axutils.childWith(element, "AXIdentifier", "_NS:237") ~= nil
end

function Timeline:new(app)
	o = {_app = app}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Timeline:app()
	return self._app
end

function Timeline:isOnSecondary()
	local ui = self:UI()
	return ui and SecondaryWindow.matches(ui:window())
end

function Timeline:isOnPrimary()
	local ui = self:UI()
	return ui and PrimaryWindow.matches(ui:window())
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- TIMELINE UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Timeline:UI()
	return axutils.cache(self, "_ui", function()
		local app = self:app()
		return Timeline._findTimeline(app:secondaryWindow(), app:primaryWindow())
	end,
	Timeline.matches)
end

function Timeline._findTimeline(...)
	for i = 1,select("#", ...) do
		local window = select(i, ...)
		debugMessage("findTimeline: window #"..i..":\n"..inspect(window))
		if window then
			local ui = window:timelineGroupUI()
			if ui then
				local timeline = axutils.childMatching(ui, Timeline.matches)
				if timeline then return timeline end
			end
		end
	end
	return nil
end

function Timeline:isShowing()
	local ui = self:UI()
	return ui ~= nil and #ui > 0
end

function Timeline:showOnPrimary()
	local menuBar = self:app():menuBar()

	-- if the timeline is on the secondary, we need to turn it off before enabling in primary
	menuBar:uncheckMenu("Window", "Show in Secondary Display", "Timeline")
	-- Then enable it in the primary
	menuBar:checkMenu("Window", "Show in Workspace", "Timeline")

	return self
end

function Timeline:showOnSecondary()
	local menuBar = self:app():menuBar()

	-- if the timeline is on the secondary, we need to turn it off before enabling in primary
	menuBar:checkMenu("Window", "Show in Secondary Display", "Timeline")

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
		return ui and axutils.childMatching(ui, Timeline.matchesMain)
	end,
	Timeline.matchesMain)
end

function Timeline.matchesMain(element)
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
		return ui and axutil.childMatching(ui, Timeline.matchesToolbar)
	end,
	Timeline.matchesToolbar)
end

function Timeline.matchesToolbar(element)
	return not Timeline.matchesMain(element)
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
Timeline.INVISIBLE = 4

function Timeline:lockPlayhead()
	if self._locked then
		-- already locked.
		return self
	end
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

		local viewFrame = content:viewFrame()
		if viewFrame == nil then
			-- The timeline is not visible.
			if status ~= Timeline.INVISIBLE then
				status = Timeline.INVISIBLE
				debugMessage("Timeline not visible.")
			end
			
			playheadStopped = Timeline.lockThreshold
		else
			local playheadOffset = viewFrame.x + math.floor(viewFrame.w/2)
			local playheadX = playhead:getPosition()
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
				local scrollWidth = timelineFrame.w - viewFrame.w
				local scrollPoint = timelineFrame.x*-1 + viewFrame.x + playheadX - playheadOffset
				local scrollTarget = scrollPoint/scrollWidth
				local scrollValue = content:getScrollHorizontal()

				if scrollTarget < 0 and scrollValue == 0 or scrollTarget > 1 and scrollValue == 1 then
					if status ~= Timeline.DEADZONE then
						status = Timeline.DEADZONE
						debugMessage("In the deadzone.")
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

	return self
end

function Timeline:unlockPlayhead()
	self._locked = false

	return self
end

function Timeline:isLockedPlayhead()
	return self._locked
end

return Timeline