--- === cp.apple.finalcutpro.inspector.color.ColorWell ===
---
--- Represents a single Color Well in the Color Wheels Inspector.

local require = require

local log                               = require "hs.logger" .new "colorWell"

local color                             = require "hs.drawing.color"
local inspect                           = require "hs.inspect"

local Element                           = require "cp.ui.Element"
local Do                                = require "cp.rx.go.Do"

local ColorWell = Element:subclass("cp.apple.finalcutpro.inspector.color.ColorWell")

local asRGB, asHSB = color.asRGB, color.asHSB
local min, cos, sin, atan, floor, sqrt, modf = math.min, math.cos, math.sin, math.atan, math.floor, math.sqrt, math.modf

-- COLOR_THRESHOLD -> number
-- Constant
-- Anything below this value is considered to be 0
local COLOR_THRESHOLD = 1/25500

-- BRIGHTNESS_CLAMP -> number
-- Constant
-- Brightness Clamp as a number.
local BRIGHTNESS_CLAMP = 85/255

--- cp.apple.finalcutpro.inspector.color.ColorWell.KEY_PRESS
--- Constant
--- This can be used with `nudge` to shift by the same distance
--- as a key press. Multiple key presses can be simulated by
--- multiplying it by the number of keys. For example:
---
--- ```lua
--- -- Nudge it two key presses to the right
--- colorWell:nudge(2*ColorWell.KEY_PRESS, 0)
--- ```
ColorWell.static.KEY_PRESS = 1/600

-- toColorValue(value) -> number
-- Function
-- Converts a color value.
--
-- Parameters:
--  * `value` - The value to convert.
--
-- Returns:
--  * Color value as number.
local function toColorValue(value)
    value = tonumber(value)
    if value < COLOR_THRESHOLD then
        value = 0
    end
    return value
end

-- colorWellValueToTable(value, hueShift) -> table | nil
-- Function
-- Converts a AXColorWell Value to a `hs.drawing.color` table.
--
-- Parameters:
--  * value         - A AXColorWell Value String (i.e. "rgb 0.5 0 1 0")
--
-- Returns:
--  * A table or `nil` if an error occurred.
local function colorWellValueToColor(value)
    if type(value) ~= "string" then
        log.ef("Invalid AXColorWell value: %s", inspect(value))
        return nil
    end
    local valueToTable = string.split(value, " ") -- luacheck: ignore
    if not valueToTable or #valueToTable ~= 5 then
        return nil
    end
    local rgbValue = {
        red = toColorValue(valueToTable[2]),
        green = toColorValue(valueToTable[3]),
        blue = toColorValue(valueToTable[4]),
        alpha = toColorValue(valueToTable[5]),
    }

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
        -- Only convert from HSB to RGB if the value is actually HSB. This is because
        -- asRGB() only support positive numbers.
        if value and value.hue then
            value = asRGB(value)
        end

        -- Make sure the `value` table is a valid `hs.drawing.color` object.
        -- This is necessary, if passing in an empty table, when doing a
        -- reset for example.
        if not value.red then value.red = 0 end
        if not value.green then value.green = 0 end
        if not value.blue then value.blue = 0 end
        if not value.alpha then value.alpha = 1 end

        return string.format("rgb %g %g %g %g", value.red, value.green, value.blue, value.alpha)
    end
    return ""
end

-- round(value) -> number
-- Function
-- Rounds a value the nearest number.
--
-- Parameters:
--  * `value` - The value as number.
--
-- Returns:
--  * The rounded number.
local function round(value)
    return floor(value + 0.5)
end

-- center(frame) -> table
-- Function
-- Returns the centered frame.
--
-- Parameters:
--  * frame - The frame to center.
--
-- Returns:
--  * The centered frame.
local function center(frame)
    return {x = floor(frame.x + frame.w/2), y = floor(frame.y + frame.h/2)}
end

-- toOrientation(theColor, hueShift) -> {right,down}
-- Function
-- Converts `theColor` to an `orientation` table with `right` and `up` values.
-- The values will range between `-1` and `+1`. Negative values are shifts
-- to the left and down, respectively.
--
-- Parameters:
-- * theColor       - The `hs.drawing.color` to convert.
-- * hueShift       - The amount to shift the hue
--
-- Returns:
-- * The orientation table.
local function toOrientation(theColor, hueShift)
    if theColor and type(theColor) == "table" then
        theColor = asHSB(theColor)

        hueShift = hueShift or 0
        local h = 1 - theColor.hue + hueShift
        local b = theColor.brightness
        local a = h * math.pi * 2
        return {right = b * cos(a), up = b * sin(a) * -1}
    else
        return nil
    end
