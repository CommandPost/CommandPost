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
local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TextField = {}

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
    return element ~= nil and element:attributeValue("AXRole") == "AXTextField"
end

--- cp.ui.TextField.new(parent, finderFn[, convertFn]) -> TextField
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
---  * finderFn	- The function will return the `axuielement` for the TextField.
---  * convertFn	- (optional) If provided, will be passed the `string` value when returning.
---
--- Returns:
---  * The new `TextField`.
function TextField.new(parent, finderFn, convertFn)
    return prop.extend({
        _parent = parent,
        _finder = finderFn,
        _convert = convertFn,
    }, TextField)
end

--- cp.ui.TextField:parent() -> table
--- Method
--- The parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object.
function TextField:parent()
    return self._parent
end

--- cp.ui.TextField:UI() -> hs._asm.axuielement | nil
--- Method
--- Returns the `axuielement` representing the `TextField`, or `nil` if not available.
---
--- Parameters:
---  * None
---
--- Return:
---  * The `axuielement` or `nil`.
function TextField:UI()
    return axutils.cache(self, "_ui", function()
        local ui = self._finder()
        return TextField.matches(ui) and ui or nil
    end,
    TextField.matches)
end

--- cp.ui.TextField.isShowing <cp.prop: boolean>
--- Variable
--- Is the Text Field showing?
function TextField:isShowing()
    return self:UI() ~= nil and self:parent():isShowing()
end

--- cp.ui.TextField.value <cp.prop: string>
--- Field
--- The current value of the text field.
TextField.value = prop(
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
):bind(TextField)

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

--- cp.ui.TextField:isEnabled() -> boolean
--- Method
--- Is the Text Field enabled?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if enabled, otherwise `false`.
function TextField:isEnabled()
    local ui = self:UI()
    return ui and ui:enabled()
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

--- cp.ui.TextField:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the UI in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
---  * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
---  * The `hs.image` that was created, or `nil` if the UI is not available.
function TextField:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return TextField
