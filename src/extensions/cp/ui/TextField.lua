--- === cp.ui.TextField ===
---
--- Text Field Module.

local require = require

-- local log                       = require "hs.logger" .new "TextField"

local go                        = require "cp.rx.go"
local Element                   = require "cp.ui.Element"

local If                        = go.If

local TextField = Element:subclass("cp.ui.TextField")
    :defineBuilder("convertingGet", "convertingSet")

-----------------------------------------------------------------------
-- TextField.Builder definitions.
-----------------------------------------------------------------------

--- === cp.ui.TextField.Builder ===
---
--- Defines a `TextField` [Builder](cp.ui.Builder.md).

--- cp.ui.TextField.Builder:convertingGet(getter) -> cp.ui.TextField.Builder
--- Method
--- Specifies a function that will convert the result of the `TextField:value()` getter to a different type.
---
--- Parameters:
---  * getter - A `function` that will be called to get the value from the `TextField`.
---
--- Returns:
---  * The `TextField.Builder`
---
--- Notes:
---  * The `getter` will be called with the `string` value from the `TextField` as its only parameter.

--- cp.ui.TextField.Builder:convertingSet(setter) -> cp.ui.TextField.Builder
--- Method
--- Specifies a function to convert the value before setting it in the `TextField`.
---
--- Parameters:
---  * setter - A `function` that will be called to set the value in the `TextField`.
---
--- Returns:
---  * The `TextField.Builder`
---
--- Notes:
---  * The `setter` will be called with the input value from a `TextField:value(...)` call as its only parameter.
---    It should return a `string` to be saved into the `TextField`.

--- cp.ui.TextField:convertingGet(getter) -> cp.ui.TextField.Builder
--- Field
--- Creates a `Builder` that will convert the result of the `TextField:value()` getter to a different type.
---
--- Parameters:
---  * getter - A `function` that will be called to get the value from the `TextField`.
---
--- Returns:
---  * The `TextField.Builder`
---
--- Notes:
---  * The `getter` will be called with the `string` value from the `TextField` as its only parameter.
---  * For example, `TextField:convertGet(tonumber)` will use the standard `tonumber` function to convert the value to a number.

--- cp.ui.TextField:convertingSet(setter) -> cp.ui.TextField.Builder
--- Field
--- Creates a `Builder` that will convert the value before setting it in the `TextField`.
---
--- Parameters:
---  * setter - A `function` that will be called to set the value in the `TextField`.
---
--- Returns:
---  * The `TextField.Builder`
---
--- Notes:
---  * The `setter` will be called with the input value from a `TextField:value(...)` call as its only parameter.
---    It should return a `string` to be saved into the `TextField`.
---  * For example, `TextField:convertSet(tostring)` will use the standard `tostring` function to convert the value to a string.

-----------------------------------------------------------------------
-- TextField definitions.
-----------------------------------------------------------------------

--- cp.ui.TextField.matches(element[, subrole]) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---  * subrole - (optional) If provided, the field must have the specified subrole.
---
--- Returns:
---  * `true` if matches otherwise `false`
function TextField.static.matches(element, subrole)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXTextField" and
        (subrole == nil or element:attributeValue("AXSubrole") == subrole)
end

--- cp.ui.TextField(parent, uiFinder[, convertFn]) -> TextField
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
--- local numberField = TextField(parent, function() return ... end, tonumber, tostring)
--- ```
---
--- Parameters:
---  * parent   - The parent object.
---  * uiFinder - The function will return the `axuielement` for the TextField.
---  * getConvertFn    - (optional) If provided, will be passed the `string` value when returning.
---  * setConvertFn    - (optional) If provided, will be passed the `number` value when setting.
---
--- Returns:
---  * The new `TextField`.
function TextField:initialize(parent, uiFinder, getConvertFn, setConvertFn)
    Element.initialize(self, parent, uiFinder)
    self._getConvertFn = getConvertFn
    self._setConvertFn = setConvertFn
end

--- cp.ui.TextField.value <cp.prop: string>
--- Field
--- The current value of the text field.
function TextField.lazy.prop:value()
    return self.UI:mutate(
        function(original)
            local ui = original()
            local value = ui and ui:attributeValue("AXValue") or nil
            if value and self._getConvertFn then
                value = self._getConvertFn(value)
            end
            return value
        end,
        function(value, original)
            local ui = original()
            if ui then
                local convert = self._setConvertFn or tostring
                value = convert(value)
                local focused
                if self._forceFocus then
                    focused = self:isFocused()
                    if not focused then
                        self:isFocused(true)
                    end
                end
                ui:setAttributeValue("AXValue", value)
                ui:performAction("AXConfirm")
            end
        end
    )
end

--- cp.ui.TextField:forceFocus()
--- Method
--- Configures the TextField to force a focus on the field before editing.
--- Some fields seem to require this to actually update the text value.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Self
function TextField:forceFocus()
    self._forceFocus = true
    return self
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

--- cp.ui.TextField:doConfirm() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will confirm the current text value.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A Statement
function TextField.lazy.method:doConfirm()
    return If(self.UI)
    :Then(function(ui)
        ui:performAction("AXConfirm")
        return true
    end)
    :Otherwise(false)
    :ThenYield()
end

--- cp.ui.TextField:doFocus() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to focus on the current `TextField`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A Statement
function TextField.lazy.method:doFocus()
    return If(self.isFocused):Is(false)
    :Then(function()
        self:isFocused(true)
        return true
    end)
    :Otherwise(false)
    :ThenYield()
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

function TextField.__call(self, parent, value)
    if parent and parent ~= self:parent() then
        value = parent
    end
    return self:value(value)
end

return TextField
