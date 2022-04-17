--- === cp.apple.finalcutpro.cmd.CommandMap ===
---
--- The list of available commands (depending on search and/or [CommandGroup](cp.apple.finalcutpro.cmd.CommandGroups.md])
--- that can be mapped to a keyboard shortcut.

local require                   = require

--- local log                      = require "hs.logger".new "CommandMap"

local fn                        = require "cp.fn"
local ax                        = require "cp.fn.ax"

local chain                     = fn.chain

local Button                    = require "cp.ui.Button"
local Group                     = require "cp.ui.Group"
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
        Table:withHeaderOf(
            -- Example of using a basic cp.ui.Group:
            -- Group:containing(Button, Button, Button)
            -- Using the custom `CommandMap.Header`
            CommandMap.Header
        ):withRowsOf(
            -- Example of using cp.ui.Row:
            -- Row:containing(TextField, TextField, TextField)
            -- Using the custom `CommandMap.Row`
            CommandMap.Row
        )
    )
end

--- cp.apple.finalcutpro.cmd.CommandMap.byCommand <cp.ui.Button>
--- Field
--- The `Button` that toggles sort order by "Command".
function CommandMap.lazy.value:byCommand()
    return self.contents.header.byCommand
end

--- cp.apple.finalcutpro.cmd.CommandMap.byModifiers <cp.ui.Button>
--- Field
--- The `Button` that toggles sort order by "Modifiers".
function CommandMap.lazy.value:byModifiers()
    return self.contents.header.byModifiers
end

--- cp.apple.finalcutpro.cmd.CommandMap.byKey <cp.ui.Button>
--- Field
--- The `Button` that toggles sort order by "Key".
function CommandMap.lazy.value:byKey()
    return self.contents.header.byKey
end

--- === cp.apple.finalcutpro.cmd.CommandMap.Header ===
---
--- The header of the CommandMap.

CommandMap.Header = Group:subclass("cp.apple.finalcutpro.cmd.CommandMap.Header")

function CommandMap.Header:initialize(parent, uiFinder)
    Group.initialize(self, parent, uiFinder, Button, Button, Button)
end

--- cp.apple.finalcutpro.cmd.CommandMap.Header.byCommand <cp.ui.Button>
--- Field
--- The `Button` that can be pressed to sort by command. Pressing more than
--- once will alternate between ascending and descending.
function CommandMap.Header.lazy.value:byCommand()
    return self.children[1]
end

--- cp.apple.finalcutpro.cmd.CommandMap.Header.byModifiers <cp.ui.Button>
--- Field
--- The `Button` that can be pressed to sort by modifiers. Pressing more than
--- once will alternate between ascending and descending.
function CommandMap.Header.lazy.value:byModifiers()
    return self.children[2]
end

--- cp.apple.finalcutpro.cmd.CommandMap.Header.byKey <cp.ui.Button>
--- Field
--- The `Button` that can be pressed to sort by key. Pressing more than
--- once will alternate between ascending and descending.
function CommandMap.Header.lazy.value:byKey()
    return self.children[3]
end

--- === cp.apple.finalcutpro.cmd.CommandMap.Row ===

CommandMap.Row = Row:subclass("cp.apple.finalcutpro.cmd.CommandMap.Row")

function CommandMap.Row:initialize(parent, uiFinder)
    Row.initialize(self, parent, uiFinder, TextField, TextField, TextField)
end

--- cp.apple.finalcutpro.cmd.CommandMap.Row.command <cp.ui.TextField>
--- Field
--- The command [TextField](cp.ui.TextField.md) (read-only).
function CommandMap.Row.lazy.value:command()
    return self.children[1]
end

--- cp.apple.finalcutpro.cmd.CommandMap.Row.modifiers <cp.ui.TextField>
--- Field
--- The modifiers [TextField](cp.ui.TextField.md) (read-only)
function CommandMap.Row.lazy.value:modifiers()
    return self.children[2]
end

--- cp.apple.finalcutpro.cmd.CommandMap.Row.key <cp.ui.TextField>
--- Field
--- The key [TextField](cp.ui.TextField.md) (read-only).
function CommandMap.Row.lazy.value:key()
    return self.children[3]
end


return CommandMap