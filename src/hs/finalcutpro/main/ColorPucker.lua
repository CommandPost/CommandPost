local mouse									= require("hs.mouse")
local geometry								= require("hs.geometry")
local drawing								= require("hs.drawing")
local timer									= require("hs.timer")

local Pucker = {}

Pucker.naturalLength = 20
Pucker.elasticity = Pucker.naturalLength/10

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
	
	self:drawMarker()
	
	-- start the timer
	self.running = true
	Pucker.loop(self)
	return self
end

function Pucker:drawMarker()
	local d = Pucker.naturalLength*2
	local oFrame = geometry.rect(self.origin.x-d/2, self.origin.y-d/2, d, d)
	local color = {red=1, blue=1, green=1, alpha=1}

	self.circle = drawing.circle(oFrame)
		:setStrokeColor(color)
		:setFill(true)
		:setStrokeWidth(1)
		
	self.arc = drawing.arc(self.origin, d/2, 135, 315)
		:setFillColor(color)
		:setFill(true)
	
	local rFrame = geometry.rect(self.origin.x-d/4, self.origin.y-d/8, d/2, d/4)
	self.negative = drawing.rectangle(rFrame)
		:setStrokeColor({white=1, alpha=0.75})
		:setStrokeWidth(1)
		:setFillColor({white=0, alpha=1.0 })
		:setFill(true)
end

function Pucker:colorMarker(pct, angle)
	local solidColor = nil
	local fillColor = nil
	
	if angle then
		solidColor = {hue = angle/360, saturation = 1, brightness = 1, alpha = 1}
		fillColor = {hue = angle/360, saturation = 1, brightness = 1, alpha = math.abs(pct/100)}
	else
		solidColor = {hue = 0, saturation = 0, brightness = 1, alpha = 1}
		fillColor = {hue = 0, saturation = 0, brightness = 1, alpha = math.abs(pct/100)}
	end
	
	self.circle:setStrokeColor(solidColor)
		:setFillColor(fillColor)
		:show()
		
	self.arc:setStrokeColor(solidColor)
		:setFillColor(solidColor)
		:show()
		
	if angle and pct < 0 then
		self.negative:show()
	else
		self.negative:hide()
	end
end

function Pucker:stop()
	self.running = false
end

function Pucker:cleanup()
	self.running = false
	self.circle:delete()
	self.circle = nil
	self.arc:delete()
	self.arc = nil
	self.negative:delete()
	self.negative = nil
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
	pucker:colorMarker(pctValue, angleValue)
	
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
