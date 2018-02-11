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
local tools									= require("cp.tools")
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

Puck._active = nil

-- tension(diff) -> number
-- Function
-- Calculates the tension given the x/y difference value, based on the Puck elasticity and natural length.
--
-- Parameters:
-- * diff	- The amount of stretch in a given dimension.
--
-- Returns:
-- * The tension factor.
local function tension(diff)
	local factor = diff < 0 and -1 or 1
	local t = Puck.elasticity * (diff*factor-Puck.naturalLength) / Puck.naturalLength
	return t < 0 and 0 or t * factor
end

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

	-- finds the current label for the row.
	o.label = o.row.label:wrap(o)

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
	if ui then
		local f = ui:frame()
		-- local centre = geometry(f.x + f.w/2, f.y + f.h/2)
		local centre = geometry(f).center
		tools.ninjaMouseClick(centre)
	end
	return self
end

Puck.skimming = prop(function(self)
	return not self:app():getPreference("FFDisableSkimming", false)
end):bind(Puck)

-- TODO: Add documentation
function Puck:start()
	-- stop any running pucks when starting a new one.
	if Puck._active then
		Puck._active:stop()
	end

	-- disable skimming while the Puck is running
	self.menuBar = self:parent():app():menuBar()
	if self.skimming() then
		self.menuBar:checkMenu({"View", "Skimming"})
	end

	Puck._active = self

	-- select the puck to ensure properties are available.
	self:select()

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

	local aStart, aEnd = self:getArc()
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
	local fillColor

	if angle then
		solidColor = {hue = angle/360, saturation = 1, brightness = 1, alpha = 1}
		fillColor = {hue = angle/360, saturation = 1, brightness = 1, alpha = math.abs(pct/100)}
	else
		local brightness = pct >= 0 and 1 or 0
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
	Puck._active = nil
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
function Puck:loop()
	if not self.running then
		self:cleanup()
		return
	end

	local pct = self.percent
	local angle = self.angle

	local current = mouse.getAbsolutePosition()
	local xDiff = current.x - self.origin.x
	local yDiff = self.origin.y - current.y

	local xShift = tension(xDiff)
	local yShift = tension(yDiff)

	xShift, yShift = self:accumulate(xShift, yShift)

	local pctValue = (pct:value() or 0) + yShift
	local angleValue = ((angle:value() or 0) + xShift + 360) % 360
	self:colorMarker(pctValue, angleValue)

	if yShift then pct:value(pctValue) end
	if xShift then angle:value(angleValue) end

	timer.doAfter(0.01, function() self:loop() end)
end

function Puck:__tostring()
	return string.format("%s - %s", self:parent(), self:label() or "[Unknown]")
end

return Puck