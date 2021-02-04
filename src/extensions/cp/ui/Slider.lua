--- === cp.ui.Slider ===
---
--- Slider Module.

local require       = require

local axutils       = require "cp.ui.axutils"
local Element       = require "cp.ui.Element"

local Slider = Element:subclass("cp.ui.Slider")

--- cp.ui.Slider.matches(element) -> boolean
--- Function
--- Checks if the provided `hs.axuielement` is a Slider.
---
--- Parameters:
---  * element		- The `axuielement` to check.
---
--- Returns:
---  * `true` if it's a match, or `false` if not.
function Slider.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXSlider"
end

--- cp.ui.Slider(parent, uiFinder) -> cp.ui.Slider
--- Constructor
--- Creates a new Slider
---
--- Parameters:
---  * parent		- The parent object. Should have an `isShowing` property.
---  * uiFinder		- The function which returns an `hs.axuielement` for the slider, or `nil`.
---
--- Returns:
---  * A new `Slider` instance.
function Slider:initialize(parent, uiFinder)
    Element.initialize(self, parent, uiFinder)
end

--- cp.ui.Slider.value <cp.prop: number>
--- Field
--- Sets or gets the value of the slider.
function Slider.lazy.prop:value()
    return axutils.prop(self.UI, "AXValue", true)
end

--- cp.ui.Slider.minValue <cp.prop: number; read-only>
--- Field
--- Gets the minimum value of the slider.
function Slider.lazy.prop:minValue()
    return axutils.prop(self.UI, "AXMinValue")
end

--- cp.ui.Slider.maxValue <cp.prop: number; read-only>
--- Field
--- Gets the maximum value of the slider.
function Slider.lazy.prop:maxValue()
    return axutils.prop(self.UI, "AXMaxValue")
end

--- cp.ui.Slider:getValue() -> number
--- Method
--- Gets the value of the slider.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The value of the slider as a number.
function Slider:getValue()
    return self:value()
end

--- cp.ui.Slider:setValue(value) -> self
--- Method
--- Sets the value of the slider.
---
--- Parameters:
---  * value - The value you want to set the slider to as a number.
---
--- Returns:
---  * Self
function Slider:setValue(value)
    self.value:set(value)
    return self
end

--- cp.ui.Slider:shiftValue(value) -> self
--- Method
--- Shifts the value of the slider.
---
--- Parameters:
---  * value - The value you want to shift the slider by as a number.
---
--- Returns:
---  * Self
function Slider:shiftValue(value)
    local currentValue = self:value()
    self.value:set(currentValue - value)
    return self
end

--- cp.ui.Slider:getMinValue() -> number
--- Method
--- Gets the minimum value of the slider.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The value as a number.
function Slider:getMinValue()
    return self:minValue()
end

--- cp.ui.Slider:getMaxValue() -> number
--- Method
--- Gets the maximum value of the slider.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The value as a number.
function Slider:getMaxValue()
    return self:maxValue()
end

--- cp.ui.Slider:increment() -> self
--- Method
--- Increments the slider by one step.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Self
function Slider:increment()
    local ui = self:UI()
    if ui then
        ui:performAction("AXIncrement")
    end
    return self
end

--- cp.ui.Slider:decrement() -> self
--- Method
--- Decrements the slider by one step.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Self
function Slider:decrement()
    local ui = self:UI()
    if ui then
        ui:performAction("AXDecrement")
    end
    return self
end

-- cp.ui.xxx:__call([parent], value) -> self, boolean
-- Method
-- Allows the slider to be called like a function, to set the value.
--
-- Parameters:
--  * parent - (optional) The parent object.
--  * value - The value you want to set the slider to.
--
-- Returns:
--  * None
function Slider:__call(parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:value(value)
end

--- cp.ui.Slider:saveLayout() -> table
--- Method
--- Saves the current Slider layout to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the current Slider Layout.
function Slider:saveLayout()
    local layout = {}
    layout.value = self:getValue()
    return layout
end

--- cp.ui.Slider:loadLayout(layout) -> none
--- Method
--- Loads a Slider layout.
---
--- Parameters:
---  * layout - A table containing the Slider layout settings - created using [saveLayout](#saveLayout].
---
--- Returns:
---  * None
function Slider:loadLayout(layout)
    if layout then
        self:setValue(layout.value)
    end
end

return Slider
