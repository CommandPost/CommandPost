--- === cp.ui.Image ===
---
--- UI Image.

local require = require

local Element = require("cp.ui.Element")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

--- cp.ui.Group(parent, uiFinder) -> Image
--- Constructor
--- Creates a new `Image` instance.
---
--- Parameters:
---  * parent - The parent object.
---  * uiFinder - A function which will return the `hs._asm.axuielement` when available.
---
--- Returns:
---  * A new `Image` object.
local Image = Element:subclass("cp.ui.Image")

--- cp.ui.Image.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function Image.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXImage"
end

return Image