--- === cp.apple.finalcutpro.cmd.CommandList ===
---
--- A list of commands available in the [CommandEditor](cp.apple.finalcutpro.cmd.CommandEditor.md).
---
--- Extends: [cp.ui.Element](cp.ui.Element.md)
--- Delegates To: [contents](#contents)

local require = require

-- local log                                   = require "hs.logger".new "CommandList"

local fn                                    = require "cp.fn"
local ax                                    = require "cp.fn.ax"
local Group                                 = require "cp.ui.Group"
local SplitGroup                            = require "cp.ui.SplitGroup"
local StaticText                            = require "cp.ui.StaticText"
local has                                   = require "cp.ui.has"

local CommandGroups                         = require "cp.apple.finalcutpro.cmd.CommandGroups"
local Commands                              = require "cp.apple.finalcutpro.cmd.Commands"

local chain                                 = fn.chain
local matchesExactItems                     = fn.table.matchesExactItems

local list, alias                           = has.list, has.alias

local CommandList = Group:subclass("cp.apple.finalcutpro.cmd.CommandList")
                        :delegateTo("contents")

-- NOTE: Strings in the Command Editor are only found in the following .nib:
-- <Final Cut Pro.app>/Contents/Frameworks/LunaKit.framework/Resources/en.lproj/LKCommandCustomizationAquaCongruency.nib

--- cp.apple.finalcutpro.cmd.CommandList.matches(element) -> boolean
--- Function
--- Checks if the element matches the CommandList.
---
--- Parameters:
---  * element - The element to check.
---
--- Returns:
---  * `true` if the element matches, `false` otherwise.
CommandList.static.matches = ax.matchesIf(
    -- It's a Group
    Group.matches,
    -- it has a StaticText followed by a ScrollArea.
    chain // ax.childrenTopDown >> matchesExactItems(
        StaticText.matches, SplitGroup.matches
    )
)

CommandList.static.children = list {
    alias "label" { StaticText },
    alias "contents" {
        SplitGroup:with(
            alias "groups" { CommandGroups },
            alias "commands" { Commands }
        )
    },
}

--- cp.apple.finalcutpro.cmd.CommandList(parent, uiFinder) -> CommandList
--- Constructor
--- Creates a new `CommandList` instance.
---
--- Parameters:
---  * parent - The parent object.
---  * uiFinder - A `axuielementObject` or `hs.uielement` to use when searching for the `CommandList`.
---
--- Returns:
---  * The new `CommandList` instance.
function CommandList:initialize(parent, uiFinder)
    Group.initialize(self, parent, uiFinder, CommandList.children)
end

--- cp.apple.finalcutpro.cmd.CommandList.label <cp.ui.StaticText>
--- Field
--- The StaticText that displays the label.

--- cp.apple.finalcutpro.cmd.CommandList.groups <cp.apple.finalcutpro.cmd.CommandGroups>
--- Field
--- The [CommandGroups](cp.apple.finalcutpro.cmd.CommandGroups.md) for this CommandList.

--- cp.apple.finalcutpro.cmd.CommandList.commands <cp.apple.finalcutpro.cmd.Commands>
--- Field
--- The [Commands](cp.apple.finalcutpro.cmd.Commands.md) for this CommandList.

--- cp.apple.finalcutpro.cmd.CommandList.splitter <cp.ui.Splitter>
--- Field
--- The [Splitter](cp.ui.Splitter.md) for this CommandList.
function CommandList.lazy.value:splitter()
    return self.splitters[1]
end

return CommandList