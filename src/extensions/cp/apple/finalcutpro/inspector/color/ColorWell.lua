--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.color.ColorWell ===
---
--- Represents a single Color Well in the Color Wheels Inspector.
---
--- Requires Final Cut Pro 10.4 or later.
--
-----------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log                               = require("hs.logger").new("colorWell")

local color								= require("hs.drawing.color")
local inspect							= require("hs.inspect")
local asRGB, asHSB						= color.asRGB, color.asHSB

local prop                              = require("cp.prop")
local axutils							= require("cp.ui.axutils")

local min, cos, sin, atan, floor, sqrt, modf	= math.min, math.cos, math.sin, math.atan, math.floor, math.sqrt, math.modf

local ColorWell = {}

-- the hue shift currently being output from AXColorWell values.
local HUE_SHIFT = 4183333/6000000
-- anything below this value is considered to be 0
local COLOR_THRESHOLD = 1/25500

local function toColorValue(value)
	value = tonumber(value)
	if value < COLOR_THRESHOLD then
		value = 0
	end
	return value
end

local function cleanColor(value)
	for k,v in pairs(value) do
		value[k] = toColorValue(v)
	end
	return value
end

-- colorWellValueToTable(value) -> table | nil
-- Function
-- Converts a AXColorWell Value to a `hs.drawing.color` table.
--
-- Parameters:
--  * value - A AXColorWell Value String (i.e. "rgb 0.5 0 1 0")
--
-- Returns:
--  * A table or `nil` if an error occurred.
local function colorWellValueToColor(value)
    if type(value) ~= "string" then
        log.ef("Invalid AXColorWell value: %s", inspect(value))
        return nil
    end
    local valueToTable = string.split(value, " ")
    if not valueToTable or #valueToTable ~= 5 then
        return nil
	end
	local rgbValue = {
        red = toColorValue(valueToTable[2]),
		green = toColorValue(valueToTable[3]),
		blue = toColorValue(valueToTable[4]),
		alpha = toColorValue(valueToTable[5]),
	}

	-- NOTE: There is a bug in AXColorWell which shifts the output value color from the actual value.
	-- This code compensates for that shift.
	local hsbValue = asHSB(rgbValue)
    local theHue = hsbValue.hue
    theHue = theHue + HUE_SHIFT
    theHue = theHue > 1 and (theHue-1) or theHue < 0 and (theHue+1) or theHue
	hsbValue.hue = theHue
	rgbValue = cleanColor(asRGB(hsbValue))
	log.df("value: hsb: %s, rgb: %s", inspect(hsbValue), inspect(rgbValue))

    return rgbValue
end

-- colorTocolorWellValue(value) -> string | nil
-- Function
-- Converts a `hs.drawing.color` to a AXColorWell Value string.
--
-- Parameters:
--  * value - A color table (RGB or HSB)
--
-- Returns:
--  * A string or `nil` if an error occurred.
local function colorToColorWellValue(value)
	if value then
		value = asRGB(value)
		return string.format("rgb %g %g %g %g", value.red, value.green, value.blue, value.alpha)
	end
	return ""
end

--- cp.apple.finalcutpro.inspector.color.ColorWell.minPosition
--- Constant
--- The minimum relative X or Y value for the well, for `colorPosition`.
ColorWell.minPosition = -175

--- cp.apple.finalcutpro.inspector.color.ColorWell.maxPosition
--- Constant
--- The maximum relative X or Y value for the well, for `colorPosition`.
ColorWell.maxPosition = 176

--- cp.apple.finalcutpro.inspector.color.ColorWell.matches(element)
--- Function
--- Checks if the specified element is a Color Well.
---
--- Parameters:
--- * element	- The element to check
---
--- Returns:
--- * `true` if the element is a Color Well.
function ColorWell.matches(element)
	return axutils.isValid(element) and element:attributeValue("AXRole") == "AXColorWell"
end

