--- === cp.apple.finalcutpro.inspector.color.ColorWheel ===
---
--- Represents a single Color Well in the Color Wheels Inspector.

local require = require

-- local log                               = require("hs.logger").new("colorWheel")

local axutils							= require("cp.ui.axutils")
local Element                           = require("cp.ui.Element")

local ColorWell							= require("cp.apple.finalcutpro.inspector.color.ColorWell")
local ValueIndicator					= require("cp.apple.finalcutpro.inspector.color.ValueIndicator")
local Button							= require("cp.ui.Button")

local Do                                = require("cp.rx.go.Do")
local If                                = require("cp.rx.go.If")

local ColorWheel = Element:subclass("cp.apple.finalcutpro.inspector.color.ColorWheel")

--- cp.apple.finalcutpro.inspector.color.ColorWheel.TYPE
--- Constant
--- The possible types of ColorWheels: MASTER, SHADOWS, MIDTONES, HIGHLIGHTS.
ColorWheel.static.TYPE = {
    MASTER      = { single = 1, all = 1 },
    SHADOWS     = { single = 2, all = 3 },
    MIDTONES    = { single = 3, all = 4 },
    HIGHLIGHTS  = { single = 4, all = 2 },
}

-- cp.apple.finalcutpro.inspector.clor.ColorWheel.HUE_SHIFT -> number
-- Constant
-- The hue shift currently being output from AXColorWell values.
ColorWheel.static.HUE_SHIFT = 4183333/6000000

