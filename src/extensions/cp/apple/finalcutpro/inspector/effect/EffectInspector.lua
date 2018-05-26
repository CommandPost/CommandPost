--- === cp.apple.finalcutpro.inspector.effect.EffectInspector ===
---
--- Effect Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                               = require("hs.logger").new("effectInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop                              = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local EffectInspector = {}

--- cp.apple.finalcutpro.inspector.effect.EffectInspector:new(parent) -> EffectInspector object
--- Method
--- Creates a new EffectInspector object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A EffectInspector object
-- TODO: Use a function instead of a method.
function EffectInspector:new(parent) -- luacheck: ignore
    local o = {
        _parent = parent,
        _child = {}
    }
    return prop.extend(o, EffectInspector)
end

--- cp.apple.finalcutpro.inspector.effect.EffectInspector:parent() -> table
--- Method
--- Returns the EffectInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function EffectInspector:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.effect.EffectInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function EffectInspector:app()
    return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- EFFECT INSPECTOR:
--
--------------------------------------------------------------------------------

return EffectInspector
