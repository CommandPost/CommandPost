--- === cp.apple.finalcutpro.cmd.CommandDetail ===
---
--- This class provides a UI for displaying the details of a command when it is selected on the `CommandList`.

local require = require

-- local log                                   = require "hs.logger".new "CommandDetail"

local fn                                    = require "cp.fn"
local ax                                    = require "cp.fn.ax"
local Group                                 = require "cp.ui.Group"
local StaticText                            = require "cp.ui.StaticText"
local ScrollArea                            = require "cp.ui.ScrollArea"
local TextArea                              = require "cp.ui.TextArea"
local has                                   = require "cp.ui.has"

local chain                                 = fn.chain
local matchesExactItems                     = fn.table.matchesExactItems
local list, alias                           = has.list, has.alias

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
    -- ...with exactly one child
    chain // ax.children >> matchesExactItems(
        fn.all(
            -- It's a Group
            Group.matches,
            -- ...containing exactly...
            chain // ax.childrenTopDown >> matchesExactItems(
                -- ... a StaticText...
                StaticText.matches,
                -- ... and a ScrollArea...
                ScrollArea.matches
            )
        )
    )
)

--- cp.apple.finalcutpro.cmd.CommandDetail.children <cp.ui.has.UIHandler>
--- Constant
--- UI Handler for the children of this class.
CommandDetail.static.children = list {
    Group:containing {
        alias "label" { StaticText },
        alias "detail" { ScrollArea:containing(TextArea) }
    }
}

--- cp.apple.finalcutpro.cmd.CommandDetail(parent, uiFinder) -> cp.apple.finalcutpro.cmd.CommandDetail
--- Constructor
--- Creates a new CommandDetail.
---
--- Parameters:
---  * parent - The parent object.
---  * uiFinder - The uiFinder object.
---
--- Returns:
---  * The new CommandDetail object.
function CommandDetail:initialize(parent, uiFinder)
    Group.initialize(self, parent, uiFinder, CommandDetail.children)
end

--- cp.apple.finalcutpro.cmd.CommandDetail.label <cp.ui.StaticText>
--- Field
--- The StaticText that displays the label.
function CommandDetail.lazy.value:label()
    return self.children[1].label
end

--- cp.apple.finalcutpro.cmd.CommandDetail.detail <cp.ui.ScrollArea>
--- Field
--- The [ScrollArea](cp.ui.ScrollArea.md) that displays the contained [TextArea](cp.ui.TextArea.md).
function CommandDetail.lazy.value:detail()
    return self.children[1].detail
end

--- cp.apple.finalcutpro.cmd.CommandDetail.contents <cp.ui.TextArea>
--- Field
--- The TextArea that displays the content.
function CommandDetail.lazy.value:contents()
    return self.detail.contents
end

return CommandDetail