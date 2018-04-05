--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.Slider ===
---
--- Slider Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Slider = {}

-- TODO: Add documentation
function Slider.matches(element)
    return element ~= nil and element:attributeValue("AXRole") == "AXSlider"
end

--- cp.ui.Slider.new(parent, finderFn) -> cp.ui.Slider
--- Constructor
--- Creates a new Slider
---
--- Parameters:
--- * parent		- The parent object. Should have an `isShowing` property.
--- * finderFn		- The function which returns an `hs._asm.axuielement` for the slider, or `nil`.
---
--- Returns:
--- * A new `Slider` instance.
function Slider.new(parent, finderFn)
    local o = prop.extend({_parent = parent, _finder = finderFn}, Slider)

    -- TODO: Add documentation
    local UI = prop(function(self)
        return axutils.cache(self, "_ui", function()
            return self._finder()
        end,
        Slider.matches)
    end)

    prop.bind(o) {
        UI = UI,

        isShowing = parent.isShowing:AND(UI),

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

        -- TODO: Add documentation
        minValue = UI:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue("AXMinValue")
        end),

        -- TODO: Add documentation
        maxValue = UI:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue("AXMaxValue")
        end),
    }

    return o
end

-- TODO: Add documentation
function Slider:parent()
    return self._parent
end

function Slider:app()
    return self:parent():app()
end

-- TODO: Add documentation
function Slider:getValue()
    return self:value()
end

-- TODO: Add documentation
function Slider:setValue(value)
    self.value:set(value)
    return self
end

-- TODO: Add documentation
function Slider:shiftValue(value)
    local currentValue = self:value()
    self.value:set(currentValue - value)
    return self
end

-- TODO: Add documentation
function Slider:getMinValue()
    return self:minValue()
end

-- TODO: Add documentation
function Slider:getMaxValue()
    return self:maxValue()
end

-- TODO: Add documentation
function Slider:increment()
    local ui = self:UI()
    if ui then
        ui:doIncrement()
    end
    return self
end

-- TODO: Add documentation
function Slider:decrement()
    local ui = self:UI()
    if ui then
        ui:doDecrement()
    end
    return self
end

-- TODO: Add documentation
function Slider:isEnabled()
    local ui = self:UI()
    return ui and ui:enabled()
end

function Slider:__call(parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:value(value)
end

-- TODO: Add documentation
function Slider:saveLayout()
    local layout = {}
    layout.value = self:getValue()
    return layout
end

-- TODO: Add documentation
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
--- * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
--- * The `hs.image` that was created, or `nil` if the UI is not available.
function Slider:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return Slider