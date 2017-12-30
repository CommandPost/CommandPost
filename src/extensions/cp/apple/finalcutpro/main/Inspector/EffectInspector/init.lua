--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.Inspector.EffectInspector ===
---
--- Effect Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("effectInspect")

local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local EffectInspector = {}

--- cp.apple.finalcutpro.main.Inspector.EffectInspector:new(parent) -> EffectInspector object
--- Method
--- Creates a new EffectInspector object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A EffectInspector object
function EffectInspector:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}
	return prop.extend(o, EffectInspector)
end

--- cp.apple.finalcutpro.main.Inspector.EffectInspector:parent() -> table
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

--- cp.apple.finalcutpro.main.Inspector.EffectInspector:app() -> table
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