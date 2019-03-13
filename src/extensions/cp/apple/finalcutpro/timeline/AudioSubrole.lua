--- === cp.apple.finalcutpro.timeline.AudioSubrole ==
---
--- *Extends [Role](cp.apple.finalcutpro.timeline.Role.md)*
---
--- A [Role](cp.apple.finalcutpro.timeline.Role.md) representing Audio.

local Role	             = require "cp.apple.finalcutpro.timeline.Role"
local AudioRole          = require "cp.apple.finalcutpro.timeline.AudioRole"

local AudioSubrole = Role:subclass("cp.apple.finalcutpro.timeline.AudioSubrole")

--- cp.apple.finalcutpro.timeline.AudioSubrole.matches(element) -> boolean
--- Function
--- Checks if the element is a "Audio" Subrole.
function AudioSubrole.static.matches(element)
    return Role.matches(element)
    and AudioRole.matches(element:attributeValue("AXDisclosedByRow"))
end

--- cp.apple.finalcutpro.timeline.AudioSubrole(parent, uiFinder)
--- Constructor
--- Creates a new instance with the specified `parent` and `uiFinder`.
---
--- Parameters:
--- * parent - the parent `Element`.
--- * uiFinder - a `function` or `cp.prop` containing the `axuielement`
---
--- Returns:
--- * The new `Row`.
function AudioSubrole:initialize(parent, uiFinder)
    Role.initialize(self, parent, uiFinder, Role.TYPE.AUDIO)
end

return AudioSubrole