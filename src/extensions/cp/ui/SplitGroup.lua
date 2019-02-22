--- === cp.ui.SplitGroup ===
---
--- Split Group UI.

local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fnutils	        = require("hs.fnutils")
local axutils	        = require("cp.ui.axutils")
local Element           = require("cp.ui.Element")
local Splitter	        = require("cp.ui.Splitter")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local SplitGroup = Element:subclass("cp.ui.SplitGroup")

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

--- cp.ui.SplitterGroup.splittersUI <cp.prop: table of axuielements; read-only>
--- Field
--- The list of `AXSplitter` `axuielement` items for the SplitGroup.
function SplitGroup.lazy.prop:splittersUI()
    return axutils.prop(self.UI, "AXSplitters")
end

--- cp.ui.SplitterGroup.splitters <cp.prop: table of cp.ui.Splitter; read-only>
--- Field
--- The list of [Splitter](cp.ui.Splitter.md) values for the group.
function SplitGroup.lazy.prop:splitters()
    return self.splittersUI:mutate(function(original)
        local uis = original()
        return uis and fnutils.map(uis, function(ui) return Splitter(self, ui) end)
    end)
end

return SplitGroup
