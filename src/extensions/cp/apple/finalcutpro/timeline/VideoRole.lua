--- === cp.apple.finalcutpro.timeline.VideoRole ==
---
--- *Extends [Role](cp.apple.finalcutpro.timeline.Role.md)*
---
--- A [Role](cp.apple.finalcutpro.timeline.Role.md) representing Video clips.

-- local log	                = require "hs.logger" .new "VideoRole"

local axutils	            = require "cp.ui.axutils"
local Button	            = require "cp.ui.Button"
local CheckBox	            = require "cp.ui.CheckBox"

local Role	                = require "cp.apple.finalcutpro.timeline.Role"

local valueOf               = axutils.valueOf
local childrenMatching	    = axutils.childrenMatching
local childFromLeft	        = axutils.childFromLeft

local VideoRole = Role:subclass("cp.apple.finalcutpro.timeline.VideoRole")

--- cp.apple.finalcutpro.timeline.VideoRole.matches(element) -> boolean
--- Function
--- Checks if the element is a "Video" Role.
function VideoRole.static.matches(element)
    return Role.matches(element)
    and valueOf(element, "AXDisclosureLevel") == 0
    and #childrenMatching(element[1], CheckBox.matches) == 1
end

--- cp.apple.finalcutpro.timeline.VideoRole(parent, uiFinder)
--- Constructor
--- Creates a new instance with the specified `parent` and `uiFinder`.
---
--- Parameters:
--- * parent - the parent `Element`.
--- * uiFinder - a `function` or `cp.prop` containing the `axuielement`
---
--- Returns:
--- * The new `Row`.
function VideoRole:initialize(parent, uiFinder)
    Role.initialize(self, parent, uiFinder, Role.TYPE.VIDEO)
end

--- cp.apple.finalcutpro.timeline.VideoRole.subrolesExpanded <cp.ui.Button>
--- Field
--- A [Button](cp.ui.Button.md) that toggles whether the sub-captions are visible.
---
--- Note:
--- * This [Button](cp.ui.Button.md) is only visible when the pointer is hovering over the Role.
function VideoRole.lazy.value:subrolesExpanded()
    return Button(self, self.cellUI:mutate(function(original)
        return childFromLeft(original(), 1, Button.matches)
    end))
end

return VideoRole