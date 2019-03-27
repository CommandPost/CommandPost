--- === cp.ui.Image ===
---
--- Represents an `AXImage` `axuielement` value.
---
--- Extends [Element](cp.ui.Element.md).

local Element           = require "cp.ui.Element"

local Image = Element:subclass("cp.ui.Image")

--- cp.ui.Image.matches(element)
--- Function
--- Checks if the provided `axuielement` is an `AXImage`.
---
--- Parameters:
---  * element  - The `axuielement` to check.
---
--- Returns:
--- * `true` if it is an `AXImage`, otherwise `false`.
function Image.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXImage"
end

return Image