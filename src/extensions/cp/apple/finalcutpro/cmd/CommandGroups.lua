--- === cp.apple.finalcutpro.cmd.CommandGroups ===
---
--- Represents the list of Command Groups in the [CommandList](cp.apple.finalcutpro.cmd.CommandList.md).

local require                       = require

-- local log                           = require "hs.logger".new "CommandGroups"

local fn                            = require "cp.fn"
local ax                            = require "cp.fn.ax"

local ScrollArea                    = require "cp.ui.ScrollArea"

local CommandGroups = ScrollArea:subclass("cp.apple.finalcutpro.cmd.CommandGroups")

--- cp.apple.finalcutpro.cmd.CommandGroups.matches(element) -> boolean
--- Function
--- Checks if the element is a Command Groups element.
---
--- Parameters:
---  * element - The element to check.
---
--- Returns:
---  * `true` if the element matches, `false` otherwise.
CommandGroups.static.matches = ax.matchesIf(ScrollArea.matches)

return CommandGroups