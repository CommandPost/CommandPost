--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Slider UI

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local axutils						= require("cp.finalcutpro.axutils")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Slider = {}

-- TODO: Add documentation
function Slider.matches(element)
	return element:attributeValue("AXRole") == "AXSlider"
end

--- cp.finalcutpro.ui.Slider:new(axuielement, function) -> Slider
--- Function:
--- Creates a new Slider
function Slider:new(parent, finderFn)
	o = {_parent = parent, _finder = finderFn}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function Slider:parent()
	return self._parent
end

-- TODO: Add documentation
function Slider:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end,
	Slider.matches)
end

-- TODO: Add documentation
function Slider:getValue()
	local ui = self:UI()
	return ui and ui:attributeValue("AXValue")
end

-- TODO: Add documentation
function Slider:setValue(value)
	local ui = self:UI()
	if ui then
		ui:setAttributeValue("AXValue", value)
	end
	return self
end

-- TODO: Add documentation
function Slider:getMinValue()
	local ui = self:UI()
	return ui and ui:attributeValue("AXMinValue")
end

-- TODO: Add documentation
function Slider:getMaxValue()
	local ui = self:UI()
	return ui and ui:attributeValue("AXMaxValue")
end

-- TODO: Add documentation
function Slider:increment()
	local ui = self:UI()
	if ui then
		ui:doIncrement()
	end
	return self
end

-- TODO: Add documentation
function Slider:decrement()
	local ui = self:UI()
	if ui then
		ui:doDecrement()
	end
	return self
end

-- TODO: Add documentation
function Slider:isEnabled()
	local ui = self:UI()
	return ui and ui:enabled()
end

-- TODO: Add documentation
function Slider:saveLayout()
	local layout = {}
	layout.value = self:getValue()
	return layout
end

-- TODO: Add documentation
function Slider:loadLayout(layout)
	if layout then
		self:setValue(layout.value)
	end
end

return Slider