--- cp.apple.finalcutpro.inspector.color.ColorWell:new(parent, finderFn) -> ColorWell
--- Method
--- Creates a new `ColorWell` instance, with the specified parent and finder function.
--- The finder function should return the specific color well UI element that this instance represents.
---
--- Parameters:
--- * parent - The parent object
--- * finderFn - Returns the `axuielement` that represents the color well.
---
--- Returns:
--- * A new `ColorWell` instance.
function ColorWell:new(parent, finderFn)
	local o = prop.extend({
		_parent = parent,
		_finder = finderFn,
	}, ColorWell)

	return o
end

function ColorWell:parent()
	return self._parent
end

function ColorWell:app()
	return self:parent():app()
end

function ColorWell:UI()
	return axutils.cache(self, "_ui",
		function()
			return self._finder()
		end
	)
end

function ColorWell:isShowing()
	return self:UI() ~= nil
end

function ColorWell:show()
	self:parent():show()
	return self
end

ColorWell.value = prop(
	function(self)
		local ui = self:UI()
		return ui and colorWellValueToColor(ui:attributeValue("AXValue")) or nil
	end,
	function(value, self)
		local ui = self:UI()
		if ui then
			ui:setAttributeValue("AXValue", colorToColorWellValue(value))
		end
	end
):bind(ColorWell)

ColorWell.frame = prop(
	function(self)
		local ui = self:UI()
		return ui and ui:attributeValue("AXFrame")
	end,
	function(value, self)
		local ui = self:UI()
		if ui then
			ui:setAttributeValue("AXFrame", value)
		end
	end
):bind(ColorWell)

local BRIGHTNESS_CLAMP = 85/255

local function round(value)
	return floor(value + 0.5)
end

local function centre(frame)
	return {x = floor(frame.x + frame.w/2), y = floor(frame.y + frame.h/2)}
end

--- cp.apple.finalcutpro.inspector.color.ColorWell.centre <cp.prop: point; read-only>
--- Field
--- The center point of the ColorWell. A table with `{x=..., y=...}`.
ColorWell.centre = prop(function(self)
	return centre(self:frame())
end):bind(ColorWell)

-- toXY(c, frame, absolute, clamp) -> table
-- Function
-- Converts a color to a position to the centre of the provided color well frame.
-- The color well only shows movement to 85 out of 255 possible values. If `clamp`
-- is `true`, the returned XY position will be clamped inside the circle. If `false`,
-- the XY position will be where where it would be if not clamped.
--
-- Parameters:
-- * c			- The hs.drawing.color to position
-- * frame		- The frame for the outer boundary of the color well cirle.
-- * absolute	- If `true`, the returned position will be the absolute screen position. Otherwise, it will be relative to the centre of the color well.
-- * clamp		- If `true`, the returned position will be clamped to the color well circle.
--
-- Returns:
-- * The position of the color, relative to the centre of the color well.
local toXY = function(c, frame, absolute, clamp)
	c = asHSB(c)

	local radius = min(frame.w/2, frame.h/2) / (clamp and 1 or BRIGHTNESS_CLAMP)
	local h = 1 - c.hue + HUE_SHIFT
	local b = clamp and min(BRIGHTNESS_CLAMP, c.brightness)/BRIGHTNESS_CLAMP or c.brightness
	local a = h * math.pi * 2
	local x, y = b * cos(a), b * sin(a)

	local pos = {x = round(x*radius), y = round(y*radius)}
	if absolute then
		local ctr = centre(frame)
		pos.x, pos.y = pos.x + ctr.x, pos.y + ctr.y
		-- _highlightPoint(pos)
	end
	return pos
end

