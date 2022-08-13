--- === cp.apple.finalcutpro.cmd.CommandGroups ===
---
--- Represents the list of Command Groups in the [CommandList](cp.apple.finalcutpro.cmd.CommandList.md).

local require                       = require

-- local log                           = require "hs.logger".new "CommandGroups"

local ax                            = require "cp.fn.ax"
local Button                        = require "cp.ui.Button"
local Group                         = require "cp.ui.Group"
local Outline                       = require "cp.ui.Outline"
local Row                           = require "cp.ui.Row"
local ScrollArea                    = require "cp.ui.ScrollArea"
local StaticText                    = require "cp.ui.StaticText"

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
CommandGroups.static.matches = ax.matchesIf(
    ScrollArea.matches,
    ax.childMatching(Outline.matches)
)

function CommandGroups:initialize(parent, uiFinder)
    ScrollArea.initialize(self, parent, uiFinder,
        Outline:withHeaderOf(
            Group:containing(Button)
        ):withRowsOf(
            Row:containing(StaticText)
        )
    )
end

return CommandGroups