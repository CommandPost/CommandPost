--- === cp.ui.Button ===
---
--- The `Button` type extends [Element](cp.ui.Element.md) and includes all its
--- methods, fields and other properties.

local require       = require

local axutils       = require("cp.ui.axutils")
local Element       = require("cp.ui.Element")
local go            = require("cp.rx.go")

local If            = go.If

local Button = Element:subclass("cp.ui.Button")

--- cp.ui.Button.matches(element) -> boolean
--- Function
--- Checks if the `element` is a `Button`, returning `true` if so.
---
--- Parameters:
---  * element		- The `hs._asm.axuielement` to check.
---
--- Returns:
---  * `true` if the `element` is a `Button`, or `false` if not.
function Button.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXButton"
end

--- cp.ui.Button(parent, uiFinder) -> cp.ui.Button
--- Constructor
--- Creates a new `Button` instance.
---
--- Parameters:
---  * parent		- The parent object. Should have a `UI` and `isShowing` field.
---  * uiFinder		- A function which will return the `hs._asm.axuielement` the button belongs to, or `nil` if not available.
---
--- Returns:
--- The new `Button` instance.
function Button:initialize(parent, uiFinder)
    Element.initialize(self, parent, uiFinder)
end

--- cp.ui.Button.title <cp.prop: string; read-only>
--- Field
--- The button title, if available.
function Button.lazy.prop:title()
    return axutils.prop(self.UI, "AXTitle")
end

--- cp.ui.Button:press() -> self, boolean
--- Method
--- Performs a button press action, if the button is available.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Button` instance.
---  * `true` if the button was actually pressed successfully.
function Button:press()
    local success = false
    local ui = self:UI()
    if ui then success = ui:doPress() == true end
    return self, success
end

--- cp.ui.Button:doPress() -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` that will press the button when executed, if available at the time.
--- If not an `error` is sent.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` which will press the button when executed.
function Button.lazy.method:doPress()
    return If(self.UI):Then(function(ui)
        ui:doPress()
        return true
    end)
    :Otherwise(false)
    :ThenYield()
    :Label("Button:doPress")
end

-- cp.ui.Button:__call() -> self, boolean
-- Method
-- Allows the button to be called like a function which will trigger a `press`.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The `Button` instance.
--  * `true` if the button was actually pressed successfully.
function Button:__call()
    return self:press()
end

function Button:__tostring()
    return string.format("cp.ui.Button: %q (parent: %s)", self:title(), self:parent())
end

return Button
