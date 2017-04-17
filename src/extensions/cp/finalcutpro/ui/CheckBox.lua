--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.finalcutpro.ui.CheckBox ===
---
--- Check Box UI Module.

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
local CheckBox = {}

-- TODO: Add documentation
function CheckBox.matches(element)
	return element:attributeValue("AXRole") == "AXCheckBox"
end

--- cp.finalcutpro.ui.CheckBox:new(axuielement, function) -> CheckBox
--- Function
--- Creates a new CheckBox
function CheckBox:new(parent, finderFn)
	o = {_parent = parent, _finder = finderFn}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function CheckBox:parent()
	return self._parent
end

-- TODO: Add documentation
function CheckBox:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end,
	CheckBox.matches)
end

-- TODO: Add documentation
function CheckBox:isChecked()
	local ui = self:UI()
	return ui and ui:value() == 1
end

-- TODO: Add documentation
function CheckBox:check()
	local ui = self:UI()
	if ui and ui:value() == 0 then
		ui:doPress()
	end
	return self
end

-- TODO: Add documentation
function CheckBox:uncheck()
	local ui = self:UI()
	if ui and ui:value() == 1 then
		ui:doPress()
	end
	return self
end

-- TODO: Add documentation
function CheckBox:toggle()
	local ui = self:UI()
	if ui then
		ui:doPress()
	end
	return self
end

-- TODO: Add documentation
function CheckBox:isEnabled()
	local ui = self:UI()
	return ui and ui:enabled()
end

-- TODO: Add documentation
function CheckBox:press()
	local ui = self:UI()
	if ui then
		ui:doPress()
	end
	return self
end

-- TODO: Add documentation
function CheckBox:saveLayout()
	return {
		checked = self:isChecked()
	}
end

-- TODO: Add documentation
function CheckBox:loadLayout(layout)
	if layout then
		if layout.checked then
			self:check()
		else
			self:uncheck()
		end
	end
end

return CheckBox