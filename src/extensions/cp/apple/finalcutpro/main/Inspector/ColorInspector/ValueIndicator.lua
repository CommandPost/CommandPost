--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.ValueIndicator ===
---
--- ValueIndicator Module.

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
local ValueIndicator = {}

-- TODO: Add documentation
function ValueIndicator.matches(element)
	return element:attributeValue("AXRole") == "AXValueIndicator"
end

--- cp.ui.ValueIndicator:new(parent, finderFn, minValue, maxValue, toAXValueFn, fromAXValueFn) -> ValueIndicator
--- Method
--- Creates a new ValueIndicator.
---
--- Parameters:
--- * parent	- The parent table.
--- * finderFn	- The function which returns the `axuielement`.
--- * minValue	- The minimum value allowed for the value.
--- * maxValue	- The maximum value allowed for the value.
--- * toAXValueFn	- The function which will convert the user value to the actual AXValue.
--- * fromAXValueFn	- The function which will convert the current AXValue to a user value.
---
--- Returns:
--- * New `ValueIndicator` instance.
function ValueIndicator:new(parent, finderFn, minValue, maxValue, toAXValueFn, fromAXValueFn)
	return prop.extend({
		_parent = parent,
		_finder = finderFn,
		_minValue = minValue,
		_maxValue = maxValue,
		_toAXValueFn = toAXValueFn,
		_fromAXValueFn = fromAXValueFn,
	}, ValueIndicator)
end

-- TODO: Add documentation
function ValueIndicator:parent()
	return self._parent
end

function ValueIndicator:isShowing()
	return self:UI() ~= nil and self:parent():isShowing()
end

-- TODO: Add documentation
function ValueIndicator:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end,
	ValueIndicator.matches)
end

ValueIndicator.value = prop.new(
	function(self)
		local ui = self:UI()
		local value = ui and ui:attributeValue("AXValue") or nil
		if value ~= nil then
			if self._fromAXValueFn then
				value = self._fromAXValueFn(value)
			end
			return value
		end
		return nil
	end,
	function(value, self)
		local ui = self:UI()
		if ui then
			if self._toAXValueFn then
				value = self._toAXValueFn(value)
			end
			ui:setAttributeValue("AXValue", value)
		end
	end
):bind(ValueIndicator)

-- TODO: Add documentation
function ValueIndicator:shiftValue(value)
	local currentValue = self:value()
	self.value:set(currentValue - value)
	return self
end

ValueIndicator.minValue = prop.new(function(self)
	return self._minValue
end)

ValueIndicator.maxValue = prop.new(function(self)
	return self._maxValue
end)

-- TODO: Add documentation
function ValueIndicator:increment()
	local ui = self:UI()
	if ui then
		ui:doIncrement()
	end
	return self
end

-- TODO: Add documentation
function ValueIndicator:decrement()
	local ui = self:UI()
	if ui then
		ui:doDecrement()
	end
	return self
end

-- TODO: Add documentation
function ValueIndicator:isEnabled()
	local ui = self:UI()
	return ui and ui:enabled()
end

-- TODO: Add documentation
function ValueIndicator:saveLayout()
	local layout = {}
	layout.value = self:getValue()
	return layout
end

-- TODO: Add documentation
function ValueIndicator:loadLayout(layout)
	if layout then
		self:setValue(layout.value)
	end
end

return ValueIndicator