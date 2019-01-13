--- === cp.apple.finalcutpro.timeline.CaptionsRole ==
---
--- *Extends [Role](cp.apple.finalcutpro.timeline.Role.md)*
---
--- A [Role](cp.apple.finalcutpro.timeline.Role.md) representing Captions.

-- local log	                = require "hs.logger" .new "CaptionsRole"

local axutils	            = require "cp.ui.axutils"
local Button	            = require "cp.ui.Button"
local CheckBox	            = require "cp.ui.CheckBox"

local Role	                = require "cp.apple.finalcutpro.timeline.Role"

local valueOf               = axutils.valueOf
local childrenMatching	    = axutils.childrenMatching
local childFromLeft	        = axutils.childFromLeft

local CaptionsRole = Role:subclass("cp.apple.finalcutpro.timeline.CaptionsRole")

--- cp.apple.finalcutpro.timeline.CaptionsRole.matches(element) -> boolean
--- Function
--- Checks if the element is a "Captions" Role.
function CaptionsRole.static.matches(element)
    return Role.matches(element)
    and valueOf(element, "AXDisclosureLevel") == 0
    and #childrenMatching(element[1], CheckBox.matches) == 2
end

--- cp.apple.finalcutpro.timeline.CaptionsRole(parent, uiFinder)
--- Constructor
--- Creates a new instance with the specified `parent` and `uiFinder`.
---
--- Parameters:
--- * parent - the parent `Element`.
--- * uiFinder - a `function` or `cp.prop` containing the `axuielement`
---
--- Returns:
--- * The new `Row`.
function CaptionsRole:initialize(parent, uiFinder)
    Role.initialize(self, parent, uiFinder, Role.TYPE.CAPTION)
end

--- cp.apple.finalcutpro.timeline.CaptionsRole:visibleInViewer() -> cp.ui.CheckBox
--- Method
--- A [CheckBox](cp.ui.CheckBox.md) that toggles whether captions are visible in the [Viewer](cp.apple.finalcutpro.main.Viewer.md).
function CaptionsRole.lazy.method:visibleInViewer()
    return CheckBox(self, self.cellUI:mutate(function(original)
        return childFromLeft(original(), 1, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.CaptionsRole:expand() -> cp.ui.Button
--- Method
--- A [Button](cp.ui.Button.md) that toggles whether the sub-captions are visible.
function CaptionsRole.lazy.method:subrolesExpanded()
    return Button(self, self.cellUI:mutate(function(original)
        return childFromLeft(original(), 1, CheckBox.matches())
    end))
end

return CaptionsRole