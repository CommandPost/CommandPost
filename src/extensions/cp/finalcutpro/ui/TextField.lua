--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.finalcutpro.ui.TextField ===
---
--- Text Field Module.

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
local TextField = {}

-- TODO: Add documentation
function TextField.matches(element)
	return element:attributeValue("AXRole") == "AXTextField"
end

--- cp.finalcutpro.ui.TextField:new(axuielement, function) -> TextField
--- Function
--- Creates a new TextField
function TextField:new(parent, finderFn)
	o = {_parent = parent, _finder = finderFn}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function TextField:parent()
	return self._parent
end

-- TODO: Add documentation
function TextField:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end,
	TextField.matches)
end

-- TODO: Add documentation
function TextField:isShowing()
	return self:UI() ~= nil and self:parent():isShowing()
end

-- TODO: Add documentation
function TextField:getValue()
	local ui = self:UI()
	return ui and ui:attributeValue("AXValue")
end

-- TODO: Add documentation
function TextField:setValue(value)
	local ui = self:UI()
	if ui then
		ui:setAttributeValue("AXValue", value)
		ui:performAction("AXConfirm")
	end
	return self
end

-- TODO: Add documentation
function TextField:clear()
	self:setValue("")
end

-- TODO: Add documentation
function TextField:isEnabled()
	local ui = self:UI()
	return ui and ui:enabled()
end

-- TODO: Add documentation
function TextField:saveLayout()
	local layout = {}
	layout.value = self:getValue()
	return layout
end

-- TODO: Add documentation
function TextField:loadLayout(layout)
	if layout then
		self:setValue(layout.value)
	end
end

return TextField