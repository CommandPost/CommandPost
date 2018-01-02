--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.Slider ===
---
--- Slider Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")

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

--- cp.ui.Slider:new(axuielement, function) -> Slider
--- Function
--- Creates a new Slider
function Slider:new(parent, finderFn)
	local o = {_parent = parent, _finder = finderFn}
	return prop.extend(o, Slider)
end

-- TODO: Add documentation
function Slider:parent()
	return self._parent
end

function Slider:isShowing()
	return self:UI() ~= nil and self:parent():isShowing()
end

-- TODO: Add documentation
function Slider:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end,
	Slider.matches)
end

Slider.value = prop.new(
	function(self)
		local ui = self:UI()
		return ui and ui:attributeValue("AXValue")
	end,
	function(value, self)
		local ui = self:UI()
		if ui then
			ui:setAttributeValue("AXValue", value)
		end
	end
):bind(Slider)

-- TODO: Add documentation
function Slider:getValue()
	return self:value()
end

-- TODO: Add documentation
function Slider:setValue(value)
	self.value:set(value)
	return self
end

-- TODO: Add documentation
function Slider:shiftValue(value)
	local currentValue = self:value()
	self.value:set(currentValue - value)
	return self
end

Slider.minValue = prop.new(function(self)
	local ui = self:UI()
	return ui and ui:attributeValue("AXMinValue")
end)

-- TODO: Add documentation
function Slider:getMinValue()
	return self:minValue()
end

Slider.maxValue = prop.new(function(self)
	local ui = self:UI()
	return ui and ui:attributeValue("AXMaxValue")
end)

-- TODO: Add documentation
function Slider:getMaxValue()
	return self:maxValue()
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