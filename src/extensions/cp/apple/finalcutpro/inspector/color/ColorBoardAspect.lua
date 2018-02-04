--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspect.color.ColorBoardAspect ===
---
--- Represents a particular aspect of the color board (Color/Saturation/Exposure).

local axutils					= require("cp.ui.axutils")
local prop						= require("cp.prop")

local PropertyRow				= require("cp.ui.PropertyRow")
local TextField					= require("cp.ui.TextField")

local ColorPuck					= require("cp.apple.finalcutpro.inspector.color.ColorPuck")

local ColorBoardAspect = {}

--- cp.apple.finalcutpro.inspect.color.ColorBoard.matches() -> boolean
--- Function
--- Checks if the element is a ColorBoardAspect.
function ColorBoardAspect.matches(element)
	return element and element:attributeValue("AXRole") == "AXGroup"
end

function ColorBoardAspect:new(parent, index)
	local o = prop.extend({
		_parent = parent,
		_index = index,
	}, ColorBoardAspect)

	return o
end

function ColorBoardAspect:parent()
	return self._parent
end

function ColorBoardAspect:app()
	return self:parent():app()
end

function ColorBoardAspect:UI()
	local parent = self:parent()
	-- only return the if this is the currently-selected aspect
	if parent:aspectGroup():selectedOption() == self._index then
		return parent:contentUI()
	end
end

function ColorBoardAspect:show()
	if not self:isShowing() then
		local parent = self:parent()
		parent:show()
		parent:aspectGroup():selectedOption(self._index)
	end
	return self
end

function ColorBoardAspect:isShowing()
	return self:UI() ~= nil
end

function ColorBoardAspect:index()
	return self._index
end

function ColorBoardAspect:master()
	if not self._master then
		self._master = ColorPuck:new(
			self, ColorPuck.range.master,
			{"cb master puck display name", "cb global puck display name"}
		)
	end
	return self._master
end

function ColorBoardAspect:shadows()
	if not self._shadows then
		self._shadows = ColorPuck:new(
			self, ColorPuck.range.shadows,
			"cb shadow puck display name"
		)
	end
	return self._shadows
end

function ColorBoardAspect:midtones()
	if not self._midtones then
		self._midtones = ColorPuck:new(
			self, ColorPuck.range.midtones,
			"cb midtone puck display name"
		)
	end
	return self._midtones
end

function ColorBoardAspect:highlights()
	if not self._highlights then
		self._highlights = ColorPuck:new(
			self, ColorPuck.range.highlights,
			"cb highlight puck display name"
		)
	end
	return self._highlights
end

return ColorBoardAspect