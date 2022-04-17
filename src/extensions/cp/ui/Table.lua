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

return Table