--- === cp.apple.finalcutpro.inspector.color.ValueIndicator ===
---
--- ValueIndicator Module.

local require = require

local log                           = require("hs.logger").new("valueIndicator")

local Element                       = require("cp.ui.Element")
local prop                          = require("cp.prop")

local ValueIndicator = Element:subclass("ValueIndicator")

--- cp.apple.finalcutpro.inspector.color.ValueIndicator.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function ValueIndicator.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXValueIndicator"
end

--- cp.apple.finalcutpro.inspector.color.ValueIndicator(parent, uiFinder, minValue, maxValue, toAXValueFn, fromAXValueFn) -> ValueIndicator
--- Constructor
--- Creates a new ValueIndicator.
---
--- Parameters:
---  * `parent`         - The parent table.
---  * `uiFinder`       - The function which returns the `axuielement`.
---  * `minValue`       - The minimum value allowed for the value.
---  * `maxValue`       - The maximum value allowed for the value.
---  * `toAXValueFn`    - The function which will convert the user value to the actual AXValue.
---  * `fromAXValueFn`  - The function which will convert the current AXValue to a user value.
---
--- Returns:
---  * New `ValueIndicator` instance.
function ValueIndicator:initialize(parent, uiFinder, minValue, maxValue, toAXValueFn, fromAXValueFn)
    Element.initialize(self, parent, uiFinder)

    self._minValue = minValue
    self._maxValue = maxValue
    self._toAXValueFn = toAXValueFn
    self._fromAXValueFn = fromAXValueFn
end

--- cp.apple.finalcutpro.inspector.color.ValueIndicator:isShowing() -> boolean
--- Method
--- Is the Value Indicator currently showing?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing, otherwise `false`
function ValueIndicator.lazy.prop:isShowing()
    return self:UI():ISNOT(nil):AND(self:parent().isShowing)
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.value <cp.prop: number>
--- Field
--- The value of the value indicator as a number.
function ValueIndicator.lazy.prop:value()
    return self.UI:mutate(
        function(original)
            local ui = original()
            local value = ui and ui:attributeValue("AXValue") or nil
            if value ~= nil then
                if self._fromAXValueFn then
                    value = self._fromAXValueFn(value)
                end
                return value
            end
            return nil
        end,
        function(value, original)
            local ui = original()
            if ui then
                if self._toAXValueFn then
                    value = self._toAXValueFn(value)
                end
                ui:setAttributeValue("AXValue", value)
            end
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ValueIndicator:shiftValue(value) -> cp.apple.finalcutpro.inspector.color.ValueIndicator
--- Method
--- Shifts the Value Indicator value.
---
--- Parameters:
---  * `value` - The amount to shift the value indicator by as a number.
---
--- Returns:
---  * The `cp.apple.finalcutpro.inspector.color.ValueIndicator` object.
function ValueIndicator:shiftValue(value)
    local currentValue = self:value()
    if currentValue and value then
        self.value:set(currentValue - value)
    else
        log.ef("Failed to shift value: %s", value)
    end
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.minValue <cp.prop: number>
--- Field
--- The minimum value of the indicator as a number.
function ValueIndicator.lazy.prop:minValue()
    return prop(function()
        return self._minValue
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.maxValue <cp.prop: number>
--- Field
--- The maximum value of the indicator as a number.
function ValueIndicator.lazy.prop:maxValue()
    return prop(function()
        return self._maxValue
    end)
end

--- cp.apple.finalcutpro.inspector.color.ValueIndicator:increment() -> cp.apple.finalcutpro.inspector.color.ValueIndicator
--- Method
--- Increments the value indicator.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.inspector.color.ValueIndicator` object.
function ValueIndicator:increment()
    local ui = self:UI()
    if ui then
        ui:doIncrement()
    end
    return self
end

--- cp.apple.finalcutpro.inspector.color.ValueIndicator:decrement() -> cp.apple.finalcutpro.inspector.color.ValueIndicator
--- Method
--- Decrements the value indicator.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.inspector.color.ValueIndicator` object.
function ValueIndicator:decrement()
    local ui = self:UI()
    if ui then
        ui:doDecrement()
    end
    return self
end

--- cp.apple.finalcutpro.inspector.color.ValueIndicator:saveLayout() -> table
--- Method
--- Saves the layout.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the layout.
function ValueIndicator:saveLayout()
    local layout = {}
    layout.value = self:getValue()
    return layout
end

--- cp.apple.finalcutpro.inspector.color.ValueIndicator:loadLayout(layout) -> none
--- Method
--- Loads a layout.
---
--- Parameters:
---  * `layout` - The layout table you want to load.
---
--- Returns:
---  * None
function ValueIndicator:loadLayout(layout)
    if layout then
        self:setValue(layout.value)
    end
end

return ValueIndicator
