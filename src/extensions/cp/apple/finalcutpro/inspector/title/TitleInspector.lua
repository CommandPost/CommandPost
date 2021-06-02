--- === cp.apple.finalcutpro.inspector.title.TitleInspector ===
---
--- Title Inspector Module.
---
--- Extends [BaseMotionPanel](cp.apple.finalcutpro.inspector.BaseMotionPanel.md).

local require = require

-- local log								= require "hs.logger" .new "titleInspect"

local BaseMotionPanel                   = require "cp.apple.finalcutpro.inspector.BaseMotionPanel"


local TitleInspector = BaseMotionPanel:subclass("cp.apple.finalcutpro.inspector.title.TitleInspector")

--- cp.apple.finalcutpro.inspector.title.TitleInspector(parent) -> cp.apple.finalcutpro.inspector.title.TitleInspector
--- Constructor
--- Creates a new `TitleInspector` object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A `TitleInspector` object
function TitleInspector:initialize(parent)
    BaseMotionPanel.initialize(self, parent, "Title")
end

return TitleInspector
