--- === cp.apple.finalcutpro.cmd.CommandList ===
---
--- A list of commands available in the [CommandEditor](cp.apple.finalcutpro.cmd.CommandEditor.md).

local require = require

-- local log                                   = require "hs.logger".new "CommandList"

local fn                                    = require "cp.fn"
local ax                                    = require "cp.fn.ax"
local Group                                 = require "cp.ui.Group"
local SplitGroup                            = require "cp.ui.SplitGroup"
local Splitter                              = require "cp.ui.Splitter"
local StaticText                            = require "cp.ui.StaticText"

local CommandGroups                         = require "cp.apple.finalcutpro.cmd.CommandGroups"
local Commands                            = require "cp.apple.finalcutpro.cmd.Commands"

local chain                                 = fn.chain
local matchesExactItems                     = fn.table.matchesExactItems

local CommandList = Group:subclass("cp.apple.finalcutpro.cmd.CommandList")

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

--- cp.apple.finalcutpro.cmd.CommandList.label <cp.ui.StaticText>
--- Field
--- The StaticText that displays the label.
function CommandList.lazy.value:label()
    return StaticText(self, self.UI:mutate(
        ax.childMatching(StaticText.matches)
    ))
end

-- cp.apple.finalcutpro.cmd.CommandList._commandsSplitGroup() -> cp.ui.SplitGroup
-- Field
-- The [SplitGroup](cp.ui.SplitGroup.md) containing the commands.
function CommandList.lazy.value:_commandsSplitGroup()
    return SplitGroup(self, self.UI:mutate(ax.childMatching(SplitGroup.matches)), {
        CommandGroups, Splitter, Commands
    })
end

--- cp.apple.finalcutpro.cmd.CommandList.groups <cp.apple.finalcutpro.cmd.CommandGroups>
--- Field
--- The [CommandGroups](cp.apple.finalcutpro.cmd.CommandGroups.md) for this CommandList.
function CommandList.lazy.value:groups()
    return self._commandsSplitGroup.children[1]
end

--- cp.apple.finalcutpro.cmd.CommandList.splitter <cp.ui.Splitter>
--- Field
--- The [Splitter](cp.ui.Splitter.md) for this CommandList.
function CommandList.lazy.value:splitter()
    return self._commandsSplitGroup.children[2]
end

--- cp.apple.finalcutpro.cmd.CommandList.commands <cp.apple.finalcutpro.cmd.Commands>
--- Field
--- The [Commands](cp.apple.finalcutpro.cmd.Commands.md) for this CommandList.
function CommandList.lazy.value:commands()
    return self._commandsSplitGroup.children[3]
end

return CommandList