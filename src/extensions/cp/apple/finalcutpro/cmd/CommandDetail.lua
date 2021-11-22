--- === cp.apple.finalcutpro.cmd.CommandDetail ===
---
--- This class provides a UI for displaying the details of a command when it is selected on the `CommandList`.

local require = require

-- local log                   = require "hs.logger".new "CommandDetail"

local fn                    = require "cp.fn"
local ax                    = require "cp.fn.ax"
local Group                 = require "cp.ui.Group"
local StaticText            = require "cp.ui.StaticText"
local ScrollArea            = require "cp.ui.ScrollArea"
local TextArea              = require "cp.ui.TextArea"

local chain                 = fn.chain
local hasExactly            = fn.table.hasExactly

local CommandDetail = Group:subclass("cp.apple.finalcutpro.cmd.CommandDetail")

--- cp.apple.finalcutpro.cmd.CommandDetail.matches(element) -> boolean
--- Function
--- Checks if the element matches the criteria for this class.
---
--- Parameters:
---  * element - The element to check.
---
--- Returns:
---  * `true` if the element matches, `false` otherwise.
CommandDetail.static.matches = ax.matchesIf(
    -- It's a Group
    Group.matches,
    -- ...with exactly one child...
    hasExactly(1),
    -- ...which is a Group...
    chain // ax.childMatching(Group.matches) >>
    -- ...and that group has exactly three children...
        ax.children >> fn.table.sort(ax.topDown) >>
        fn.table.matchesExactItems(
            -- ... and the first is a StaticText...
            StaticText.matches,
            -- ... and the second is a ScrollArea...
            ScrollArea.matches
        )
)

-- cp.apple.finalcutpro.cmd.CommandDetail._contentGroupUI <cp.prop: axuielement>
-- Field
-- The [axuielement](cp.prop.axuielement) for the content Group.
function CommandDetail.lazy.prop:_contentGroupUI()
    return self.UI:mutate(ax.childMatching(Group.matches))
end

--- cp.apple.finalcutpro.cmd.CommandDetail.label <cp.ui.StaticText>
--- Field
--- The StaticText that displays the label.
function CommandDetail.lazy.value:label()
    return StaticText(self, self._contentGroupUI:mutate(
        ax.childMatching(StaticText.matches, 1)
    ))
end

--- cp.apple.finalcutpro.cmd.CommandDetail.detail <cp.ui.ScrollArea>
--- Field
--- The ScrollArea that displays the contained [TextArea].
function CommandDetail.lazy.value:detail()
    return ScrollArea(self,
        self._contentGroupUI:mutate(ax.childMatching(ScrollArea.matches, 1)),
        TextArea
    )
end

--- cp.apple.finalcutpro.cmd.CommandDetail.contents <cp.ui.TextArea>
--- Field
--- The TextArea that displays the content.
function CommandDetail.lazy.value:contents()
    return self.detail.contents
end

return CommandDetail