end

-- fromOrientation(theOrientation) -> hs.drawing.color
-- Function
-- Converts the `orientation` table with `right` and `up` values between `-1` and `1`
-- into an RGB `hs.drawing.color`.
--
-- Parameters:
-- * theOrientation     - The orientation table.
--
-- Returns:
-- * The orientation color.
local function fromOrientation(o, hueShift)
    hueShift = hueShift or 0
    o.right, o.up = o.right or 0, o.up or 0
    local h, b, _
    h, b = atan(o.up*-1, o.right) / ( math.pi * 2), sqrt(o.right * o.right + o.up * o.up)
    _, h = modf(1 - h + hueShift)
    b = min(1.0, b)

    return asRGB({hue=h, saturation=1, brightness=b})
end

-- toXY(c, frame, clamp, hueShift) -> table
-- Function
-- Converts a color to a position to the center of the provided color well frame.
-- The color well only shows movement to 85 out of 255 possible values. If `clamp`
-- is `true`, the returned XY position will be clamped inside the circle. If `false`,
-- the XY position will be where where it would be if not clamped.
--
-- Parameters:
--  * c          - The hs.drawing.color to position
--  * frame      - The frame for the outer boundary of the color well cirle.
--  * clamp      - If `true`, the returned position will be clamped to the color well circle.
--  * hueShift   - The amount to shift the hue.
--
-- Returns:
--  * The position of the color, relative to the center of the color well.
local function toXY(c, frame, clamp, hueShift)
    local o = toOrientation(c, hueShift)

    local radius = min(frame.w/2, frame.h/2) / (clamp and 1 or BRIGHTNESS_CLAMP)
    local pos = {x = o.right*radius, y = o.up*radius*-1}
    pos.x, pos.y = round(pos.x), round(pos.y)

    local ctr = center(frame)
    pos.x, pos.y = pos.x + ctr.x, pos.y + ctr.y

    -- _highlightPoint(pos)
    return pos
end

-- fromXY(pos, frame, absolute, hueShift) -> table
-- Function
-- Converts an XY position to a color, relative to the provided color well circle `frame`.
-- The return value should be multiplied by the radius of the particular color well.
--
-- Parameters:
--  * pos        - The `{x=?, y=?}` position of the location.
--  * frame      - The frame for the outer boundary of the color well cirle.
--  * absolute   - If `true`, the position and frame are considered to be absolute screen positions.
--  * hueShift   - The amount to shift the hue.
--
-- Returns:
--  * The `hs.drawing.color` for the position, relative to the color well.
local function fromXY(pos, frame, absolute, hueShift)
    local x, y = pos.x, pos.y
    if absolute then
        local ctr = center(frame)
        x, y = x - ctr.x, y - ctr.y
    end

    local radius = min(frame.w/2, frame.h/2) / BRIGHTNESS_CLAMP
    local o = {right = x/radius, up = y/radius*-1}

    return fromOrientation(o, hueShift)
end


--- cp.apple.finalcutpro.inspector.color.ColorWell.matches(element)
--- Function
--- Checks if the specified element is a Color Well.
---
--- Parameters:
--- * element   - The element to check
---
--- Returns:
--- * `true` if the element is a Color Well.
function ColorWell.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXColorWell"
end

--- cp.apple.finalcutpro.inspector.color.ColorWell(parent, uiFinder[, hueShift]) -> ColorWell
--- Constructor
--- Creates a new `ColorWell` instance, with the specified parent and finder function.
--- The finder function should return the specific color well UI element that this instance represents.
---
--- Parameters:
--- * parent    - The parent object
--- * uiFinder  - Returns the `axuielement` that represents the color well.
--- * hueShift  - The amount to shift the hue.
---
--- Returns:
--- * A new `ColorWell` instance.
function ColorWell:initialize(parent, uiFinder, hueShift)
    Element.initialize(self, parent, uiFinder)
    self._hueShift = hueShift or 0
end

function ColorWell:hueShift()
    return self._hueShift
end

--- cp.apple.finalcutpro.inspector.color.ColorWell.focused <cp.pref: boolean>
--- Field
--- Gets and sets whether the Color Well has focus.
function ColorWell.lazy.prop:focused()
    return self:parent().focused
end

