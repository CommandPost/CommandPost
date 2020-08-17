--- === cp.ui.List ===
---
--- Represents an `AXList` `axuielement` value.
---
--- Extends [Element](cp.ui.Element.md).

local axutils           = require "cp.ui.axutils"
local Element           = require "cp.ui.Element"

local insert            = table.insert

local List = Element:subclass("cp.ui.List")

--- cp.ui.List.matches(element)
--- Function
--- Checks if the provided `axuielement` is an `AXList`.
---
--- Parameters:
---  * element  - The `axuielement` to check.
---
--- Returns:
--- * `true` if it is an `AXList`, otherwise `false`.
function List.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXList"
end

--- cp.ui.List(parent, uiFinder, itemAdaptorFn)
--- Constructor
--- Creates a new List.
---
--- Parameters:
---  * parent       - The parent table. Should have a `isShowing` property.
---  * uiFinder      - The `function` or `cp.prop` that provides the current `hs._asm.axuielement`.
---
--- Returns:
---  * The new `List` instance.
function List:initialize(parent, uiFinder, itemAdaptorFn)
    if type(itemAdaptorFn) ~= "function" then
        error("The itemAdaptor must be a function")
    end

    Element.initialize(self, parent, uiFinder)
    self._itemAdaptorFn = itemAdaptorFn
end

function List.lazy.prop:childrenUI()
    return axutils.prop(self.UI, "AXChildren")
end

--- cp.ui.List:items() -> table of values
--- Method
--- Returns the children as items, as adapted by the `itemAdaptor` in the constructor
function List:items()
    local items = {}
    local childrenUI = self:childrenUI()

    if childrenUI then
        for _,child in ipairs(childrenUI) do
            local item = self._itemAdaptorFn(self, child)
            insert(items, item)
        end
    end

    return items
end

return List