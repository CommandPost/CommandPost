--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.finalcutpro.ui.RadioButton ===
---
--- Radio Button Module.

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
local RadioButton = {}

-- TODO: Add documentation
function RadioButton.matches(element)
	return element:attributeValue("AXRole") == "AXRadioButton"
end

--- cp.finalcutpro.ui.RadioButton:new(axuielement, function) -> RadioButton
--- Function
--- Creates a new RadioButton
function RadioButton:new(parent, finderFn)
	o = {_parent = parent, _finder = finderFn}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function RadioButton:parent()
	return self._parent
end

-- TODO: Add documentation
function RadioButton:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end,
	RadioButton.matches)
end

-- TODO: Add documentation
function RadioButton:isChecked()
	local ui = self:UI()
	return ui and ui:value() == 1
end

-- TODO: Add documentation
function RadioButton:check()
	local ui = self:UI()
	if ui and ui:value() == 0 then
		ui:doPress()
	end
	return self
end

-- TODO: Add documentation
function RadioButton:uncheck()
	local ui = self:UI()
	if ui and ui:value() == 1 then
		ui:doPress()
	end
	return self
end

-- TODO: Add documentation
function RadioButton:toggle()
	local ui = self:UI()
	if ui then
		ui:doPress()
	end
	return self
end

-- TODO: Add documentation
function RadioButton:isEnabled()
	local ui = self:UI()
	return ui and ui:enabled()
end

-- TODO: Add documentation
function RadioButton:press()
	local ui = self:UI()
	if ui then
		ui:doPress()
	end
	return self
end

-- TODO: Add documentation
function RadioButton:saveLayout()
	return {
		checked = self:isChecked()
	}
end

-- TODO: Add documentation
function RadioButton:loadLayout(layout)
	if layout then
		if layout.checked then
			self:check()
		else
			self:uncheck()
		end
	end
end

return RadioButton