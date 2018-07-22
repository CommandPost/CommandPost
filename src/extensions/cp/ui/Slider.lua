--- === cp.ui.Slider ===
---
--- Slider Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require
local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Slider = {}

--- cp.ui.Slider.matches(element) -> boolean
--- Function
--- Checks if the provided `hs._asm.axuielement` is a Slider.
---
--- Parameters:
---  * element		- The `axuielement` to check.
---
--- Returns:
---  * `true` if it's a match, or `false` if not.
function Slider.matches(element)
    return element ~= nil and element:attributeValue("AXRole") == "AXSlider"
end

--- cp.ui.Slider.new(parent, finderFn) -> cp.ui.Slider
--- Constructor
--- Creates a new Slider
---
--- Parameters:
---  * parent		- The parent object. Should have an `isShowing` property.
---  * finderFn		- The function which returns an `hs._asm.axuielement` for the slider, or `nil`.
---
--- Returns:
---  * A new `Slider` instance.
function Slider.new(parent, finderFn)
    local o = prop.extend({_parent = parent, _finder = finderFn}, Slider)

    local UI = prop(function(self)
        return axutils.cache(self, "_ui", function()
            return self._finder()
        end,
        Slider.matches)
    end)

    prop.bind(o) {

        --- cp.ui.Slider:UI() -> hs._asm.axuielement | nil
        --- Method
        --- Returns the `axuielement` representing the Slider, or `nil` if not available.
        ---
        --- Parameters:
        ---  * None
        ---
        --- Return:
        ---  * The `axuielement` or `nil`.
        UI = UI,

        --- cp.ui.Slider.isShowing <cp.prop: boolean; read-only>
        --- Field
        --- If `true`, it is visible on screen.
        isShowing = parent.isShowing:AND(UI),

        --- cp.ui.Slider.value <cp.prop: number>
        --- Field
        --- Sets or gets the value of the slider.
        value = UI:mutate(
            function(original)
                local ui = original()
                return ui and ui:attributeValue("AXValue")
            end,
            function(value, original)
                local ui = original()
                if ui then
                    ui:setAttributeValue("AXValue", value)
                end
            end
        ),

        --- cp.ui.Slider.minValue <cp.prop: number; read-only>
        --- Field
        --- Gets the minimum value of the slider.
        minValue = UI:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue("AXMinValue")
        end),

        --- cp.ui.Slider.maxValue <cp.prop: number; read-only>
        --- Field
        --- Gets the maximum value of the slider.
        maxValue = UI:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue("AXMaxValue")
        end),
    }

    return o
end

--- cp.ui.Slider:parent() -> table
--- Method
--- The parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object.
function Slider:parent()
    return self._parent
end

--- cp.ui.Slider:app() -> App
--- Method
--- Returns the app instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Slider:app()
    return self:parent():app()
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
        ui:doIncrement()
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
        ui:doDecrement()
    end
    return self
end

--- cp.ui.Slider:isEnabled() -> boolean
--- Method
--- Is the slider enabled?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if enabled, otherwise `false`.
function Slider:isEnabled()
    local ui = self:UI()
    return ui and ui:enabled()
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
---  * layout - A table containing the Slider layout settings - created using `cp.ui.Slider:saveLayout()`.
---
--- Returns:
---  * None
function Slider:loadLayout(layout)
    if layout then
        self:setValue(layout.value)
    end
end

--- cp.ui.Slider:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the UI in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
---  * path	- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
---  * The `hs.image` that was created, or `nil` if the UI is not available.
function Slider:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return Slider
