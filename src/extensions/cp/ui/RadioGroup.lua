--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.RadioGroup ===
---
--- Represents an `AXRadioGroup`, providing utility methods.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("radioGroup")
local inspect						= require("hs.inspect")

local axutils						= require("cp.ui.axutils")

local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local RadioGroup = {}

--- cp.ui.RadioGroup.matches(element) -> boolean
--- Function
--- Checks if the provided `axuielement` is a RadioGroup.
---
--- Parameters:
--- * element	- The element to check.
---
--- Returns:
--- * `true` if the element is a RadioGroup.
function RadioGroup.matches(element)
	return element and element:attributeValue("AXRole") == "AXRadioGroup"
end

--- cp.ui.RadioGroup:new(parent, finderFn[, cached]) -> RadioGroup
--- Method
--- Creates a new RadioGroup.
---
--- Parameters:
--- * parent	- The parent table.
--- * finderFn	- The function which will find the `axuielement` representing the RadioGroup.
--- * cached	- If set to `false`, the `axuielement` will not be cached. Defaults to `true`.
---
--- Returns:
--- * The new `RadioGroup` instance.
function RadioGroup:new(parent, finderFn, cached)
	local o = prop.extend({
		_parent = parent,
		_finder = finderFn,
		_cached = cached ~= false and true or false,
	}, RadioGroup)
	return o
end

--- cp.ui.RadioGroup:parent() -> table
--- Method
--- Returns the parent object.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The parent object.
function RadioGroup:parent()
	return self._parent
end

--- cp.ui.RadioGroup:isShowing() -> boolean
--- Method
--- Checks if the RadioGroup is visible.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the RadioGroup is visible.
function RadioGroup:isShowing()
	return self:UI() ~= nil and self:parent():isShowing()
end

--- cp.ui.RadioGroup:UI() -> axuielement
--- Method
--- Returns the `axuielement` for the RadioGroup, or `nil` if not currently visible.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `asuielement` or `nil`.
function RadioGroup:UI()
	if self._cached then
		return axutils.cache(self, "_ui", function()
			return self._finder()
		end,
		RadioGroup.matches)
	else
		return self._finder()
	end
end

--- cp.ui.RadioGroup:isEnabled()
--- Method
--- Checks if the RadioGroup is enabled.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the RadioGroup is showing and enabled.
function RadioGroup:isEnabled()
	local ui = self:UI()
	return ui and ui:enabled()
end

--- cp.ui.RadioGroup.optionCount <cp.prop: number; read-only>
--- Field
--- The number of options in the group.
RadioGroup.optionCount = prop(
	function(self)
		local ui = self:UI()
		return ui and #ui or 0
	end
):bind(RadioGroup)



--- cp.ui.RadioGroup.selectedOption <cp.prop: number>
--- Field
--- The currently selected option number.
RadioGroup.selectedOption = prop(
	function(self)
		local ui = self:UI()
		if ui then
			for i,item in ipairs(ui:children()) do
				if item:attributeValue("AXValue") == 1 then
					return i
				end
			end
		end
		return nil
	end,
	function(index, self)
		local ui = self:UI()
		if ui then
			if index >= 1 and index <= #ui then
				local item = ui[index]
				if item and item:attributeValue("AXValue") ~= 1 then
					item:doPress()
					return index
				end
			end
		end
		return nil
	end
):bind(RadioGroup)

--- cp.ui.RadioGroup:nextOption() -> self
--- Method
--- Selects the next option in the group. Cycles from the last to the first option.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `RadioGroup`.
function RadioGroup:nextOption()
	local selected = self:selectedOption()
	local count = self:optionCount()
	selected = selected >= count and 1 or selected + 1
	self:selectedOption(selected)
	return self
end

--- cp.ui.RadioGroup:previousOption() -> self
--- Method
--- Selects the previous option in the group. Cycles from the first to the last item.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `RadioGroup`.
function RadioGroup:previousOption()
	local selected = self:selectedOption()
	local count = self:optionCount()
	selected = selected <= 1 and count or selected - 1
	self:selectedOption(selected)
	return self
end

return RadioGroup