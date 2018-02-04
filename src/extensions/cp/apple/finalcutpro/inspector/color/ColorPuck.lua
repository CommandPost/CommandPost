--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.color.ColorPuck ===
---
--- Color Puck Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log									= require("hs.logger").new("colorPuck")

local mouse									= require("hs.mouse")
local geometry								= require("hs.geometry")
local drawing								= require("hs.drawing")
local timer									= require("hs.timer")

local prop									= require("cp.prop")
local axutils								= require("cp.ui.axutils")
local PropertyRow							= require("cp.ui.PropertyRow")
local TextField								= require("cp.ui.TextField")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Puck = {}

Puck.range = {master=1, shadows=2, midtones=3, highlights=4}

Puck.naturalLength = 20
Puck.elasticity = Puck.naturalLength/10

function Puck.matches(element)
	return element and element:attributeValue("AXRole") == "AXButton"
end

-- TODO: Add documentation
function Puck:new(parent, puckNumber, labelKeys)
	assert(
		puckNumber >= Puck.range.master and puckNumber <= Puck.range.highlights,
		string.format("Please supply a puck number between %s and %s.", Puck.range.master, Puck.range.highlights)
	)

	local o = prop.extend({
		_parent = parent,
		_puckNumber = puckNumber,
		_labelKeys = labelKeys,
		xShift = 0,
		yShift = 0
	}, Puck)

	-- finds the 'row' for the property type
	o.row = PropertyRow:new(o, o._labelKeys, "contentUI")

	-- the 'percent' text field
	o.percent = TextField:new(o, function()
		local fields = axutils.childrenWithRole(o.row:children(), "AXTextField")
		return fields and fields[#fields] or nil
	end, tonumber)

	-- the 'angle' text field (only present for the 'color' aspect)
	o.angle = TextField:new(o, function()
		local fields = axutils.childrenWithRole(o.row:children(), "AXTextField")
		return fields and #fields > 1 and fields[1] or nil
	end, tonumber)

	return o
end

function Puck:parent()
	return self._parent
end

function Puck:app()
	return self:parent():app()
end

function Puck:UI()
	return axutils.cache(self, "_ui", function()
		local buttons = axutils.childrenWithRole(self:parent():UI(), "AXButton")
		return buttons and #buttons == 5 and buttons[self._puckNumber+1] or nil
	end, Puck.matches)
end

function Puck:contentUI()
	return self:parent():UI()
end

function Puck:isShowing()
	return self:UI() ~= nil
end

function Puck:show()
	self:parent():show()
	return self
end

function Puck:select()
	self:show()
	local ui = self:UI()
	if ui then ui:doPress() end
	return self
end

Puck.skimming = prop(function(self)
	return not self:app():getPreference("FFDisableSkimming", false)
end):bind(Puck)

-- TODO: Add documentation
function Puck:start()
	-- disable skimming while the Puck is running
	self.menuBar = self.colorBoard:app():menuBar()
	if self.skimming() then
		self.menuBar:checkMenu({"View", "Skimming"})
	end

	-- record the origin and draw a marker
	self.origin = mouse.getAbsolutePosition()

	self:drawMarker()

	-- start the timer
	self.running = true
	Puck.loop(self)
	return self
end

-- TODO: Add documentation
function Puck:getBrightness()
	if self.property == "global" then
		return 0.25
	elseif self.property == "shadows" then
		return 0
	elseif self.property == "midtones" then
		return 0.33
	elseif self.property == "highlights" then
		return 0.66
	else
		return 1
	end
end

-- TODO: Add documentation
function Puck:getArc()
	if self.angleUI then
		return 135, 315
	elseif self.property == "global" then
		return 0, 0
	else
		return 90, 270
	end
end

-- TODO: Add documentation
function Puck:drawMarker()
	local d = Puck.naturalLength*2
	local oFrame = geometry.rect(self.origin.x-d/2, self.origin.y-d/2, d, d)

	local brightness = self:getBrightness()
	local color = {hue=0, saturation=0, brightness=brightness, alpha=1}

	self.circle = drawing.circle(oFrame)
		:setStrokeColor(color)
		:setFill(true)
		:setStrokeWidth(1)

	aStart, aEnd = self:getArc()
	self.arc = drawing.arc(self.origin, d/2, aStart, aEnd)
		:setStrokeColor(color)
		:setFillColor(color)
		:setFill(true)

	local rFrame = geometry.rect(self.origin.x-d/4, self.origin.y-d/8, d/2, d/4)
	self.negative = drawing.rectangle(rFrame)
		:setStrokeColor({white=1, alpha=0.75})
		:setStrokeWidth(1)
		:setFillColor({white=0, alpha=1.0 })
		:setFill(true)
end

-- TODO: Add documentation
function Puck:colorMarker(pct, angle)
	local solidColor = nil
	local fillColor = nil

	if angle then
		solidColor = {hue = angle/360, saturation = 1, brightness = 1, alpha = 1}
		fillColor = {hue = angle/360, saturation = 1, brightness = 1, alpha = math.abs(pct/100)}
	else
		brightness = pct >= 0 and 1 or 0
		fillColor = {hue = 0, saturation = 0, brightness = brightness, alpha = math.abs(pct/100)}
	end

	if solidColor then
		self.circle:setStrokeColor(solidColor)
		self.arc:setStrokeColor(solidColor)
			:setFillColor(solidColor)
	end

	self.circle:setFillColor(fillColor):show()

	self.arc:show()

	if angle and pct < 0 then
		self.negative:show()
	else
		self.negative:hide()
	end
end

-- TODO: Add documentation
function Puck:stop()
	self.running = false
end

-- TODO: Add documentation
function Puck:cleanup()
	self.running = false
	if self.circle then
		self.circle:delete()
		self.circle = nil
	end
	if self.arc then
		self.arc:delete()
		self.arc = nil
	end
	if self.negative then
		self.negative:delete()
		self.negative = nil
	end
	self.origin = nil
	if self.skimming() and self.menuBar then
		self.menuBar:checkMenu({"View", "Skimming"})
	end
	self.menuBar = nil
	self.colorBoard.Puck = nil
end

-- TODO: Add documentation
function Puck:accumulate(xShift, yShift)
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

-- TODO: Add documentation
function Puck.loop(Puck)
	if not Puck.running then
		Puck:cleanup()
		return
	end

	local pctUI = Puck.percent:UI()
	local angleUI = Puck.angle:UI()

	local current = mouse.getAbsolutePosition()
	local xDiff = current.x - Puck.origin.x
	local yDiff = Puck.origin.y - current.y

	local xShift = Puck.tension(xDiff)
	local yShift = Puck.tension(yDiff)

	xShift, yShift = Puck:accumulate(xShift, yShift)

	local pctValue = pctUI and tonumber(pctUI:attributeValue("AXValue") or "0") + yShift
	local angleValue = angleUI and (tonumber(angleUI:attributeValue("AXValue") or "0") + xShift + 360) % 360
	Puck:colorMarker(pctValue, angleValue)

	if yShift and pctUI then pctUI:setAttributeValue("AXValue", tostring(pctValue)):doConfirm() end
	if xShift and angleUI then angleUI:setAttributeValue("AXValue", tostring(angleValue)):doConfirm() end

	timer.doAfter(0.01, function() Puck.loop(Puck) end)
end

-- TODO: Add documentation
function Puck.tension(diff)
	local factor = diff < 0 and -1 or 1
	local tension = Puck.elasticity * (diff*factor-Puck.naturalLength) / Puck.naturalLength
	return tension < 0 and 0 or tension * factor
end

return Puck