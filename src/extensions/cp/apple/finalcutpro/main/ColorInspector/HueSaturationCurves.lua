--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.ColorInspector.HueSaturationCurves ===
---
--- Hue/Saturation Curves Module.
---
--- Requires Final Cut Pro 10.4 or later.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("hueSaturationCurves")

local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local CORRECTION_TYPE					= "Hue/Saturation Curves"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local HueSaturationCurves = {}

--- cp.apple.finalcutpro.main.ColorInspector.HueSaturationCurves:new(parent) -> HueSaturationCurves object
--- Method
--- Creates a new HueSaturationCurves object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A HueSaturationCurves object
function HueSaturationCurves:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}

	return prop.extend(o, HueSaturationCurves)
end

--- cp.apple.finalcutpro.main.ColorInspector.HueSaturationCurves:parent() -> table
--- Method
--- Returns the HueSaturationCurves's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function HueSaturationCurves:parent()
	return self._parent
end

--- cp.apple.finalcutpro.main.ColorInspector.HueSaturationCurves:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function HueSaturationCurves:app()
	return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- HUE/SATURATION CURVES:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.ColorInspector.HueSaturationCurves:show() -> boolean
--- Method
--- Show's the Color Board within the Color Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * HueSaturationCurves object
function HueSaturationCurves:show()
	self:parent():show(CORRECTION_TYPE)
	return self
end

return HueSaturationCurves