--- === cp.ui.Popover ===
---
--- UI Group.

local require           = require

local Element           = require "cp.ui.Element"
local If                = require "cp.rx.go.If"

local Popover = Element:subclass("cp.ui.Popover")

--- cp.ui.Popover.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function Popover.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXPopover"
end

--- cp.ui.Popover(parent, uiFinder) -> Popover
--- Constructor
--- Creates a new `Popover` instance.
---
--- Parameters:
---  * parent - The parent object.
---  * uiFinder - A function which will return the `hs.axuielement` when available.
---
--- Returns:
---  * A new `Popover` object.

--- cp.ui.Popover:hide() -> Popover
--- Method
--- Hides a popover.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Self
function Popover:hide()
    local ui = self:UI()
    if ui then
        ui:performAction("AXCancel")
    end
    return self
end

--- cp.ui.Popover:doHide() -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` which will hide the popover.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`.
function Popover.lazy.method:doHide()
    return If(self.isShowing)
    :Then(self:doPerformAction("AXCancel"))
    :Otherwise(false)
    :Label("Popover:doHide")
end

return Popover