local log	                    = require "hs.logger" .new "IndexRolesOutline"

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

local IndexRolesOutline = Outline:subclass("cp.apple.finalcutpro.timeline.IndexRolesOutline")

-- cp.apple.finalcutpro.timeline.IndexRolesOutline:createRow(rowUI) -> cp.apple.finalcutpro.timeline.Role
-- Private Method
-- Returns Rows as a Role.
function IndexRolesOutline:createRow(rowUI)
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

return IndexRolesOutline