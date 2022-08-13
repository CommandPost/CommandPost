--- === cp.apple.finalcutpro.cmd.Commands ===
---
--- The list of available commands (depending on search and/or [CommandGroup](cp.apple.finalcutpro.cmd.CommandGroups.md])
--- that can be mapped to a keyboard shortcut.

local require                   = require

--- local log                      = require "hs.logger".new "Commands"

local fn                        = require "cp.fn"
local ax                        = require "cp.fn.ax"

local chain                     = fn.chain

local Button                    = require "cp.ui.Button"
local Group                     = require "cp.ui.Group"
local Row                       = require "cp.ui.Row"
local ScrollArea                = require "cp.ui.ScrollArea"
local Table                     = require "cp.ui.Table"
local TextField                 = require "cp.ui.TextField"

local Commands = ScrollArea:subclass("cp.apple.finalcutpro.cmd.Commands")

--- cp.apple.finalcutpro.cmd.Commands.matches(element) -> boolean
--- Function
--- Checks if the element matches the criteria for this class.
---
--- Parameters:
--- * element - An `axuielementObject` to check.
---
--- Returns:
--- * `true` if the element matches the criteria for this class.
Commands.static.matches = ax.matchesIf(ScrollArea.matches, chain // ax.childMatching(Table.matches))

function Commands:initialize(parent, uiFinder)
    ScrollArea.initialize(
        self, parent, uiFinder,
        Table:withHeaderOf(
            -- Example of using a basic cp.ui.Group:
            -- Group:containing(Button, Button, Button)
            -- Using the custom `Commands.Header`
            Commands.Header
        ):withRowsOf(
            -- Example of using cp.ui.Row:
            -- Row:containing(TextField, TextField, TextField)
            -- Using the custom `Commands.Row`
            Commands.Row
        )
    )
end

--- === cp.apple.finalcutpro.cmd.Commands.Header ===
---
--- The header of the Commands.

Commands.Header = Group:subclass("cp.apple.finalcutpro.cmd.Commands.Header")

function Commands.Header:initialize(parent, uiFinder)
    Group.initialize(self, parent, uiFinder, Button, Button, Button)
end

--- cp.apple.finalcutpro.cmd.Commands.Header.command <cp.ui.Button>
--- Field
--- The `Button` that can be pressed to sort by "Command". Pressing more than
--- once will alternate between ascending and descending.
function Commands.Header.lazy.value:command()
    return self.children[1]
end

--- cp.apple.finalcutpro.cmd.Commands.Header.modifiers <cp.ui.Button>
--- Field
--- The `Button` that can be pressed to sort by "Modifiers". Pressing more than
--- once will alternate between ascending and descending.
function Commands.Header.lazy.value:modifiers()
    return self.children[2]
end

--- cp.apple.finalcutpro.cmd.Commands.Header.key <cp.ui.Button>
--- Field
--- The `Button` that can be pressed to sort by "Key". Pressing more than
--- once will alternate between ascending and descending.
function Commands.Header.lazy.value:key()
    return self.children[3]
end

--- === cp.apple.finalcutpro.cmd.Commands.Row ===

Commands.Row = Row:subclass("cp.apple.finalcutpro.cmd.Commands.Row")

function Commands.Row:initialize(parent, uiFinder)
    Row.initialize(self, parent, uiFinder, TextField, TextField, TextField)
end

--- cp.apple.finalcutpro.cmd.Commands.Row.command <cp.ui.TextField>
--- Field
--- The command [TextField](cp.ui.TextField.md) (read-only).
function Commands.Row.lazy.value:command()
    return self.children[1]
end

--- cp.apple.finalcutpro.cmd.Commands.Row.modifiers <cp.ui.TextField>
--- Field
--- The modifiers [TextField](cp.ui.TextField.md) (read-only)
function Commands.Row.lazy.value:modifiers()
    return self.children[2]
end

--- cp.apple.finalcutpro.cmd.Commands.Row.key <cp.ui.TextField>
--- Field
--- The key [TextField](cp.ui.TextField.md) (read-only).
function Commands.Row.lazy.value:key()
    return self.children[3]
end


return Commands