--- cp.apple.finalcutpro.inspector.color.ColorInspector.value <cp.prop: cp.drawing.color>
--- Field
--- Gets the Color Well Value as a `cp.drawing.color`.
function ColorWell.lazy.prop:value()
    return self.UI:mutate(
        function(original)
            local ui = original()
            return ui and colorWellValueToColor(ui:attributeValue("AXValue")) or nil
        end,
        function(value, original)
            local ui = original()
            if ui then
                ui:setAttributeValue("AXValue", colorToColorWellValue(value))
            end
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWell.center <cp.prop: point; read-only>
--- Field
--- The center point of the ColorWell. A table with `{x=..., y=...}`.
function ColorWell.lazy.prop:center()
    return self.frame:mutate(function(original)
        return center(original())
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorWell.puckPosition <cp.prop: hs.geometry.point>
--- Field
--- Absolute X/Y screen position for the puck in the Color Well. Colours outside the bounds are clamped inside the color well.
function ColorWell.lazy.prop:puckPosition()
    return self.value:mutate(
        function(original)
            local frame = self:frame()
            if frame then
                return toXY(original(), frame, true, self:hueShift())
            end
            return nil
        end,
        function(position, original)
            local frame = self:frame()
            if frame then
                original(fromXY(position, frame, true, self:hueShift()))
            end
        end
    ):monitor(self.frame)
end

--- cp.apple.finalcutpro.inspector.color.ColorWell.colorPosition <cp.prop: hs.geometry.point>
--- Field
--- X/Y screen position for the current color value of the Color Well. This ignores the bounds of the
--- actual Color Well circle, which only extends to 85 out of 255 values.
function ColorWell.lazy.prop:colorPosition()
    return self.value:mutate(
        function(original)
            local frame = self:frame()
            if frame then
                return toXY(original(), frame, false, self:hueShift())
            end
            return nil
        end,
        function(position, original)
            local frame = self:frame()
            if frame then
                original(fromXY(position, frame, false, self:hueShift()))
            end
        end
    ):monitor(self.frame)
end

--- cp.apple.finalcutpro.inspector.color.ColorWell.colorOrientation <cp.prop: table>
--- Field
--- Provides the orientation of the color as a table containing an `up` and `right` value.
--- The values will have a range between `-1` and `1`.
function ColorWell.lazy.prop:colorOrientation()
    return self.value:mutate(
        function(original)
            return toOrientation(original(), self:hueShift())
        end,
        function(orientation, original)
            original(fromOrientation(orientation, self:hueShift()))
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorInspector:show() -> cp.apple.finalcutpro.inspector.color.ColorInspector
--- Method
--- Shows the Color Well.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.inspector.color.ColorInspector` object
function ColorWell:show()
    self:parent():show()
    return self
end

function ColorWell.lazy.method:doShow()
    return self:parent():doShow():Lable("ColorWell:doShow")
end

--- cp.apple.finalcutpro.inspector.color.ColorWell:select() -> cp.apple.finalcutpro.inspector.color.ColorWell
--- Method
--- Selects this color well.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `ColorWell` instance.
function ColorWell:select()
    self:parent():select()
    return self
end

function ColorWell.lazy.method:doSelect()
    return Do(self:parent():doSelect())
end

--- cp.apple.finalcutpro.inspector.color.ColorWell:nudge(right, up) -> self
--- Method
--- Nudges the `colorPosition` by `right`/`up` values. Negative `right` values shift left,
--- negative `up` values shift down. You may have decimal shift values.
---
--- Parameters:
---  * `right` - The number of steps to shift right. May be negative to shift left.
---  * `up` - The number of pixels to shift down. May be negative to shift down.
---
--- Returns:
---  * The `ColorWell` instance.
function ColorWell:nudge(right, up)
    right, up = right or 0, up or 0
    local o = self:colorOrientation()
    if o then
        o.right, o.up = o.right + right, o.up + up
        self:colorOrientation(o)
    end
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorWell:nudge(right, up) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that nudges the `colorPosition` by `right`/`up` values.
--- Negative `right` values shift left, negative `up` values shift down. You may have decimal shift values.
---
--- Parameters:
---  * `right` - The number of steps to shift right. May be negative to shift left.
---  * `up` - The number of pixels to shift down. May be negative to shift down.
---
--- Returns:
---  * The `ColorWell` instance.
function ColorWell:doNudge(right, up)
    return Do(function()
        self:nudge(right, up)
    end):ThenYield()
end

--- cp.apple.finalcutpro.inspector.color.ColorWell:reset() -> self
--- Method
--- Resets the color wheel.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorWell` instance.
function ColorWell:reset()
    self:value({})
end

function ColorWell.lazy.method:doReset()
    return Do(function()
        self:reset()
    end):ThenYield()
end

function ColorWell.__call(self, parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:value(value)
end

return ColorWell
