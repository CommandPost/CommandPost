--- === cp.ui.HasRepeatingChildren ===
---
--- A mixin for [Element](cp.ui.Element.md) classes that have `children` of a particular
--- type which repeat multiple times.
---
--- The mixin can be applied to a subclass by calling `:include(cp.ui.HasRepeatingChildren)`:
---
--- ```lua
--- local MyElement = Element:subclass("MyElement"):include(cp.ui.HasRepeatingChildren)
--- ```
---
--- The `childrenUI` property is used to get the table of `hs.axuielement` values for the `Element`.
--- The `children` property is used to get the [ElementRepeater](cp.ui.has.ElementRepeater.md) for the `Element`'s children.
---
--- By default, the `children` property will contain [Element](cp.ui.Element.md) instances. This
--- can be changed by setting the `childType` property:
---
--- ```lua
--- local MyElement = Element:subclass("MyElement"):include(cp.ui.HasRepeatingChildren)
---
--- function MyElement:initialize(parent, uiFinder)
---    Element.initialize(self, parent, uiFinder)
---    self:childrenHandler(cp.ui.has.zeroOrMore(MyChildElement))
--- end
---
--- See also:
--- * [HasExactChildren](cp.ui.HasExactChildren.md)

local require                       = require

local fn                            = require "cp.fn"
local ax                            = require "cp.fn.ax"
local Element                       = require "cp.ui.Element"
local has                           = require "cp.ui.has"

local chain                         = fn.chain

local zeroOrMore, handler           = has.zeroOrMore, has.handler

local HasRepeatingChildren = Element:extension("cp.ui.HasRepeatingChildren")

local DEFAULT_HANDLER = zeroOrMore(Element)

local CHILDREN_HANDLER = {}

--- cp.ui.HasRepeatingChildren:childrenHandler(childrenHandler) -> nil
--- Method
--- Sets the [UIHandler](cp.ui.has.UIHandler.md) for the `Element` being extended
---
--- Parameters:
---  * childrenHandler - The [UIHandler](cp.ui.has.UIHandler.md) to use.
---
--- Returns:
---  * `nil`
function HasRepeatingChildren:childrenHandler(childrenHandler)
    childrenHandler = childrenHandler and handler(childrenHandler) or DEFAULT_HANDLER
    self[CHILDREN_HANDLER] = childrenHandler
end

--- cp.ui.HasRepeatingChildren:childHandler(childHandler) -> nil
--- Method
--- Sets the [UIHandler](cp.ui.has.UIHandler.md) for individual child `Element`.
--- This `Element` will allow zero or more of the specified child handler to match.
---
--- Parameters:
---  * childHandler - The [UIHandler](cp.ui.has.UIHandler.md) to use.
---
--- Returns:
---  * `nil`
function HasRepeatingChildren:childHandler(childHandler)
    childHandler = childHandler and handler(childHandler or Element)
    self:childrenHandler(zeroOrMore(childHandler))
end


--- cp.ui.HasRepeatingChildren.childrenUI <cp.prop: table of hs.axuielement>
--- Field
--- The children UI elements.
function HasRepeatingChildren.lazy.prop:childrenUI()
    return ax.prop(self.UI, "AXChildren")
end

--- cp.ui.HasRepeatingChildren.children <cp.ui.ElementRepeater: cp.ui.Element>
--- Field
--- Provides access to the [Elements](cp.ui.Element.md) of this `Element`'s children.
function HasRepeatingChildren.lazy.value:children()
    return self[CHILDREN_HANDLER]:build(self, self.childrenUI)
end

--- cp.ui.HasRepeatingChildren.childrenInTopDownOrderUI <cp.prop: table of hs.axuielement>
--- Field
--- The children UI elements in top-down order.
---
--- Notes:
---  * This may be expensive on [Elements](cp.ui.Element.md) that have many children.
function HasRepeatingChildren.lazy.prop:childrenInTopDownOrderUI()
    return self:watchFor(
        {"AXCreated", "AXUIElementDestroyed", "AXLiveRegionChanged"},
        self.childrenUI:mutate(
            chain // ax.children >> fn.table.sort(ax.topDown)
        ):cached(),
        0.01
    )
end

--- cp.ui.HasRepeatingChildren.childrenInTopDownOrder <cp.ui.ElementRepeater: cp.ui.Element>
--- Field
--- Provides access to the [Elements](cp.ui.Element.md) of this `Element`'s children in top-down order.
---
--- Notes:
---  * This may be expensive on [Elements](cp.ui.Element.md) that have many children.
function HasRepeatingChildren.lazy.value:childrenInTopDownOrder()
    return self[CHILDREN_HANDLER]:build(self, self.childrenInTopDownOrderUI)
end

--- cp.ui.HasRepeatingChildren.childrenInNavigationOrderUI <cp.prop: table of axuielement>
--- Field
--- The children UI elements in navigation order.
function HasRepeatingChildren.lazy.prop:childrenInNavigationOrderUI()
    return ax.prop(self.UI, "AXChildrenInNavigationOrder")
end

--- cp.ui.HasRepeatingChildren.childrenInNavigationOrder <cp.ui.ElementRepeater: cp.ui.Element>
--- Field
--- The child [Elements](cp.ui.Element.md) of this `HasRepeatingChildren` in navigation order.
--- This will return an element for any number requested from `1` or above,
--- even if there is not currently a child at that index. It will always be
--- linked to the `childrenInNavigationOrderUI` at that index.
function HasRepeatingChildren.lazy.value:childrenInNavigationOrder()
    return self[CHILDREN_HANDLER]:build(self, self.childrenInNavigationOrderUI)
end

--- cp.ui.HasRepeatingChildren.visibleChildrenUI <cp.prop: table of axuielement>
--- Field
--- The visible children UI elements.
function HasRepeatingChildren.lazy.prop:visibleChildrenUI()
    return ax.prop(self.UI, "AXVisibleChildren")
end

--- cp.ui.HasRepeatingChildren.visibleChildren <cp.ui.ElementRepeater: cp.ui.Element>
--- Field
--- The visible child [Elements](cp.ui.Element.md) of this `HasRepeatingChildren`.
--- This will return an element for any number requested from `1` or above,
--- even if there is not currently a child at that index. It will always be
--- linked to the `visibleChildrenUI` at that index.
function HasRepeatingChildren.lazy.value:visibleChildren()
    return self[CHILDREN_HANDLER]:build(self, self.visibleChildrenUI)
end

return HasRepeatingChildren