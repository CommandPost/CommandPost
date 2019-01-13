-- local log	                    = require "hs.logger" .new "IndexRolesList"

local go	                    = require "cp.rx.go"
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

local If                        = go.If

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

--- cp.apple.finalcutpro.timeline.IndexRolesList:filterRoles([matcherFn]) -> table of Roles or nil
--- Method
--- Filters the current list of [Role](cp.apple.finalcutpro.timeline.Role.md)s based on the given `matchesFn` predicate.
---
--- Parameters:
--- * matchesFn - the matcher function. If not provided, no additional filtering occurs.
---
--- Returns:
--- * The table of [Role](cp.apple.finalcutpro.timeline.Role.md), or `nil` if no UI is currently available.
function IndexRolesList:filterRoles(matchesFn)
    return self:filterRows(function(e) return Role.is(e) and (matchesFn == nil or matchesFn(e)) end)
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

--- cp.apple.finalcutpro.timeline.IndexRolesList:findRoleTitled(title) -> Role or nil
--- Method
--- Returns the [Role](cp.apple.finalcutpro.timeline.Role.md) with the specified title.
---
--- Parameters:
--- * title - The title of the role to find.
---
--- Returns:
--- * The [Role](cp.apple.finalcutpro.timeline.Role.md), or `nil` if it can't be found.
---
--- Notes:
--- * The title can be the English name (eg. "Video", "Titles", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRolesList:findRoleTitled(title)
    --- find the language-specific title
    title = Role.findTitle(title)
    --- search for it.
    local rows = self:filterRoles(function(e) return e:title():value() == title end)
    return rows and rows[1]
end

--- cp.apple.finalcutpro.timeline.IndexRolesList:doActivate(title) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will activate the provided role, if it is available.
---
--- Parameters:
--- * title - The title of the [Role](cp.apple.finalcutpro.timeline.Role.md) to activate.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * The title can be the English name (eg. "Video", "Titles", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRolesList:doActivate(title)
    return If(function() return self:findRoleTitled(title) end)
    :Then(function(role)
        return role:doActivate()
    end)
    :Otherwise(false)
    :Label("IndexRolesList:doActivate")
end

--- cp.apple.finalcutpro.timeline.IndexRolesList:doDeactivate(title) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will deactivate the provided role, if it is available.
---
--- Parameters:
--- * title - The title of the [Role](cp.apple.finalcutpro.timeline.Role.md) to deactivate.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * The title can be the English name (eg. "Video", "Titles", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRolesList:doDeactivate(title)
    return If(function() return self:findRoleTitled(title) end)
    :Then(function(role)
        return role:doDeactivate()
    end)
    :Otherwise(false)
    :Label("IndexRolesList:doDeactivate")
end

--- cp.apple.finalcutpro.timeline.IndexRolesList:doFocusInTimeline(title) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will focus the provided [AudioRole](cp.apple.finalcutpro.timeline.AudioRole.md), if it is available.
---
--- Parameters:
--- * title - The title of the [Role](cp.apple.finalcutpro.timeline.Role.md) to activate.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * The title can be the English name (eg. "Video", "Titles", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRolesList:doFocusInTimeline(title)
    return If(function() return self:findRoleTitled(title) end)
    :Then(function(role)
        return role:isInstanceOf(AudioRole) and role:doFocusInTimeline()
    end)
    :Otherwise(false)
    :Label("IndexRolesList:doFocusInTimeline")
end

--- cp.apple.finalcutpro.timeline.IndexRolesList:doUnfocusInTimeline(title) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will unfocus the provided [AudioRole](cp.apple.finalcutpro.timeline.AudioRole.md), if it is available.
---
--- Parameters:
--- * title - The title of the [Role](cp.apple.finalcutpro.timeline.Role.md) to activate.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * The title can be the English name (eg. "Dialogue", "Music", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRolesList:doUnfocusInTimeline(title)
    return If(function() return self:findRoleTitled(title) end)
    :Then(function(role)
        return role:isInstanceOf(AudioRole) and role:doUnfocusInTimeline()
    end)
    :Otherwise(false)
    :Label("IndexRolesList:doUnfocusInTimeline")
end

--- cp.apple.finalcutpro.timeline.IndexRolesList:doShowSubroleLanes(title) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will show subrole lanes for the provided [AudioRole](cp.apple.finalcutpro.timeline.AudioRole.md), if it is available.
---
--- Parameters:
--- * title - The title of the [Role](cp.apple.finalcutpro.timeline.Role.md).
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * The title can be the English name (eg. "Dialogue", "Music", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRolesList:doShowSubroleLanes(title)
    return If(function() return self:findRoleTitled(title) end)
    :Then(function(role)
        return role:isInstanceOf(AudioRole) and role:doShowSubroleLanes()
    end)
    :Otherwise(false)
    :Label("IndexRolesList:doShowSubroleLanes")
end

--- cp.apple.finalcutpro.timeline.IndexRolesList:doHideSubroleLanes(title) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will hide subrole lanes for the provided [AudioRole](cp.apple.finalcutpro.timeline.AudioRole.md), if it is available.
---
--- Parameters:
--- * title - The title of the [Role](cp.apple.finalcutpro.timeline.Role.md).
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * The title can be the English name (eg. "Dialogue", "Music", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRolesList:doHideSubroleLanes(title)
    return If(function() return self:findRoleTitled(title) end)
    :Then(function(role)
        return role:isInstanceOf(AudioRole) and role:doHideSubroleLanes()
    end)
    :Otherwise(false)
    :Label("IndexRolesList:doHideSubroleLanes")
end

return IndexRolesList