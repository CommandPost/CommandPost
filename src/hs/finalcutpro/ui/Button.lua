local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local axutils						= require("hs.finalcutpro.axutils")

local Button = {}

--- hs.finalcutpro.ui.Button:new(axuielement, table) -> Button
--- Function:
--- Creates a new Button
function Button:new(parent, id)
	o = {_parent = parent, _id = id}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Button:parent()
	return self._parent
end

function Button:UI()
	local parentUI = self:parent():UI()
	if self._id.attribute then
		return parentUI:attributeValue(self._id.attribute)
	elseif self._id.subrole then
		return axutils.childWith(parentUI, "AXSubrole", self._id.subrole)
	else
		return nil
	end
end

function Button:isEnabled()
	return self:UI():enabled()
end

function Button:press()
	return self:UI():doPress()
end

return Button