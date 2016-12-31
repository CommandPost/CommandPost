local axutils						= require("hs.finalcutpro.axutils")

local PopUpButton = {}

function PopUpButton.matches(element)
	return element:attributeValue("AXRole") == "AXPopUpButton"
end

--- hs.finalcutpro.ui.PopUpButton:new(axuielement, function) -> PopUpButton
--- Function:
--- Creates a new PopUpButton
function PopUpButton:new(parent, finderFn)
	o = {_parent = parent, _finder = finderFn}
	setmetatable(o, self)
	self.__index = self
	return o
end

function PopUpButton:parent()
	return self._parent
end

function PopUpButton:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end,
	PopUpButton.matches)
end

function PopUpButton:selectItem(index)
	local ui = self:UI()
	if ui then
		local items = ui:doPress()[1]
		local item = items[index]
		if item then
			-- select the menu item
			item:doPress()
		else
			-- close the menu again
			items:doCancel()
		end
	end
	return self
end

function PopUpButton:isEnabled()
	local ui = self:UI()
	return ui and ui:enabled()
end

function PopUpButton:press()
	local ui = self:UI()
	if ui then
		ui:doPress()
	end
	return self
end

return PopUpButton