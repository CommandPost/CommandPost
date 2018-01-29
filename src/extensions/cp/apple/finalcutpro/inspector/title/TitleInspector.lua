--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.title.TitleInspector ===
---
--- Title Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("videoInspect")

local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TitleInspector = {}

--- cp.apple.finalcutpro.inspector.title.TitleInspector:new(parent) -> TitleInspector object
--- Method
--- Creates a new TitleInspector object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A TitleInspector object
function TitleInspector:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}
	return prop.extend(o, TitleInspector)
end

--- cp.apple.finalcutpro.inspector.title.TitleInspector:parent() -> table
--- Method
--- Returns the TitleInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function TitleInspector:parent()
	return self._parent
end

--- cp.apple.finalcutpro.inspector.title.TitleInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function TitleInspector:app()
	return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- TITLE INSPECTOR:
--
--------------------------------------------------------------------------------

return TitleInspector