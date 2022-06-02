--- === cp.ui.HasExactChildren ===
---
--- A mixin for [Element](cp.ui.Element.md) classes that have a specific set of `children`, always in the same order.
---
--- The mixin can be applied to a subclass by calling `:include(cp.ui.HasExactChildren)`:
---
--- ```lua
--- local HasExactChildren = require "cp.ui.HasExactChildren"
--- local MyGroup = Group:subclass("MyGroup"):include(HasExactChildren)
---
--- function MyGroup:initialize(parent, uiFinder)
---   Group.initialize(self, parent, uiFinder)
---   self:childTypes(StaticText, TextField, Button)
--- end
--- ```

local require               = require

local fn                    = require "cp.fn"
local ax                    = require "cp.fn.ax"
local Element               = require "cp.ui.Element"
local has                   = require "cp.ui.has"

local chain, call           = fn.chain, fn.call
local sort                  = fn.table.sort

local HasExactChildren = Element:extension("cp.ui.HasExactChildren")

local CHILDREN_HANDLER = {}

local DEFAULT_HANDLER = has.zeroOrMore { Element }

--- cp.ui.HasExactChildren.defaultChildrenHandler <cp.ui.has.UIHandler>
--- Constant
--- The default handler for children (any number of [Element](cp.ui.Element.md) values).
HasExactChildren.static.defaultChildrenHandler = DEFAULT_HANDLER

--- cp.ui.HasExactChildren.children <cp.ui.has.UIHandler>
--- Constant
--- Defines the [UIHandler] that describes the children of the element.
--- By default, will map to any number of [Element](cp.ui.Element.md) objects.
--- 
function HasExactChildren:childrenHandler(handler)
    self[CHILDREN_HANDLER] = has.handler(handler or DEFAULT_HANDLER)
end

--- cp.ui.HasExactChildren.childrenUI <cp.prop: table of hs.axuielement>
--- Field
--- The children UI elements in [top-down](cp.fn.ax.md#topDown) order.
function HasExactChildren.lazy.prop:childrenUI()
    return ax.prop(self.UI, "AXChildren"):mutate(
        chain // call >> sort(ax.topDown)
    )
end

--- cp.ui.HasExactChildren.children <any>
--- Field
--- Provides access to the [Elements](cp.ui.Element.md) of this `Element`'s children.
function HasExactChildren.lazy.value:children()
    local handler = self[CHILDREN_HANDLER] or self.defaultChildrenHandler
    return handler:build(self, self.childrenUI)
end

return HasExactChildren