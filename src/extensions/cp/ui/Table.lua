--- === cp.ui.Table ===
---
--- A Table UI element. It extends [GridElement](cp.ui.GridElement.md), so will inherit all of its properties and methods.

local require = require

-- local log                                   = require "hs.logger".new "Table"

local ax                                    = require "cp.fn.ax"
-- local Column                                = require "cp.ui.Column"
local GridElement                           = require "cp.ui.GridElement"

local Table = GridElement:subclass("cp.ui.Table")

--- cp.ui.Table.matches(element) -> boolean
--- Function
--- Checks if the `element` is a `Table`.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * A boolean
Table.static.matches = ax.matchesIf(GridElement.matches, ax.hasRole "AXTable")

-- cp.ui.Table(parent, uiFinder, factory) -> cp.ui.Table
-- Constructor
-- Creates a new `Table` instance.
--
-- Parameters:
--  * parent - The parent `Element` instance.
--  * uiFinder - A `hs.uielement` or `axuielementObject` that will be used to find this element.
--  * factory - A row/cell factory.
--
-- Returns:
--  * A new `Table` instance.
function Table:initialize(parent, uiFinder, factory)
    GridElement.initialize(self, parent, uiFinder, factory)
end

return Table