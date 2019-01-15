--- === cp.ui.Outline ===
---
--- Represents an `AXOutline` `axuielement`.

-- local log                       = require "hs.logger" .new "Outline"

local Grid	                    = require "cp.ui.Grid"

local Outline = Grid:subclass("cp.ui.Outline")

--- cp.ui.Outline.matches(element) -> boolean
--- Function
--- Checks if the `element` is an `Outline`.
function Outline.static.matches(element)
    return Grid.matches(element) and element:attributeValue("AXRole") == "AXOutline"
end

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

return Outline