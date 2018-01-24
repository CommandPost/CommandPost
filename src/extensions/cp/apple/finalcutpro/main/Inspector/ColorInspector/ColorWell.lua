--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWell ===
---
--- Represents a single Color Well in the Color Wheels Inspector.
---
--- Requires Final Cut Pro 10.4 or later.
--
-----------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log                               = require("hs.logger").new("colorWell")

local prop                              = require("cp.prop")
local axutils							= require("cp.ui.axutils")

local ColorWell = {}

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWell.matches(element)
--- Function
--- Checks if the specified element is a Color Well.
---
--- Parameters:
--- * element	- The element to check
---
--- Returns:
--- * `true` if the element is a Color Well.
function ColorWell.matches(element)
	if element and element:attributeValue("AXRole") == "AXGroup" and #element == 4 then
		return axutils.childWithRole(element, "AXColorWell") ~= nil
	end
	return false
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWell:new(parent, finderFn) -> ColorWell
--- Method
--- Creates a new `ColorWell` instance, with the specified parent and finder function.
--- The finder function should return the specific color well UI element that this instance represents.
---
--- Parameters:
--- * parent - The parent object
--- * finderFn - Returns the `axuielement` that represents the color well.
---
--- Returns:
--- * A new `ColorWell` instance.
function ColorWell:new(parent, finderFn)
	local o = prop.extend({
		_parent = parent,
		_finder = finderFn,
	}, ColorWell)

	return o
end

function ColorWell:parent()
	return self._parent
end

function ColorWell:app()
	return self:parent():app()
end

function ColorWell:UI()
	return axutils.cache(self, "_ui",
		function()
			return self._finder()
		end
	)
end

function ColorWell:isShowing()
	return self:UI() ~= nil
end

return ColorWell