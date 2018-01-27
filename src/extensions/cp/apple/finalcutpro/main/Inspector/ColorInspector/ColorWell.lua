--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWell ===
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
local asRGB, asHSB						= color.asRGB, color.asHSB

local prop                              = require("cp.prop")
local axutils							= require("cp.ui.axutils")

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
	rgbValue = asRGB(hsbValue)

    return cleanColor(rgbValue)
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
		return string.format("rgb %d %d %d %d", value.red, value.green, value.blue, value.alpha)
	end
	return ""
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWell.matches(element)
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

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWell:new(parent, finderFn) -> ColorWell
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

return ColorWell