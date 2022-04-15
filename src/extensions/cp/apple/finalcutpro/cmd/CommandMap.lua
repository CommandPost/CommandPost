--- === cp.apple.finalcutpro.cmd.CommandMap ===
---
--- The list of available commands (depending on search and/or [CommandGroup](cp.apple.finalcutpro.cmd.CommandGroups.md])
--- that can be mapped to a keyboard shortcut.

local require                   = require

--- local log                      = require "hs.logger".new "CommandMap"

local fn                        = require "cp.fn"
local ax                        = require "cp.fn.ax"

local chain                     = fn.chain

local Cell                      = require "cp.ui.Cell"
local Row                       = require "cp.ui.Row"
local ScrollArea                = require "cp.ui.ScrollArea"
local Table                     = require "cp.ui.Table"
local TextField                 = require "cp.ui.TextField"

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
CommandMap.static.matches = ax.matchesIf(ScrollArea.matches, chain // ax.childMatching(Table.matches))

function CommandMap:initialize(parent, uiFinder)
    ScrollArea.initialize(
        self, parent, uiFinder,
        Table:withRowsOf(TextField, TextField, TextField)
    )
end

--- === cp.apple.finalcutpro.cmd.CommandMap.Row ===

CommandMap.Row = Row:subclass("cp.apple.finalcutpro.cmd.CommandMap.Row")

function CommandMap.Row:initialize(parent, uiFinder)
    Row.initialize(self, parent, {TextField, TextField, TextField})
end

--- cp.apple.finalcutpro.cmd.CommandMap.Row.command <cp.ui.TextField>
--- Field
--- The command [TextField](cp.ui.TextField.md) (read-only).
function CommandMap.Row.lazy.value:command()
    return self.children[1]
end

--- cp.apple.finalcutpro.cmd.CommandMap.Row.modifiers <cp.ui.TextField>
--- Field
--- The modifiers [TextField](cp.ui.TextField.md).
function CommandMap.Row.lazy.value:modifiers()
    return self.children[2]
end

--- cp.apple.finalcutpro.cmd.CommandMap.Row.key <cp.ui.TextField>
--- Field
--- The key [TextField](cp.ui.TextField.md).
function CommandMap.Row.lazy.value:key()
    return self.children[3]
end


return CommandMap