--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.info.InfoInspector ===
---
--- Video Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("infoInspect")

local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local InfoInspector = {}

--- cp.apple.finalcutpro.inspector.info.InfoInspector:new(parent) -> InfoInspector object
--- Method
--- Creates a new InfoInspector object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A InfoInspector object
function InfoInspector:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}
	return prop.extend(o, InfoInspector)
end

--- cp.apple.finalcutpro.inspector.info.InfoInspector:parent() -> table
--- Method
--- Returns the InfoInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function InfoInspector:parent()
	return self._parent
end

--- cp.apple.finalcutpro.inspector.info.InfoInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function InfoInspector:app()
	return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- INFO INSPECTOR:
--
--------------------------------------------------------------------------------

return InfoInspector