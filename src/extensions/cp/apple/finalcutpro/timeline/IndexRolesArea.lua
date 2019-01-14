--- === cp.apple.finalcutpro.timeline.IndexRolesArea ===
---
--- Represents the list of Roles in the [IndexRoles](cp.apple.finalcutpro.timeline.IndexRoles.md).

-- local log	                    = require "hs.logger" .new "IndexRolesArea"

local axutils	                = require "cp.ui.axutils"
local ScrollArea	            = require "cp.ui.ScrollArea"
local IndexRolesList         = require "cp.apple.finalcutpro.timeline.IndexRolesList"

local childMatching	            = axutils.childMatching

local IndexRolesArea = ScrollArea:subclass("cp.apple.finalcutpro.timeline.IndexRolesArea")

--- cp.apple.finalcutpro.timeline.IndexRolesArea.matches(element) -> boolean
--- Function
--- Checks if the `element` matches an `IndexRolesArea`.
---
--- Parameters:
--- * element	- The `axuielement` to check.
---
--- Returns:
--- * `true` if it matches, otherwise `false`.
function IndexRolesArea.static.matches(element)
    if ScrollArea.matches(element) then
        local contents = element:attributeValue("AXContents")
        return #contents == 1 and IndexRolesList.matches(contents[1])
    end
    return false
end

--- cp.apple.finalcutpro.timeline.IndexRolesArea:list() -> cp.ui.Outline
--- Method
--- The [Outline](cp.ui.Outline.md) that serves as the list of the scroll area.
function IndexRolesArea.lazy.method:list()
    return IndexRolesList(self, self.UI:mutate(function(original)
        return childMatching(original(), IndexRolesList.matches)
    end))
end

function IndexRolesArea:saveLayout()
    local layout = ScrollArea.saveLayout(self)

    layout.list = self:list():saveLayout()

    return layout
end

function IndexRolesArea:loadLayout(layout)
    layout = layout or {}
    ScrollArea.loadLayout(self, layout)
    self:list():loadLayout(layout.list)
end

return IndexRolesArea