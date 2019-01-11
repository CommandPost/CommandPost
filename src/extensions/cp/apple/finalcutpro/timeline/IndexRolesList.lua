--- === cp.apple.finalcutpro.timeline.IndexRolesList ===
---
--- Represents the list of Roles in the [IndexRoles](cp.apple.finalcutpro.timeline.IndexRoles.md).

local log	                    = require "hs.logger" .new "IndexRolesList"

local axutils	                = require "cp.ui.axutils"
local ScrollArea	            = require "cp.ui.ScrollArea"
local Outline	                = require "cp.ui.Outline"

local IndexRolesList = ScrollArea:subclass("cp.apple.finalcutpro.timeline.IndexRolesList")

--- cp.apple.finalcutpro.timeline.IndexRolesList.matches(element) -> boolean
--- Function
--- Checks if the `element` matches an `IndexRolesList`.
---
--- Parameters:
--- * element	- The `axuielement` to check.
---
--- Returns:
--- * `true` if it matches, otherwise `false`.
function IndexRolesList.static.matches(element)
    if ScrollArea.matches(element) then
        local contents = element:attributeValue("AXContents")
        return #contents == 1 and Outline.matches(contents[1])
    end
    return false
end

--- cp.apple.finalcutpro.timeline.IndexRolesList:contents() -> cp.ui.Outline
--- Method
--- The [Outline](cp.ui.Outline.md) that serves as the contents of the scroll area.
function IndexRolesList.lazy.method:contents()
    return Outline(self, axutils.prop(self.UI, "AXContents"))
end

function IndexRolesList:saveLayout()
    local layout = ScrollArea.saveLayout(self)

    layout.contents = self:contents():saveLayout()

    return layout
end

function IndexRolesList:loadLayout(layout)
    log.df("IndexRolesList:loadLayout: called")
    layout = layout or {}
    ScrollArea.loadLayout(self, layout)
    self:contents():loadLayout(layout.contents)
end

return IndexRolesList