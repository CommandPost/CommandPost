--- === cp.ui.Menu ===
---
--- UI Group.

local require = require

local Element = require("cp.ui.Element")



--- cp.ui.Menu(parent, uiFinder) -> Menu
--- Constructor
--- Creates a new `Menu` instance.
---
--- Parameters:
---  * parent - The parent object.
---  * uiFinder - A function which will return the `hs._asm.axuielement` when available.
---
--- Returns:
---  * A new `Menu` object.
local Menu = Element:subclass("cp.ui.Menu")

--- cp.ui.Menu.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function Menu.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXMenu"
end

--- cp.ui.Menu:close() -> self
--- Method
--- Closes a menu.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Self
function Menu:close()
    local ui = self:UI()
    if ui then
        ui:performAction("AXCancel")
    end
    return self
end

return Menu