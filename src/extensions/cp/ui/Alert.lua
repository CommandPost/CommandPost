--- === cp.ui.Alert ===
---
--- Alert UI Module.

local require = require

local axutils                       = require("cp.ui.axutils")
local Element                       = require("cp.ui.Element")
local Button                        = require("cp.ui.Button")

local If                            = require("cp.rx.go.If")
local WaitUntil                     = require("cp.rx.go.WaitUntil")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Alert = Element:subclass("cp.ui.Alert")

--- cp.ui.Alert.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function Alert.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXSheet"
end

--- cp.ui.Alert:new(app) -> Alert
--- Constructor
--- Creates a new `Alert` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `Browser` object.
function Alert:initialize(parent)
    local UI = parent.UI:mutate(function(original)
        return axutils.childMatching(original(), Alert.matches)
    end)

    Element.initialize(self, parent, UI)
end

--- cp.ui.Alert.title <cp.prop: string>
--- Field
--- Gets the title of the alert.
function Alert.lazy.prop:title()
    return axutils.prop(self.UI, "AXTitle")
end

--- cp.ui.Alert.default <cp.ui.Button>
--- Field
--- The default [Button](cp.ui.Button.md) for the `Alert`.
function Alert.lazy.value:default()
    return Button(self, axutils.prop(self.UI, "AXDefaultButton"))
end

--- cp.ui.Alert.cancel <cp.ui.Button>
--- Field
--- The cancel [Button](cp.ui.Button.md) for the `Alert`.
function Alert.lazy.value:cancel()
    return Button(self, axutils.prop(self.UI, "AXCancelButton"))
end

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

--- cp.ui.Alert:doHide() -> cp.rx.go.Statement <boolean>
--- Method
--- Attempts to hide the Alert (if visible) by pressing the [Cancel](#cancel) button.
---
--- Parameters:
--- * None
---
--- Returns:
--- * A [Statement](cp.rx.go.Statement.md) to execute, resolving to `true` if the button was present and clicked, otherwise `false`.
function Alert.lazy.method:doHide()
    return If(self.isShowing):Then(
        self:doCancel()
    ):Then(WaitUntil(self.isShowing():NOT()))
    :Otherwise(true)
    :TimeoutAfter(10000)
    :Label("Alert:doHide")
end

--- cp.ui.Alert:doCancel() -> cp.rx.go.Statement <boolean>
--- Method
--- Attempts to hide the Alert (if visible) by pressing the [Cancel](#cancel) button.
---
--- Parameters:
--- * None
---
--- Returns:
--- * A [Statement](cp.rx.go.Statement.md) to execute, resolving to `true` if the button was present and clicked, otherwise `false`.
function Alert.lazy.method:doCancel()
    return self.cancel:doPress()
end

--- cp.ui.Alert:doDefault() -> cp.rx.go.Statement <boolean>
--- Method
--- Attempts to press the `default` [Button](cp.ui.Button.md).
---
--- Parameters:
--- * None
---
--- Returns:
--- * A [Statement](cp.rx.go.Statement.md) to execute, resolving to `true` if the button was present and clicked, otherwise `false`.
function Alert.lazy.method:doDefault()
    return self.default:doPress()
end

--- cp.ui.Alert:doPress(buttonFromLeft) -> cp.rx.go.Statement <boolean>
--- Method
--- Attempts to press the indicated button from left-to-right, if it can be found.
---
--- Parameters:
--- * buttonFromLeft    - The number of the button from left-to-right.
---
--- Returns:
--- * a [Statement](cp.rx.go.Statement.md) to execute, resolving in `true` if the button was found and pressed, otherwise `false`.
function Alert:doPress(buttonFromLeft)
    return If(self.UI):Then(function(ui)
        local button = axutils.childFromLeft(ui, 1, Button.matches)
        if button then
            button:doPress()
        end
    end)
    :Otherwise(false)
    :ThenYield()
    :Label("Alert:doPress("..tostring(buttonFromLeft)..")")
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
                --log.df("Found: start: %s, end: %s, len: %s", s, e, eValue:len())
                return s == 1 and e == eValue:len()
            end
        end
        return false
    end)
    return textUI ~= nil
end

return Alert
