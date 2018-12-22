--- === cp.ui.SplitGroup ===
---
--- Split Group UI.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local Element           = require("cp.ui.Element")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local SplitGroup = Element:subclass("SplitGroup")

--- cp.ui.SplitGroup.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function SplitGroup.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXSplitGroup"
end

--- cp.ui.SplitGroup(parent, uiFinder) -> cp.ui.SplitGroup
--- Constructor
--- Creates a new Split Group.
---
--- Parameters:
---  * parent		- The parent object.
---  * uiFinder		- The `function` or `cp.prop` which returns an `hs._asm.axuielement` for the Split Group, or `nil`.
---
--- Returns:
---  * A new `SplitGroup` instance.
function SplitGroup:initialize(parent, uiFinder)
    Element.initialize(self, parent, uiFinder)
end

return SplitGroup
