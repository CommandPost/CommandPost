--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.ColorInspector ===
---
--- Color Inspector Module.
---
--- Require Final Cut Pro 10.4 or later

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("colorInspect")
local inspect							= require("hs.inspect")
local geometry							= require("hs.geometry")

local prop								= require("cp.prop")
local just								= require("cp.just")
local axutils							= require("cp.ui.axutils")
local tools								= require("cp.tools")

local id								= require("cp.apple.finalcutpro.ids") "ColorInspector"

local semver							= require("semver")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorInspector = {}

--- cp.apple.finalcutpro.main.ColorInspector:new(parent) -> ColorInspector object
--- Method
--- Creates a new ColorInspector object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A ColorInspector object
function ColorInspector:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}

	return prop.extend(o, ColorInspector)
end

--- cp.apple.finalcutpro.main.ColorInspector:parent() -> table
--- Method
--- Returns the ColorInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function ColorInspector:parent()
	return self._parent
end

--- cp.apple.finalcutpro.main.ColorInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function ColorInspector:app()
	return self:parent():app()
end

return ColorInspector