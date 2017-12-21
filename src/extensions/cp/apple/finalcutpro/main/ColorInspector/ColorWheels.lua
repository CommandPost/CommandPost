--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.ColorInspector.ColorWheels ===
---
--- Color Wheels Module.
---
--- Requires Final Cut Pro 10.4 or later.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("colorWheels")

local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local CORRECTION_TYPE					= "Color Wheels"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorWheels = {}

--- cp.apple.finalcutpro.main.ColorInspector.ColorWheels:new(parent) -> ColorInspector object
--- Method
--- Creates a new ColorWheels object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A ColorInspector object
function ColorWheels:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}

	return prop.extend(o, ColorWheels)
end

--- cp.apple.finalcutpro.main.ColorInspector.ColorWheels:parent() -> table
--- Method
--- Returns the ColorWheels's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function ColorWheels:parent()
	return self._parent
end

--- cp.apple.finalcutpro.main.ColorInspector.ColorWheels:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function ColorWheels:app()
	return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- COLOR WHEELS:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.ColorInspector.ColorWheels:show() -> boolean
--- Method
--- Show's the Color Board within the Color Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorWheels object
function ColorWheels:show()
	self:parent():show(CORRECTION_TYPE)
	return self
end

return ColorWheels