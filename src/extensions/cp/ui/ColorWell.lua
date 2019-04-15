--- === cp.ui.ColorWell ===
---
--- UI ColorWell.

local require = require

local Element = require("cp.ui.Element")



--- cp.ui.ColorWell(parent, uiFinder) -> Image
--- Constructor
--- Creates a new `ColorWell` instance.
---
--- Parameters:
---  * parent - The parent object.
---  * uiFinder - A function which will return the `hs._asm.axuielement` when available.
---
--- Returns:
---  * A new `ColorWell` object.
local ColorWell = Element:subclass("cp.ui.ColorWell")

--- cp.ui.ColorWell.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function ColorWell.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXColorWell"
end

return ColorWell