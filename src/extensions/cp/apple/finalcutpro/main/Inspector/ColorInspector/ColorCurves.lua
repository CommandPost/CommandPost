--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorCurves ===
---
--- Color Curves Module.
---
--- Requires Final Cut Pro 10.4 or later.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("colorCurves")

local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local CORRECTION_TYPE					= "Color Curves"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorCurves = {}

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorCurves:new(parent) -> ColorCurves object
--- Method
--- Creates a new ColorCurves object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A ColorInspector object
function ColorCurves:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}

	return prop.extend(o, ColorCurves)
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorCurves:parent() -> table
--- Method
--- Returns the ColorCurves's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function ColorCurves:parent()
	return self._parent
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorCurves:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function ColorCurves:app()
	return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- COLOR CURVES:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorCurves:show() -> boolean
--- Method
--- Show's the Color Board within the Color Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorCurves object
function ColorCurves:show()
	self:parent():show(CORRECTION_TYPE)
	return self
end

return ColorCurves