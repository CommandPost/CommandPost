--- === cp.ui.Group ===
---
--- Represents an `AXGroup` element. Typically contains several specific child elements in a prectable order.
---
--- For example, if you have group containing a [StaticText](cp.ui.StaticText.md) then a [Button](cp.ui.Button.md),
--- then you can define it like so:
---
--- ```lua
--- local Group         = require "cp.ui.Group"
--- local StaticText    = require "cp.ui.StaticText"
--- local Button        = require "cp.ui.Button"
--- local has           = require "cp.ui.has"
---
--- local MyGroup = Group:subclass("MyGroup")
--- function MyGroup:initialize(parent, uiFinder)
---   Group.initialize(self, parent, uiFinder, has.list {
---       StaticText, Button
---   })
--- end
--- ```
---
--- The above will create a `Group` with two children, a `StaticText` and a `Button`, which can be accessed via the `children[1]`
--- and `children[2]` properties, respectively. You could also choose to expose them more explicitly like so:
---
--- ```lua
--- function MyGroup.lazy.value:label() -- return `StaticText`
---   return self.children[1]
--- end
---
--- function MyGroup.lazy.value:activate() -- return `Button`
---   return self.children[2]
--- end
--- ```
---
--- Alternately, if you don't need to create a full subclass, you can use the `:containing(...)` class function to create a
--- `Group` with the specified children:
---
--- ```lua
--- local Group = require "cp.ui.Group"
--- local StaticText = require "cp.ui.StaticText"
--- local Button = require "cp.ui.Button"
---
--- return Group:containing(StaticText, Button) -- a `Group.Builder`, not a `Group`
--- ```
---
--- This is most useful in situations where it is embedded in a [ScrollArea](cp.ui.ScrollArea.md) or [SplitGroup](cp.ui.SplitGroup.md),
--- or similar, where it can be passed into that parent's `:containing(...)` method. For example:
---
--- ```lua
--- local ScrollArea = require "cp.ui.ScrollArea"
--- local Group = require "cp.ui.Group"
--- local StaticText = require "cp.ui.StaticText"
--- local Button = require "cp.ui.Button"
---
--- return ScrollArea:containing(
---     Group:containing(StaticText, Button)
--- )
--- ```
---
--- Extends: [cp.ui.Element](cp.ui.Element.md)
---
--- Includes:
--- * [HasExactChildren](cp.ui.HasExactChildren.md)

local require           = require

-- local log               = require "hs.logger" .new "Group"

local ax                = require "cp.fn.ax"
local Element           = require "cp.ui.Element"
local HasExactChildren  = require "cp.ui.HasExactChildren"

local Group = Element:subclass("cp.ui.Group")
    :include(HasExactChildren)
    :defineBuilder("containing")
    :delegateTo("children")

--- === cp.ui.Group.Builder ===
---
--- Defines a `Group` [Builder](cp.ui.Builder.md).

--- cp.ui.Group.Builder:containing(...) -> cp.ui.Group.Builder
--- Method
--- Defines the provided [Element](cp.ui.Element.md) initializers as the elements in `contents`.
---
--- Parameters:
---  * ... - The [Element](cp.ui.Element.md) initializers to use.
---
--- Returns:
---  * The `Builder` instance.

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
Group.static.matches = ax.matchesIf(
    Element.matches,
    ax.hasRole "AXGroup"
)

--- cp.ui.Group(parent, uiFinder, [childrenHandler]) -> cp.ui.Group
--- Constructor
--- Creates a new `Group` instance.
---
--- Parameters:
---  * parent - The parent `Element` instance.
---  * uiFinder - The `axuielementObject` to use for the `Group`.
---  * childrenHandler - An optional function to use to handle the children.
---
--- Returns:
---  * The new `Group` instance.
---
--- Notes:
---  * The `children` property will be populated with the provided `Element` initializers, in the provided order.
---  * If the `Group` is provided insufficient child initializers, it will default to `Element` for any missing children.
function Group:initialize(parent, uiFinder, childrenHandler)
    Element.initialize(self, parent, uiFinder)
    self:childrenHandler(childrenHandler)
end

return Group
