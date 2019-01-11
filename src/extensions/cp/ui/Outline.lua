--- === cp.ui.Outline ===
---
--- Represents an `AXOutline` `axuielement`.

local axutils	                = require "cp.ui.axutils"
local Element	                = require "cp.ui.Element"

local Outline = Element:subclass("cp.ui.Outline")

--- cp.ui.Outline(parent, uiFinder) -> cp.ui.Outline
--- Constructor
--- Creates a new `Outline` with the specified `parent` and `uiFinder`.
---
--- Parameters:
--- * parent - The parent instance.
--- * uiFinder - A `function` or a `cp.prop` which will return the `AXOutline` `axuielement`.
---
--- Returns:
--- * The new `Outline` instance.

--- cp.ui.Outline.matches(element) -> boolean
--- Function
--- Checks if the `element` is an `Outline`.
function Outline.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXOutline"
end

function Outline:childrenUI()
    axutils.prop(self.UI, "AXChildren")
end

return Outline