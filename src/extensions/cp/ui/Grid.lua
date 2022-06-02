--- === cp.ui.Grid ===
---
--- An `AXGrid` UI element. It typically represents multiple items of the same type,
--- arranged into a grid of some number of columns and rows.
---
--- These are accessible via an [ElementRepeater](cp.ui.has.ElementRepeater.md) at the [children](cp.ui.HasRepeatingChildren.md#children) property,
--- and an indication of how it's split up via the [rowCount](cp.ui.Grid.md#rowCount) property.
---
--- Extends: [cp.ui.Element](cp.ui.Element.md)
--- Includes:
---  * [HasRepeatingChildren](cp.ui.HasRepeatingChildren.md)

local require                   = require

-- local log                       = require "hs.logger".new "Grid"

local ax                        = require "cp.fn.ax"
local Element                   = require "cp.ui.Element"
local HasRepeatingChildren      = require "cp.ui.HasRepeatingChildren"

local Grid = Element:subclass("cp.ui.Grid")
                    :include(HasRepeatingChildren)
                    :defineBuilder("containing")

--- === cp.ui.Grid.Builder ===
---
--- Builder for [Grid](cp.ui.Grid.md).
---
--- Extends [Builder](cp.ui.Builder.md).

--- cp.ui.Grid.Builder:containing(childrenHandler) -> cp.ui.Builder
--- Method
--- Sets the `Element` type for the `children` property.
---
--- Parameters:
---  * childrenHandler - The `Element` type to use for the `children` property.
---
--- Returns:
---  * The `Builder` instance.

--- cp.ui.Grid:containing(childrenHandler) -> cp.ui.Builder
--- Function
--- Sets the `Element` type for the `children` property.
---
--- Parameters:
---  * childrenHandler - The `Element` type to use for the `children` property.
---
--- Returns:
---  * The `Builder` instance.

--- cp.ui.Grid.matches(element) -> boolean
--- Function
--- Checks if the `element` is a `Grid`.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * A boolean
Grid.static.matches = ax.matchesIf(Element.matches, ax.hasRole "AXGrid")

function Grid:initialize(parent, uiFinder, childrenHandler)
    Element.initialize(self, parent, uiFinder)
    self:childrenHandler(childrenHandler)
end

--- cp.ui.Grid.rowCount <cp.prop: number; read-only; live>
--- Field
--- The number of rows in the grid.
function Grid.lazy.prop:rowCount()
    return ax.prop(self.UI, "AXRowCount")
end

return Grid