--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.share.ShareInspector ===
---
--- Share Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("shareInspect")

local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ShareInspector = {}

--- cp.apple.finalcutpro.inspector.share.ShareInspector:new(parent) -> ShareInspector object
--- Method
--- Creates a new ShareInspector object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A ShareInspector object
function ShareInspector:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}
	return prop.extend(o, ShareInspector)
end

--- cp.apple.finalcutpro.inspector.share.ShareInspector:parent() -> table
--- Method
--- Returns the ShareInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function ShareInspector:parent()
	return self._parent
end

--- cp.apple.finalcutpro.inspector.share.ShareInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function ShareInspector:app()
	return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- SHARE INSPECTOR:
--
--------------------------------------------------------------------------------

return ShareInspector