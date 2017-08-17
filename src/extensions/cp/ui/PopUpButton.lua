--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.PopUpButton ===
---
--- Pop Up Button Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PopUpButton = {}

-- TODO: Add documentation
function PopUpButton.matches(element)
	return element:attributeValue("AXRole") == "AXPopUpButton"
end

--- cp.ui.PopUpButton:new(axuielement, function) -> PopUpButton
--- Function
--- Creates a new PopUpButton
function PopUpButton:new(parent, finderFn)
	local o = {_parent = parent, _finder = finderFn}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function PopUpButton:parent()
	return self._parent
end

-- TODO: Add documentation
function PopUpButton:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end,
	PopUpButton.matches)
end

-- TODO: Add documentation
function PopUpButton:selectItem(index)
	local ui = self:UI()
	if ui then
		local items = ui:doPress()[1]
		if items then
			local item = items[index]
			if item then
				-- select the menu item
				item:doPress()
			else
				-- close the menu again
				items:doCancel()
			end
		end
	end
	return self
end

-- TODO: Add documentation
function PopUpButton:getValue()
	local ui = self:UI()
	return ui and ui:value()
end

-- TODO: Add documentation
function PopUpButton:setValue(value)
	local ui = self:UI()
	if ui and not ui:value() == value then
		local items = ui:doPress()[1]
		for i,item in items do
			if item:title() == value then
				item:doPress()
				return
			end
		end
		items:doCancel()
	end
	return self
end

-- TODO: Add documentation
function PopUpButton:isEnabled()
	local ui = self:UI()
	return ui and ui:enabled()
end

-- TODO: Add documentation
function PopUpButton:press()
	local ui = self:UI()
	if ui then
		ui:doPress()
	end
	return self
end

-- TODO: Add documentation
function PopUpButton:saveLayout()
	local layout = {}
	layout.value = self:getValue()
	return layout
end

-- TODO: Add documentation
function PopUpButton:loadLayout(layout)
	if layout then
		self:setValue(layout.value)
	end
end

return PopUpButton
