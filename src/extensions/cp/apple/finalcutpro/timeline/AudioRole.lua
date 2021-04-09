--- === cp.apple.finalcutpro.timeline.AudioRole ==
---
--- *Extends [Role](cp.apple.finalcutpro.timeline.Role.md)*
---
--- A [Role](cp.apple.finalcutpro.timeline.Role.md) representing Audio.

-- local log	                = require "hs.logger" .new "AudioRole"

local axutils	            = require "cp.ui.axutils"
local CheckBox	            = require "cp.ui.CheckBox"

local Role	                = require "cp.apple.finalcutpro.timeline.Role"

local valueOf               = axutils.valueOf
local childrenMatching	    = axutils.childrenMatching
local childFromRight	    = axutils.childFromRight

local AudioRole = Role:subclass("cp.apple.finalcutpro.timeline.AudioRole")

--- cp.apple.finalcutpro.timeline.AudioRole.matches(element) -> boolean
--- Function
--- Checks if the element is a "Audio" Role.
---
--- Parameters:
---  * element - An element to check
---
--- Returns:
---  * A boolean
function AudioRole.static.matches(element)
    return Role.matches(element)
    and valueOf(element, "AXDisclosureLevel") == 0
    and #childrenMatching(element[1], CheckBox.matches) == 4
end

--- cp.apple.finalcutpro.timeline.AudioRole(parent, uiFinder)
--- Constructor
--- Creates a new instance with the specified `parent` and `uiFinder`.
---
--- Parameters:
--- * parent - the parent `Element`.
--- * uiFinder - a `function` or `cp.prop` containing the `axuielement`
---
--- Returns:
--- * The new `Row`.
function AudioRole:initialize(parent, uiFinder)
    Role.initialize(self, parent, uiFinder, Role.TYPE.AUDIO)
end

--- cp.apple.finalcutpro.timeline.AudioRole.focusedInTimeline <cp.ui.CheckBox>
--- Field
--- A [CheckBox](cp.ui.CheckBox.md) that toggles this role is larger than the other audio roles on the timeline.
function AudioRole.lazy.value:focusedInTimeline()
    return CheckBox(self, self.cellUI:mutate(function(original)
        return childFromRight(original(), 1, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.AudioRole.subrolesExpanded <cp.ui.CheckButton>
--- Field
--- A [CheckButton](cp.ui.CheckButton.md) that toggles whether the roles are visible in the Index.
---
--- Notes:
--- * Unlike the [VideoRole](cp.finalcutpro.apple.timeline.VideoRole.md) and [CaptionsRole](cp.apple.finalcutpro.timeline.CaptionsRole.md), this is a [CheckBox](cp.ui.CheckBox.md) and is always visible.
function AudioRole.lazy.value:subrolesExpanded()
    return CheckBox(self, self.cellUI:mutate(function(original)
        return childFromRight(original(), 2, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.AudioRole.subroleLanes <cp.ui.CheckButton>
--- Field
--- A [CheckButton](cp.ui.CheckButton.md) that toggles whether the subroles are visible in the [Timeline](cp.apple.finalcutpro.timeline.Timeline.md).
function AudioRole.lazy.value:subroleLanes()
    return CheckBox(self, self.cellUI:mutate(function(original)
        return childFromRight(original(), 3, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.AudioRole:doFocusInTimeline() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to focus on this audio role in the timeline.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A Statement
function AudioRole.lazy.method:doFocusInTimeline()
    return self.focusedInTimeline:doCheck()
end

--- cp.apple.finalcutpro.timeline.AudioRole:doUnfocusInTimeline() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to unfocus on this audio role in the timeline.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A Statement
function AudioRole.lazy.method:doUnfocusInTimeline()
    return self.focusedInTimeline:doUncheck()
end

--- cp.apple.finalcutpro.timeline.AudioRole:doShowSubroleLanes() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to show the subrole lanes on this audio role in the timeline.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A Statement
function AudioRole.lazy.method:doShowSubroleLanes()
    return self.subroleLanes:doCheck()
end

--- cp.apple.finalcutpro.timeline.AudioRole:doHideSubroleLanes() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to hide the subrole lanes on this audio role in the timeline.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A Statement
function AudioRole.lazy.method:doHideSubroleLanes()
    return self.subroleLanes:doUncheck()
end

return AudioRole