-- fromXY(pos, frame, absolute) -> table
-- Function
-- Converts an XY position to a color, relative to the provided color well circle `frame`.
-- The return value should be multiplied by the radius of the particular color well.
--
-- Parameters:
-- * pos		- The `{x=?, y=?}` position of the location.
-- * frame		- The frame for the outer boundary of the color well cirle.
-- * absolute	- If `true`, the position and frame are considered to be absolute screen positions.
--
-- Returns:
-- * The `hs.drawing.color` for the position, relative to the color well.
local fromXY = function(pos, frame, absolute)
	local radius = min(frame.w/2, frame.h/2) / BRIGHTNESS_CLAMP
	local x, y = pos.x, pos.y
	if absolute then
		local ctr = centre(frame)
		x, y = x - ctr.x, y - ctr.y
	end

	local h, b, _
	h, b = atan(y, x) / ( math.pi * 2), sqrt(x * x + y * y) / radius
	_, h = modf(1 - h + HUE_SHIFT)
	b = min(1.0, b)
    return asRGB({hue=h, saturation=1, brightness=b})
end

--- cp.apple.finalcutpro.inspector.color.ColorWell.colorScreenPosition <cp.prop: hs.geometry.point>
--- Field
--- X/Y screen position for the current color value of the Color Well. This ignores the bounds of the
--- actual Color Well circle, which only extends to 85 out of 255 values.
ColorWell.colorScreenPosition = prop(
	function(self)
		local frame = self:frame()
		if frame then
			return toXY(self:value(), frame, true)
		end
		return nil
	end,
	function(position, self)
		local frame = self:frame()
		if frame then
			self:value(fromXY(position, frame, true))
		end
	end
):bind(ColorWell)

--- cp.apple.finalcutpro.inspector.color.ColorWell.colorScreenPosition <cp.prop: hs.geometry.point>
--- Field
--- Relative X/Y position for the current color value of the Color Well. This will be a `point` table,
--- with an `x` and `y` value between `-255` and `+255`. `{x=0,y=0}` is the centre point.
ColorWell.colorPosition = prop(
	function(self)
		local frame = self:frame()
		if frame then
			return toXY(self:value(), frame, false)
		end
		return nil
	end,
	function(position, self)
		local frame = self:frame()
		if frame then
			self:value(fromXY(position, frame, false))
		end
	end
):bind(ColorWell)

--- cp.apple.finalcutpro.inspector.color.ColorWell.puckScreenPosition <cp.prop: hs.geometry.point>
--- Field
--- Absolute X/Y screen position for the puck in the Color Well. Colours outside the bounds are clamped inside the color well.
ColorWell.puckScreenPosition = prop(
	function(self)
		local frame = self:frame()
		if frame then
			return toXY(self:value(), frame, true, true)
		end
		return nil
	end,
	function(position, self)
		local frame = self:frame()
		if frame then
			self:value(fromXY(position, frame, true))
		end
	end
):bind(ColorWell)

--- cp.apple.finalcutpro.inspector.color.ColorWell.puckPosition <cp.prop: hs.geometry.point>
--- Field
--- Relative X/Y position for the puck in the Color Well. Colours outside the bounds are clamped inside the color well.
ColorWell.puckPosition = prop(
	function(self)
		local frame = self:frame()
		if frame then
			return toXY(self:value(), frame, false, true)
		end
		return nil
	end,
	function(position, self)
		local frame = self:frame()
		if frame then
			self:value(fromXY(position, frame, false))
		end
	end
):bind(ColorWell)

--- cp.apple.finalcutpro.inspector.color.ColorWell:nudge(x, y) -> self
--- Method
--- Nudges the `colorPosition` by `x`/`y` values. Positive `x` values shift right,
--- positive `y` values shift down. Only integer values have an effect.
---
--- Parameters:
--- * x		- The number of pixels to shift horizontally.
--- * y		- The number of pixels to shift vertically.
---
--- Returns:
--- * The `ColorWell` instance.
function ColorWell:nudge(x, y)
	local pos = self:colorPosition()
	pos.x, pos.y = pos.x + x, pos.y + y
	self:colorPosition(pos)
	return self
end

return ColorWell