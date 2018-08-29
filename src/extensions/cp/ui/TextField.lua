--- === cp.ui.TextField ===
---
--- Text Field Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log							= require("hs.logger").new("textField")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")
local Element                       = require("cp.ui.Element")
local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TextField = Element:subtype()

--- cp.ui.TextField.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function TextField.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXTextField"
end

--- cp.ui.TextField.new(parent, uiFinder[, convertFn]) -> TextField
--- Method
--- Creates a new TextField. They have a parent and a finder function.
--- Additionally, an optional `convert` function can be provided, with the following signature:
---
--- `function(textValue) -> anything`
---
--- The `value` will be passed to the function before being returned, if present. All values
--- passed into `value(x)` will be converted to a `string` first via `tostring`.
---
--- For example, to have the value be converted into a `number`, simply use `tonumber` like this:
---
--- ```lua
--- local numberField = TextField.new(parent, function() return ... end, tonumber)
--- ```
---
--- Parameters:
---  * parent	- The parent object.
---  * uiFinder	- The function will return the `axuielement` for the TextField.
---  * convertFn	- (optional) If provided, will be passed the `string` value when returning.
---
--- Returns:
---  * The new `TextField`.
function TextField.new(parent, uiFinder, convertFn)
    local o = Element.new(parent, uiFinder, TextField)
    o._convert = convertFn

    prop.bind(o) {
--- cp.ui.TextField.value <cp.prop: string>
--- Field
--- The current value of the text field.
        value = prop(
            function(self)
                local ui = self:UI()
                local value = ui and ui:attributeValue("AXValue") or nil
                if value and self._convert then
                    value = self._convert(value)
                end
                return value
            end,
            function(value, self)
                local ui = self:UI()
                if ui then
                    value = tostring(value)
                    local focused = ui:attributeValue("AXFocused")
                    ui:setAttributeValue("AXFocused", true)
                    ui:setAttributeValue("AXValue", value)
                    ui:setAttributeValue("AXFocused", focused)
                    ui:performAction("AXConfirm")
                end

            end
        ),
    }

    return o
end

--- cp.ui.TextField:getValue() -> string
--- Method
--- Gets the value of the Text Field.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The value of the Text Field as a string.
function TextField:getValue()
    return self:value()
end

--- cp.ui.TextField:setValue(value) -> self
--- Method
--- Sets the value of the Text Field.
---
--- Parameters:
---  * value - The value you want to set the Text Field to as a string.
---
--- Returns:
---  * Self
function TextField:setValue(value)
    self.value:set(value)
    return self
end

--- cp.ui.TextField:clear() -> self
--- Method
--- Clears the value of a Text Field.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Self
function TextField:clear()
    self.value:set("")
    return self
end

--- cp.ui.TextField:saveLayout() -> table
--- Method
--- Saves the current Text Field layout to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the current Text Field Layout.
function TextField:saveLayout()
    local layout = {}
    layout.value = self:getValue()
    return layout
end

--- cp.ui.TextField:loadLayout(layout) -> none
--- Method
--- Loads a Text Field layout.
---
--- Parameters:
---  * layout - A table containing the Text Field layout settings - created using `cp.ui.TextField:saveLayout()`.
---
--- Returns:
---  * None
function TextField:loadLayout(layout)
    if layout then
        self:setValue(layout.value)
    end
end

-- cp.ui.TextField:__call(parent, value) -> self, boolean
-- Method
-- Allows the Text Field instance to be called as a function/method which will get/set the value.
--
-- Parameters:
--  * parent - (optional) The parent object.
--  * value - The value you want to set the Text Field to.
--
-- Returns:
--  * The value of the Static Text box.
function TextField.__call(self, parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:value(value)
end

return TextField
