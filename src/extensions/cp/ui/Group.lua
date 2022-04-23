--- === cp.ui.Group ===
---
--- UI Group.

local require           = require

-- local log               = require "hs.logger" .new "Group"

local ax                = require "cp.fn.ax"
local Element           = require "cp.ui.Element"

local pack              = table.pack

local Group = Element:subclass("cp.ui.Group")
    :defineBuilder("containing")

--- === cp.ui.Group.Builder ===
---
--- Defines a `Group` builder.

--- cp.ui.Group:containing(...) -> cp.ui.Group.Builder
--- Function
--- Returns a `Builder` with the `Element` initializers for the children in the group.
---
--- Parameters:
---  * ... - A variable list of `Element` initializers, one for each child.
---
--- Returns:
---  * The `Group.Builder`

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

--- cp.ui.Group(parent, uiFinder[, contentsClass]) -> Alert
--- Constructor
--- Creates a new `Group` instance.
---
--- Parameters:
---  * parent - The parent object.
---  * uiFinder - A function which will return the `hs.axuielement` when available.
---
--- Returns:
---  * A new `Group` object.
function Group:initialize(parent, uiFinder, ...)
    Element.initialize(self, parent, uiFinder)
    self.childInits = pack(...)
end

--- cp.ui.Group.childrenUI <cp.prop: table of axuielement>
--- Field
--- Contains the list of `axuielement` children of the group.
function Group.lazy.prop:childrenUI()
    return ax.prop(self.UI, "AXChildren")
end

--- cp.ui.Group.children <table of cp.ui.Element>
--- Field
--- Contains the list of `Element` children of the group.
function Group.lazy.value:children()
    return ax.initElements(self, self.childrenUI, self.childInits)
end

return Group
