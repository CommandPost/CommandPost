--- === cp.apple.finalcutpro.cmd.CommandList ===
---
--- A list of commands available in the [CommandEditor](cp.apple.finalcutpro.cmd.CommandEditor.md).

local require = require

-- local log                   = require "hs.logger".new "CommandList"

local ax                    = require "cp.fn.ax"
local Group                 = require "cp.ui.Group"
local ScrollArea            = require "cp.ui.ScrollArea"
local SplitGroup            = require "cp.ui.SplitGroup"
local Splitter              = require "cp.ui.Splitter"
local StaticText            = require "cp.ui.StaticText"

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
function CommandList.static.matches(element)
    if Group.matches(element) then
        local children = element.AXChildren
        return #children == 2
        and StaticText.matches(children[1])
        and SplitGroup.matches(children[2])
    end
    return false
end

--- cp.apple.finalcutpro.cmd.CommandList.label <cp.ui.StaticText>
--- Field
--- The StaticText that displays the label.
function CommandList.lazy.value:label()
    return StaticText(self, self.UI:mutate(
        ax.childMatching(StaticText.matches)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandList.commandsSplitGroup() -> cp.ui.SplitGroup
--- Field
--- The [SplitGroup](cp.ui.SplitGroup.md) containing the commands.
function CommandList.lazy.value:commandsSplitGroup()
    return SplitGroup(
        self,
        self.UI:mutate(ax.childMatching(SplitGroup.matches)),
        { ScrollArea, Splitter, ScrollArea }
    )
end

return CommandList