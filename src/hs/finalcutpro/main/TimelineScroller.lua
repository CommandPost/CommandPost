local timer									= require("hs.timer")
local inspect								= require("hs.inspect")
local alert 								= require("hs.alert")

local Scroller = {}

Scroller.interval = 0.1
Scroller.logLength = 5
Scroller.errorMargin = 2.0

Scroller.scrollInterval = 0.001

Scroller.SECONDS_PER_MINUTE = 60
Scroller.SECONDS_PER_HOUR = 60 * Scroller.SECONDS_PER_MINUTE

function Scroller:new(timeline)
	o = {
		timeline = timeline,
		log = {}
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Scroller:init()
	local content = self.timeline:content()
	local playhead = content:playhead()
	local viewer = content:app():viewer()
	local parse = Scroller.parseTimecode
	local compare = Scroller.compareTimecode
	
	self.timer = timer.new(Scroller.interval,
	function()
		local dir = self:processPlayhead(playhead)
		-- if dir > 0 then
		-- 	-- it's playing forward
		-- 	if dir ~= self.lastDir then
		-- 		alert.closeAll(0)
		-- 		alert.show("Forward")
		-- 	end
		-- elseif dir < 0 then
		-- 	-- it's playing backward
		-- 	if dir ~= self.lastDir then
		-- 		alert.closeAll(0)
		-- 		alert.show("Backward")
		-- 	end
		-- else
		-- 	-- it's not moving.
		-- 	if dir ~= self.lastDir then
		-- 		alert.closeAll(0)
		-- 		alert.show("Stopped")
		-- 	end
		-- end

		if dir ~= 0 then
			self.scrollTimer:start()
		else
			self.scrollTimer:stop()
		end
		self.lastDir = dir
	end)
	
	self.scrollTimer = timer.new(Scroller.scrollInterval,
	function()
		-- it's moving
		local viewFrame = content:viewFrame()
		local timelineFrame = content:timelineFrame()
		local viewTimelineRatio = viewFrame.w / timelineFrame.w

		local currentPlayheadX = playhead:getX()
		local currentPlayheadPercentage = currentPlayheadX / timelineFrame.w

		if self.initialPlayheadX == nil then
			-- We just started moving
			self.initialPlayheadX = currentPlayheadX
			self.initialPlayheadPercentage = currentPlayheadPercentage
		end

		local scrollbarStep = (currentPlayheadPercentage - self.initialPlayheadPercentage) * viewTimelineRatio

		content:scrollHorizontalBy(scrollbarStep)
		
	end)
end

function Scroller:start()
	if not self.timer then
		self:init()
	end
	self.timer:start()
end

function Scroller:stop()
	if self.timer then
		self.timer:stop()
		self.log = {}
	end
	if self.scrollTimer and self.scrollTimer:running() then
		self.scrollTimer:stop()
	end
end

function Scroller:isRunning()
	return self.time and self.timer:running()
end

function Scroller:processPlayhead(playhead)
	local prev = Scroller._prevIndex
	local next = Scroller._nextIndex
	local log = self.log

	local thisX = playhead:getX()
	local thisTimestamp = timer.secondsSinceEpoch()
	if thisX == nil then 
		return 0
	end
	
	-- retrieve last log
	local lastIndex = log.index
	local lastLog = lastIndex and log[lastIndex]

	local thisDelta = nil
	local avgDelta = nil
	
	if not lastLog or thisX ~= lastLog.x then
		-- create this log
		thisDelta = lastLog and (thisTimestamp - lastLog.ts)/(thisX - lastLog.x) or nil
		local thisIndex = next(lastIndex)

		-- find the average delta
		local i = lastIndex
		local sumDelta = 0
		local count = 0
	
		repeat
			lastLog = log[i]
			-- break out early if we hit the end of the log
			if lastLog == nil then break end
		
			sumDelta = lastLog.delta ~= nil and (sumDelta + lastLog.delta) or sumDelta
			count = count + 1
			i = prev(i)
		until i == lastIndex
	
		avgDelta = count > 0 and (sumDelta / count) or 0
	
		local thisLog = {x = thisX, ts = thisTimestamp, delta = thisDelta, avgDelta = avgDelta}
		log[thisIndex] = thisLog
		log.index = thisIndex
	else
		avgDelta = lastLog and lastLog.avgDelta or nil
	end
	
	local diff = thisDelta ~= nil and avgDelta ~= nil and (thisDelta - avgDelta) or 0
	
	if thisDelta == 0 or thisDelta == nil then
		return 0
	elseif math.abs(diff) < Scroller.errorMargin then
		if thisDelta > 0 then
			return 1
		elseif thisDelta < 0 then
			return -1
		end
	end
	return 0
end

function Scroller._nextIndex(index)
	return index and (index % Scroller.logLength + 1) or 1
end

function Scroller._prevIndex(index)
	return index and (index - 1) % Scroller.logLength or 10
end

return Scroller