--- === cp.ui.Outline ===
---
--- A Outline UI element. It extends [GridElement](cp.ui.GridElement.md), so will inherit all of its properties and methods.
---
--- Extends: [cp.ui.GridElement](cp.ui.GridElement.md)

local require = require

-- local log                                   = require "hs.logger".new "Outline"

local ax                                    = require "cp.fn.ax"
local GridElement                           = require "cp.ui.GridElement"

local Outline = GridElement:subclass("cp.ui.Outline")

--- cp.ui.Outline.matches(element) -> boolean
--- Function
--- Checks if the `element` is an `Outline`.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * A boolean
Outline.static.matches = ax.matchesIf(GridElement.matches, ax.hasRole "AXOutline")

return Outline