--- === cp.apple.finalcutpro.timeline.CaptionsSubrole ==
---
--- *Extends [Role](cp.apple.finalcutpro.timeline.Role.md)*
---
--- A [Role](cp.apple.finalcutpro.timeline.Role.md) representing Captions.

local axutils	            = require "cp.ui.axutils"
local CheckBox	            = require "cp.ui.CheckBox"
local StaticText	        = require "cp.ui.StaticText"

local Role	                = require "cp.apple.finalcutpro.timeline.Role"
local CaptionsRole          = require "cp.apple.finalcutpro.timeline.CaptionsRole"

local CaptionsSubrole = Role:subclass("cp.apple.finalcutpro.timeline.CaptionsSubrole")

--- cp.apple.finalcutpro.timeline.CaptionsSubrole.matches(element) -> boolean
--- Function
--- Checks if the element is a "Captions" Subrole.
function CaptionsSubrole.static.matches(element)
    return Role.matches(element)
    and CaptionsRole.matches(element:attributeValue("AXDisclosedByRow"))
end

--- cp.apple.finalcutpro.timeline.CaptionsSubrole(parent, uiFinder)
--- Constructor
--- Creates a new instance with the specified `parent` and `uiFinder`.
---
--- Parameters:
--- * parent - the parent `Element`.
--- * uiFinder - a `function` or `cp.prop` containing the `axuielement`
---
--- Returns:
--- * The new `Row`.
function CaptionsSubrole:initialize(parent, uiFinder)
    Role.initialize(self, parent, uiFinder, Role.TYPE.CAPTION)
end

--- cp.apple.finalcutpro.timeline.CaptionsSubrole.format <cp.ui.StaticText>
--- Field
--- A [StaticText](cp.ui.StaticText.md) which represents the subtitle format (e.g. "ITT", "SRT").
function CaptionsSubrole.lazy.value:format()
    return StaticText(self, self.cellUI:mutate(function(original)
        return axutils.childFromLeft(original(), 1, StaticText.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.CaptionsSubrole.visibleInTimeline <cp.ui.CheckBox>
--- Field
--- A [CheckBox](cp.ui.CheckBox.md) that indicates if the subtitle track is visible in the Viewer.
function CaptionsSubrole.lazy.value:visibleInViewer()
    return CheckBox(self, self.cellUI:mutate(function(original)
        return axutils.childFromLeft(original(), 1, CheckBox.matches)
    end))
end

return CaptionsSubrole