--- cp.apple.finalcutpro.inspector.color.ColorWheel.matches(element)
--- Function
--- Checks if the specified element is a Color Well.
---
--- Parameters:
--- * element	- The element to check
---
--- Returns:
--- * `true` if the element is a Color Well.
function ColorWheel.static.matches(element)
    if Element.matches(element) and element:attributeValue("AXRole") == "AXGroup" and #element == 4 then
        return axutils.childMatching(element, ColorWell.matches) ~= nil
    end
    return false
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel(parent, type) -> ColorWheel
--- Constructor
--- Creates a new `ColorWheel` instance, with the specified parent and type.
---
--- Parameters:
--- * parent	- The parent object.
--- * type		- The type of color wheel. Must be one of the `ColorWheel.TYPE` values.
---
--- Returns:
--- * A new `ColorWheel` instance.
function ColorWheel:initialize(parent, type)
    local UI = parent.contentUI:mutate(function(original)
        return axutils.cache(self, "_ui", function()
            local ui = original()
            if ui then
                local groups = axutils.childrenWithRole(ui, "AXGroup")
                if parent:viewingAllWheels() then
                    --------------------------------------------------------------------------------
                    -- All Wheels:
                    --------------------------------------------------------------------------------
                    return axutils.childFromTop(ui, 2 + self._type.all)
                elseif not parent:viewingAllWheels() and groups and #groups == 4 then
                    --------------------------------------------------------------------------------
                    -- Single Wheels - with all wheels visible (i.e. Inspector is very wide):
                    --------------------------------------------------------------------------------
                    local children = axutils.childrenWithRole(ui, "AXGroup")
                    return children and children[self._type.single]
                elseif parent.wheelType:selectedOption() == self._type.single then
                    --------------------------------------------------------------------------------
                    -- Single Wheels - with only a single wheel visible:
                    --------------------------------------------------------------------------------
                    return axutils.childFromTop(ui, 4)
                end
            end
            return nil
        end, ColorWheel.matches)
    end)

    Element.initialize(self, parent, UI)

    self._type = type
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel.focused <cp.pref: boolean>
--- Field
--- Gets and sets whether the Color Well has focus.
function ColorWheel.lazy.prop:focused()
    return axutils.prop(self.UI, "AXFocused", true)
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel.colorValue <cp.prop: hs.drawing.color>
--- Field
--- The current color value, as a `hs.drawing.color` table.
function ColorWheel.lazy.prop:colorValue()
    return self.colorWell.value
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel.puckPosition <cp.prop: point>
--- Field
--- Absolute X/Y screen position for the puck in the Color Well. Colours outside the bounds are clamped inside the color well.
function ColorWheel.lazy.prop:puckPosition()
    return self.colorWell.puckPosition
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel.colorPosition <cp.prop: point>
--- Field
--- X/Y screen position for the current color value of the Color Well. This ignores the bounds of the
--- actual Color Well circle, which only extends to 85 out of 255 values.
function ColorWheel.lazy.prop:colorPosition()
    return self.colorWell.colorPosition
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel.colorOrientation <cp.prop: table>
--- Field
--- Provides the orientation of the color as a table containing an `up` and `right` value.
--- The values will have a range between `-1` and `1`.
function ColorWheel.lazy.prop:colorOrientation()
    return self.colorWell.colorOrientation
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel.saturationValue <cp.prop: number>
--- Field
--- The current saturation value, as a number between 0 and 10.
function ColorWheel.lazy.prop:saturationValue()
    return self.saturation.value
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel.brightnessValue <cp.prop: number>
--- Field
--- The current brightness value, as a number between -12 and 10.
function ColorWheel.lazy.prop:brightnessValue()
    return self.brightness.value
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel:show() -> self
--- Method
--- Shows the `ColorWheel`, if possible.
---
--- Returns:
--- * The same `ColorWheel` instance, for chaining.
function ColorWheel:show()
    self:parent():show()
    -- ensure the wheel type is correct, if visible.
    local wheelType = self:parent().wheelType
    if wheelType:isShowing() then
        wheelType:selectedOption(self._type.single)
    end
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that attempts to show the `ColorWheel`.
---
--- Returns:
--- * The `Statement`, resolving to `true` if shown, `false` if not.
function ColorWheel.lazy.method:doShow()
    local wheelType = self:parent().wheelType
    return Do(self:parent():doShow())
    :Then(
        If(wheelType.isShowing):Then(
            wheelType:doSelectOption(self._type.single)
        )
        :Otherwise(true)
    )
    :Label("ColorWheel:doShow")
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel:select() -> cp.apple.finalcutpro.inspector.color.ColorWheel
--- Method
--- Shows and selects this color wheel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `ColorWheel` instance.
function ColorWheel:select()
    self:show():focused(true)
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel:doSelect() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that attempts to select this `ColorWheel`.
---
--- Returns:
--- * The `Statement`, resolving to `true` if selected, otherwise `false`.
function ColorWheel.lazy.method:doSelect()
    return Do(self:doShow())
    :Then(function()
        self:focused(true)
    end)
    :ThenYield()
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel.colorWell <ColorWell>
--- Method
--- Returns the `ColorWell` for this ColorWheel.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorWell` instance.
function ColorWheel.lazy.value:colorWell()
    return ColorWell(self, function()
        return axutils.childMatching(self:UI(), ColorWell.matches)
    end, ColorWheel.HUE_SHIFT)
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel.saturation <ValueIndicator>
--- Method
--- Returns the saturation `ValueIndicator` for this ColorWheel.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The saturation `ValueIndicator` instance.
function ColorWheel.lazy.value:saturation()
    return ValueIndicator(self,
        self.UI:mutate(function(original)
            return axutils.childFromLeft(original(), 1)
        end),
        0, 10,
        function(value) -- toAXValue
            return value / 2
        end,
        function(value) -- fromAXValue
            return value * 2
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel.brightness <ValueIndicator>
--- Method
--- Returns the brightness `ValueIndicator` for this ColorWheel.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The brightness `ValueIndicator` instance.
function ColorWheel.lazy.value:brightness()
    return ValueIndicator(self,
        self.UI:mutate(function(original)
            return axutils.childFromRight(axutils.childrenWithRole(original(), "AXValueIndicator"), 1)
        end),
        -12, 10,
        function(value) -- toAXValue
            return (value+1)/2
        end,
        function(value) -- fromAXValue
            return value*2-1
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel.reset <cp.ui.Button>
--- Field
--- A [Button](cp.ui.Button.md) that resets the color wheel values, if the `ColorWheel` is showing.
--- May be called directly to click (e.g. `wheel:reset()`).
function ColorWheel.lazy.value:reset()
    return Button(self, function()
        return axutils.childMatching(self:UI(), Button.matches)
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel:nudgeColor(right, up) -> self
--- Method
--- Nudges the `colorPosition` by `right`/`up` values. Negative `right` values shift left,
--- negative `up` values shift down. You may have decimal shift values.
---
--- Parameters:
---  * `right` - The number of steps to shift right. May be negative to shift left.
---  * `up` - The number of pixels to shift down. May be negative to shift down.
---
--- Returns:
--- * The `ColorWheel` instance.
function ColorWheel:nudgeColor(right, up)
    self.colorWell:nudge(right, up)
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorWheel:doNudgeColor(right, up) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that nudges the `colorPosition` by `right`/`up` values.
--- Negative `right` values shift left, negative `up` values shift down. You may have decimal shift values.
---
--- Parameters:
---  * `right` - The number of steps to shift right. May be negative to shift left.
---  * `up` - The number of pixels to shift down. May be negative to shift down.
---
--- Returns:
--- * The `Statement`, resolving to `true` if successful.
function ColorWheel:doNudgeColor(right, up)
    return self.colorWell:doNudge(right, up):Label("ColorWheel:doNudgeColor")
end

return ColorWheel
