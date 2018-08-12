--- === cp.apple.finalcutpro.inspector.transition.TransitionInspector ===
---
--- Transition Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log								= require("hs.logger").new("transInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TransitionInspector = {}

--- cp.apple.finalcutpro.inspector.transition.TransitionInspector.new(parent) -> TransitionInspector
--- Constructor
--- Creates a new `TransitionInspector` object.
---
--- Parameters:
---  * parent - The parent
---
--- Returns:
---  * A `TransitionInspector` object
function TransitionInspector.new(parent)
    local o = {
        _parent = parent,
        _child = {}
    }
    return prop.extend(o, TransitionInspector)
end

--- cp.apple.finalcutpro.inspector.transition.TransitionInspector:parent() -> table
--- Method
--- Returns the TransitionInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function TransitionInspector:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.transition.TransitionInspector:app() -> App
--- Method
--- Returns the `cp.apple.finalcutpro` object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object
function TransitionInspector:app()
    return self:parent():app()
end

return TransitionInspector
