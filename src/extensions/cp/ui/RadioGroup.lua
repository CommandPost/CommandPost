--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.RadioGroup ===
---
--- RadioGroup Module.

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

-- TODO: Add documentation
function RadioGroup.matches(element)
	return element and element:attributeValue("AXRole") == "AXRadioGroup"
end

--- cp.ui.RadioGroup:new(axuielement, table) -> RadioGroup
--- Function
--- Creates a new RadioGroup
function RadioGroup:new(parent, finderFn)
	local o = prop.extend({
		_parent = parent,
		_finder = finderFn
	}, RadioGroup)
	return o
end

-- TODO: Add documentation
function RadioGroup:parent()
	return self._parent
end

function RadioGroup:isShowing()
	return self:UI() ~= nil and self:parent():isShowing()
end

-- TODO: Add documentation
function RadioGroup:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end,
	RadioGroup.matches)
end

-- TODO: Add documentation
function RadioGroup:isEnabled()
	local ui = self:UI()
	return ui and ui:enabled()
end

RadioGroup.itemCount = prop(
	function(self)
		local ui = self:UI()
		return ui and #ui or 0
	end
):bind(RadioGroup)

RadioGroup.selectedItem = prop(
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

return RadioGroup