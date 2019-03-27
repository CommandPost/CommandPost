--- === cp.ui.Group ===
---
--- UI Group.

local require   = require

-- local log       = require "hs.logger" .new "Group"

local Element   = require "cp.ui.Element"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Group = Element:subclass("cp.ui.Group")

--- cp.ui.Group.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function Group.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXGroup"
end

--- cp.ui.Group.contents(element) -> axuielement
--- Function
--- Returns the `AXContents` of the element, if it is an `AXGroup`.
---
--- Parameters:
---  * element  - The `axuielement` to check.
---
--- Returns:
---  * The list of `axuielements` for the `AXContents` of the `AXGroup`, or `nil`.
function Group.static.contents(element)
    return Group.matches(element) and element:attributeValue("AXContents")
end

--- cp.ui.Group(parent, uiFinder[, contentsClass]) -> Alert
--- Constructor
--- Creates a new `Group` instance.
---
--- Parameters:
---  * parent - The parent object.
---  * uiFinder - A function which will return the `hs._asm.axuielement` when available.
---
--- Returns:
---  * A new `Group` object.
function Group:initialize(parent, uiFinder)
    Element.initialize(self, parent, uiFinder)
end

return Group
