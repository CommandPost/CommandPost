--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.generator.GeneratorInspector ===
---
--- Generator Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                               = require("hs.logger").new("generatorInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop                              = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local GeneratorInspector = {}

--- cp.apple.finalcutpro.inspector.generator.GeneratorInspector:new(parent) -> GeneratorInspector object
--- Method
--- Creates a new GeneratorInspector object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A GeneratorInspector object
-- TODO: Use a function instead of a method.
function GeneratorInspector:new(parent) -- luacheck: ignore
    local o = {
        _parent = parent,
        _child = {}
    }
    return prop.extend(o, GeneratorInspector)
end

--- cp.apple.finalcutpro.inspector.generator.GeneratorInspector:parent() -> table
--- Method
--- Returns the GeneratorInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function GeneratorInspector:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.generator.GeneratorInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function GeneratorInspector:app()
    return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- GENERATOR INSPECTOR:
--
--------------------------------------------------------------------------------

return GeneratorInspector
