local mouse									= require("hs.mouse")
local geometry								= require("hs.geometry")
local drawing								= require("hs.drawing")
local timer									= require("hs.timer")

local Pucker = {}

function Pucker:new(colorBoard, aspect, property)
	o = {
		colorBoard = colorBoard,
		aspect = aspect,
		property = property
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Pucker:start()
	debugMessage("Pucker:start() - setting up")
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
	debugMessage("Pucker:start() - starting loop")
	self.running = true
	Pucker.loop(self)
	return self
end

function Pucker:stop()
	debugMessage("Pucker:stop() - stopping")
	self.running = false
end

function Pucker:cleanup()
	self.running = false
	self.highlight:delete()
	self.pctUI = nil
	self.angleUI = nil
	self.origin = nil
end

function Pucker.loop(pucker)
	if not pucker.running then
		debugMessage("Pucker.loop() - stopping.")
		pucker:cleanup()
		return
	end
	
	local pctUI = pucker.pctUI
	local angleUI = pucker.angleUI
	
	local current = mouse.getAbsolutePosition()
	local xDiff = current.x - pucker.origin.x
	local yDiff = pucker.origin.y - current.y
	
	local xShift = xDiff ~= 0 and xDiff/math.abs(xDiff) or 0
	local yShift = yDiff ~= 0 and yDiff/math.abs(yDiff) or 0
	
	local pctValue = pctUI and tonumber(pctUI:attributeValue("AXValue") or "0") + yShift
	local angleValue = angleUI and tonumber(angleUI:attributeValue("AXValue") or "0") + xShift
	-- loop angle at the boundaries
	angleValue = (angleValue + 360) % 360 
	
	if pctUI then pctUI:setAttributeValue("AXValue", tostring(pctValue)):doConfirm() end
	if angleUI then angleUI:setAttributeValue("AXValue", tostring(angleValue)):doConfirm() end
	
	timer.doAfter(0.0001, function() Pucker.loop(pucker) end)
end

return Pucker
