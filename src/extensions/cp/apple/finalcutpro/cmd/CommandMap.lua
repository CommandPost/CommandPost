--- === cp.apple.finalcutpro.cmd.CommandMap ===
---
--- The list of available commands (depending on search and/or [CommandGroup](cp.apple.finalcutpro.cmd.CommandGroups.md])
--- that can be mapped to a keyboard shortcut.

local require                   = require

--- local log                      = require "hs.logger".new "CommandMap"

local fn                        = require "cp.fn"
local ax                        = require "cp.fn.ax"

local ScrollArea                = require "cp.ui.ScrollArea"

local CommandMap = ScrollArea:subclass("cp.apple.finalcutpro.cmd.CommandMap")

--- cp.apple.finalcutpro.cmd.CommandMap.matches(element) -> boolean
--- Function
--- Checks if the element matches the criteria for this class.
---
--- Parameters:
--- * element - An `axuielementObject` to check.
---
--- Returns:
--- * `true` if the element matches the criteria for this class.
CommandMap.static.matches = ax.matchesIf(ScrollArea.matches)

return CommandMap