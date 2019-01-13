-- local log	                    = require "hs.logger" .new "IndexRolesList"

local prop	                    = require "cp.prop"
local Outline	                = require "cp.ui.Outline"
local Row                       = require "cp.ui.Row"

local Role                      = require "cp.apple.finalcutpro.timeline.Role"
local AudioRole                 = require "cp.apple.finalcutpro.timeline.AudioRole"
local AudioSubrole	            = require "cp.apple.finalcutpro.timeline.AudioSubrole"
local CaptionsRole	            = require "cp.apple.finalcutpro.timeline.CaptionsRole"
local CaptionsSubrole	        = require "cp.apple.finalcutpro.timeline.CaptionsSubrole"
local VideoRole	                = require "cp.apple.finalcutpro.timeline.VideoRole"
local VideoSubrole	            = require "cp.apple.finalcutpro.timeline.VideoSubrole"

local IndexRolesList = Outline:subclass("cp.apple.finalcutpro.timeline.IndexRolesList")

-- cp.apple.finalcutpro.timeline.IndexRolesList:createRow(rowUI) -> cp.apple.finalcutpro.timeline.Role
-- Private Method
-- Returns Rows as a Role.
function IndexRolesList:createRow(rowUI)
    assert(rowUI:attributeValue("AXParent") == self:UI(), "The provided `rowUI` is not in this Outline.")
    local rowProp = prop.THIS(rowUI)

    if AudioRole.matches(rowUI) then
        return AudioRole(self, rowProp)
    elseif AudioSubrole.matches(rowUI) then
        return AudioSubrole(self, rowProp)
    elseif CaptionsRole.matches(rowUI) then
        return CaptionsRole(self, rowProp)
    elseif CaptionsSubrole.matches(rowUI) then
        return CaptionsSubrole(self, rowProp)
    elseif VideoRole.matches(rowUI) then
        return VideoRole(self, rowProp)
    elseif VideoSubrole.matches(rowUI) then
        return VideoSubrole(self, rowProp)
    elseif Role.matches(rowUI) then
        return Role(self, rowProp)
    end

    return Row(self, rowProp)
end

-- creates a filter function for Roles.
local function rolesFilter(includeSubroles, type)
    return function(e)
        return Role.is(e)
        and (includeSubroles == true or e:subroleRow() ~= true)
        and (type == nil or e[type] == true)
    end
end

--- cp.apple.finalcutpro.timeline.IndexRolesList:allRoles([includeSubroles]) -> table of Roles
--- Method
--- Returns the list of all [Role](cp.ui.Role.md)s in the current list.
---
--- Parameters:
--- * includeSubroles - if `true`, include Subroles, otherwise exclude them.
---
--- Returns:
--- * A `table` of [Role](cp.apple.finalcutpro.timeline.Role.md)s, or `nil` if no UI is available currently.
function IndexRolesList:allRoles(includeSubroles)
    return self:filterRows(rolesFilter(includeSubroles))
end

--- cp.apple.finalcutpro.timeline.IndexRolesList:videoRoles([includeSubroles]) -> table of Roles
--- Method
--- Returns the list of all video [Role](cp.ui.Role.md)s in the current list.
---
--- Parameters:
--- * includeSubroles - if `true`, include Subroles, otherwise exclude them.
---
--- Returns:
--- * A `table` of [Role](cp.apple.finalcutpro.timeline.Role.md)s, or `nil` if no UI is available currently.
function IndexRolesList:videoRoles(includeSubroles)
    return self:filterRows(rolesFilter(includeSubroles, "video"))
end

--- cp.apple.finalcutpro.timeline.IndexRolesList:audioRoles([includeSubroles]) -> table of Roles
--- Method
--- Returns the list of all audio [Role](cp.ui.Role.md)s in the current list.
---
--- Parameters:
--- * includeSubroles - if `true`, include Subroles, otherwise exclude them.
---
--- Returns:
--- * A `table` of [Role](cp.apple.finalcutpro.timeline.Role.md)s, or `nil` if no UI is available currently.
function IndexRolesList:audioRoles(includeSubroles)
    return self:filterRows(rolesFilter(includeSubroles, "audio"))
end

--- cp.apple.finalcutpro.timeline.IndexRolesList:allRoles([includeSubroles]) -> table of Roles
--- Method
--- Returns the list of caption [Role](cp.ui.Role.md)s in the current list.
---
--- Parameters:
--- * includeSubroles - if `true`, include Subroles, otherwise exclude them.
---
--- Returns:
--- * A `table` of [Role](cp.apple.finalcutpro.timeline.Role.md)s, or `nil` if no UI is available currently.
function IndexRolesList:captionRoles(includeSubroles)
    return self:filterRows(rolesFilter(includeSubroles, "caption"))
end

return IndexRolesList