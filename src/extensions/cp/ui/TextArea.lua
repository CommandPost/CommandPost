--- === cp.ui.TextArea ===
---
--- UI Text Area.

local require = require

local Element = require("cp.ui.Element")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

--- cp.ui.TextArea(parent, uiFinder) -> TextArea
--- Constructor
--- Creates a new `TextArea` instance.
---
--- Parameters:
---  * parent - The parent object.
---  * uiFinder - A function which will return the `hs._asm.axuielement` when available.
---
--- Returns:
---  * A new `TextArea` object.
local TextArea = Element:subclass("cp.ui.TextArea")

--- cp.ui.TextArea.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function TextArea.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXTextArea"
end

return TextArea