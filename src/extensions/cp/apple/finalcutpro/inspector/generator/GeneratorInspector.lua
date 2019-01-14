--- === cp.apple.finalcutpro.inspector.generator.GeneratorInspector ===
---
--- Generator Inspector Module. This appears for both Generators and Titles.

local require = require

--local log                               = require("hs.logger").new("generatorInspector")

local BaseMotionPanel                       = require("cp.apple.finalcutpro.inspector.BaseMotionPanel")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local GeneratorInspector = BaseMotionPanel:subclass("cp.apple.finalcutpro.inspector.generator.GeneratorInspector")

--- cp.apple.finalcutpro.inspector.generator.GeneratorInspector(parent) -> GeneratorInspector object
--- Constructor
--- Creates a new GeneratorInspector object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A GeneratorInspector object
function GeneratorInspector:initialize(parent)
    BaseMotionPanel.initialize(self, parent, "Generator")
end

return GeneratorInspector
