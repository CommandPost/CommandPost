--- === cp.apple.finalcutpro.cmd.KeyDetail ===
---
--- This class provides a UI for displaying the details of a key when it is selected on the keyboard layout.

local require = require

-- local log                   = require "hs.logger".new "KeyDetail"

local fn                    = require "cp.fn"
local ax                    = require "cp.fn.ax"
local Cell                  = require "cp.ui.Cell"
local Group                 = require "cp.ui.Group"
local Image                 = require "cp.ui.Image"
local StaticText            = require "cp.ui.StaticText"
local ScrollArea            = require "cp.ui.ScrollArea"
local Table                 = require "cp.ui.Table"
local TextField             = require "cp.ui.TextField"

local chain                 = fn.chain
local hasExactly            = fn.table.hasExactly

local KeyDetail = Group:subclass("cp.apple.finalcutpro.cmd.KeyDetail")

--- cp.apple.finalcutpro.cmd.KeyDetail.matches(element) -> boolean
--- Function
--- Checks if the element matches the criteria for this class.
---
--- Parameters:
---  * element - The element to check.
---
--- Returns:
---  * `true` if the element matches, `false` otherwise.
KeyDetail.static.matches = ax.matchesIf(
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
            -- ... and the second is an Image...
            Image.matches,
            -- ... and the third is a ScrollArea...
            ScrollArea.matches
        )
)

--- cp.apple.finalcutpro.cmd.KeyDetail.contentGroupUI <cp.prop: axuielement>
--- Field
--- The [axuielement](cp.prop.axuielement) for the content Group.
function KeyDetail.lazy.prop:contentGroupUI()
    return self.UI:mutate(ax.childMatching(Group.matches))
end

--- cp.apple.finalcutpro.cmd.KeyDetail.label <cp.ui.StaticText>
--- Field
--- The `StaticText` that displays the label.
function KeyDetail.lazy.value:label()
    return StaticText(self, self.contentGroupUI:mutate(
        ax.childMatching(StaticText.matches)
    ))
end

--- cp.apple.finalcutpro.cmd.KeyDetail.key <cp.ui.Image>
--- Field
--- The `Image` that displays the key.
function KeyDetail.lazy.value:key()
    return Image(self, self.contentGroupUI:mutate(
        ax.childMatching(Image.matches)
    ))
end

--- cp.apple.finalcutpro.cmd.KeyDetail.detail <cp.ui.ScrollArea>
--- Field
--- The `ScrollArea` that displays the detail.
function KeyDetail.lazy.value:detail()
    return ScrollArea(self,
        self.contentGroupUI:mutate(ax.childMatching(ScrollArea.matches)),
        Table:withRowsOf(Cell:with(TextField), Cell:with(TextField))
    )
end

--- cp.apple.finalcutpro.cmd.KeyDetail.contents <cp.ui.OldTable>
--- Field
--- The `Table` that displays the contents.
function KeyDetail.lazy.value:contents()
    return self.detail.contents
end

return KeyDetail