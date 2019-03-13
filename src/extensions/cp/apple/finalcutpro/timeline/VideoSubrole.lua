--- === cp.apple.finalcutpro.timeline.VideoSubrole ==
---
--- *Extends [Role](cp.apple.finalcutpro.timeline.Role.md)*
---
--- A [Role](cp.apple.finalcutpro.timeline.Role.md) representing Captions.

local Role	                = require "cp.apple.finalcutpro.timeline.Role"
local VideoRole             = require "cp.apple.finalcutpro.timeline.VideoRole"

local VideoSubrole = Role:subclass("cp.apple.finalcutpro.timeline.VideoSubrole")

function VideoSubrole.static.matches(element)
    return Role.matches(element)
    and VideoRole.matches(element:attributeValue("AXDisclosedByRow"))
end

--- cp.apple.finalcutpro.timeline.VideoSubrole(parent, uiFinder)
--- Constructor
--- Creates a new instance with the specified `parent` and `uiFinder`.
---
--- Parameters:
--- * parent - the parent `Element`.
--- * uiFinder - a `function` or `cp.prop` containing the `axuielement`
---
--- Returns:
--- * The new `Row`.
function VideoSubrole:initialize(parent, uiFinder)
    Role.initialize(self, parent, uiFinder, Role.TYPE.VIDEO)
end

return VideoSubrole