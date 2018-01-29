--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.transition.TransitionInspector ===
---
--- Transition Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("transInspect")

local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TransitionInspector = {}

--- cp.apple.finalcutpro.inspector.transition.TransitionInspector:new(parent) -> TransitionInspector object
--- Method
--- Creates a new TransitionInspector object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A TransitionInspector object
function TransitionInspector:new(parent)
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

--- cp.apple.finalcutpro.inspector.transition.TransitionInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function TransitionInspector:app()
	return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- TRANSITION INSPECTOR:
--
--------------------------------------------------------------------------------

return TransitionInspector