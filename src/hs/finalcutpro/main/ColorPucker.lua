local mouse									= require("hs.mouse")
local geometry								= require("hs.geometry")
local drawing								= require("hs.drawing")
local timer									= require("hs.timer")

local Pucker = {}

Pucker.elasticity = .5
Pucker.naturalLength = 10

function Pucker:new(colorBoard, aspect, property)
	o = {
		colorBoard = colorBoard,
		aspect = aspect,
		property = property,
		xShift = 0,
		yShift = 0
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Pucker:start()
	-- find the percent and angle UIs
	self.pctUI		= self.colorBoard:aspectPropertyPanelUI(self.aspect, self.property, 'pct')
	self.angleUI	= self.colorBoard:aspectPropertyPanelUI(self.aspect, self.property, 'angle')
	
	-- record the origin and draw a marker
	self.origin = mouse.getAbsolutePosition()
	local oFrame = geometry.rect(self.origin.x-5, self.origin.y-5, 10, 10)
	local color = {["red"]=0,["blue"]=0,["green"]=1,["alpha"]=0.75}

	self.highlight = drawing.circle(oFrame)
		:setStrokeColor(color)
		:setFill(false)
		:setStrokeWidth(3)
		:show()
	
	-- start the timer
	self.running = true
	Pucker.loop(self)
	return self
end

function Pucker:stop()
	self.running = false
end

function Pucker:cleanup()
	self.running = false
	self.highlight:delete()
	self.pctUI = nil
	self.angleUI = nil
	self.origin = nil
end

function Pucker:accumulate(xShift, yShift)
	if xShift < 1 and xShift > -1 then
		self.xShift = self.xShift + xShift
		if self.xShift > 1 or self.xShift < -1 then
			xShift = self.xShift
			self.xShift = 0
		else
			xShift = 0
		end
	end
	if yShift < 1 and yShift > -1 then
		self.yShift = self.yShift + yShift
		if self.yShift > 1 or self.yShift < -1 then
			yShift = self.yShift
			self.yShift = 0
		else
			yShift = 0
		end
	end
	return xShift, yShift
end

function Pucker.loop(pucker)
	if not pucker.running then
		pucker:cleanup()
		return
	end
	
	local pctUI = pucker.pctUI
	local angleUI = pucker.angleUI
	
	local current = mouse.getAbsolutePosition()
	local xDiff = current.x - pucker.origin.x
	local yDiff = pucker.origin.y - current.y
	
	local xShift = Pucker.tension(xDiff)
	local yShift = Pucker.tension(yDiff)
	
	xShift, yShift = pucker:accumulate(xShift, yShift)
	
	local pctValue = pctUI and tonumber(pctUI:attributeValue("AXValue") or "0") + yShift
	local angleValue = angleUI and (tonumber(angleUI:attributeValue("AXValue") or "0") + xShift + 360) % 360
	
	if yShift and pctUI then pctUI:setAttributeValue("AXValue", tostring(pctValue)):doConfirm() end
	if xShift and angleUI then angleUI:setAttributeValue("AXValue", tostring(angleValue)):doConfirm() end
	
	timer.doAfter(0.0005, function() Pucker.loop(pucker) end)
end

function Pucker.tension(diff)
	local factor = diff < 0 and -1 or 1
	local tension = Pucker.elasticity * (diff*factor-Pucker.naturalLength) / Pucker.naturalLength
	return tension < 0 and 0 or tension * factor
end

return Pucker
