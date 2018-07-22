--- === cp.ui.Alert ===
---
--- Alert UI Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                           = require("hs.logger").new("alert")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                       = require("cp.ui.axutils")
local Button                        = require("cp.ui.Button")
local prop                          = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Alert = {}

--- cp.ui.Alert.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function Alert.matches(element)
    if element then
        return element:attributeValue("AXRole") == "AXSheet"
    end
    return false
end

--- cp.ui.Alert.new(app) -> Alert
--- Constructor
--- Creates a new `Alert` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `Browser` object.
function Alert.new(parent)
    return prop.extend({_parent = parent}, Alert)
end

--- cp.ui.Alert:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function Alert:parent()
    return self._parent
end

--- cp.ui.Alert:app() -> App
--- Method
--- Returns the app instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Alert:app()
    return self:parent():app()
end

--- cp.ui.Alert:UI() -> axuielementObject
--- Method
--- Returns the UI object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * An axuielementObject object.
function Alert:UI()
    return axutils.cache(self, "_ui", function()
        return axutils.childMatching(self:parent():UI(), Alert.matches)
    end,
    Alert.matches)
end

--- cp.ui.Alert.isShowing <cp.prop: boolean>
--- Variable
--- Is the alert showing?
Alert.isShowing = prop(
    function(self)
        return self:UI() ~= nil
    end
):bind(Alert)

--- cp.ui.Alert:hide() -> none
--- Method
--- Hides the alert by pressing the "Cancel" button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function Alert:hide()
    self:pressCancel()
end

--- cp.ui.Alert:cancel() -> Button
--- Method
--- Gets the Cancel button object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Button` object.
function Alert:cancel()
    if not self._cancel then
        self._cancel = Button.new(self, function()
            local ui = self:UI()
            return ui and ui:cancelButton()
        end)
    end
    return self._cancel
end

--- cp.ui.Alert:default() -> Button
--- Method
--- Gets the default button object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Button` object.
function Alert:default()
    if not self._default then
        self._default = Button.new(self, function()
            local ui = self:UI()
            return ui and ui:defaultButton()
        end)
    end
    return self._default
end

--- cp.ui.Alert:pressCancel() -> self, boolean
--- Method
--- Presses the Cancel button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Alert` object.
---  * `true` if successful, otherwise `false`.
function Alert:pressCancel()
    local _, success = self:cancel():press()
    return self, success
end

--- cp.ui.Alert:pressDefault() -> self, boolean
--- Method
--- Presses the Default button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Alert` object.
---  * `true` if successful, otherwise `false`.
function Alert:pressDefault()
    local _, success = self:default():press()
    return self, success
end

--- cp.ui.Alert:containsText(value[, plain]) -> boolean
--- Method
--- Checks if there are any child text elements containing the exact text or pattern, from beginning to end.
---
--- Parameters:
---  * textPattern   - The text pattern to check.
---  * plain         - If `true`, the text will be compared exactly, otherwise it will be considered to be a pattern. Defaults to `false`.
---
--- Returns:
---  * `true` if an element's `AXValue` matches the text pattern exactly.
function Alert:containsText(value, plain)
    local textUI = axutils.childMatching(self:UI(), function(element)
        local eValue = element:attributeValue("AXValue")
        if type(eValue) == "string" then
            if plain then
                return eValue == value
            else
                local s,e = eValue:find(value)
                return s == 1 and e == eValue:len()
            end
        end
        return false
    end)
    return textUI ~= nil
end

--- cp.ui.Alert.title <cp.prop: string>
--- Variable
--- Gets the title of the alert.
Alert.title = prop(
    function(self)
        local ui = self:UI()
        return ui and ui:attributeValue("AXTitle")
    end
):bind(Alert)

return Alert
