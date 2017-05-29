--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.Alert ===
---
--- Alert UI Module.

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
local Alert = {}

-- TODO: Add documentation
function Alert.matches(element)
	if element then
		return element:attributeValue("AXRole") == "AXSheet"
	end
	return false
end

-- TODO: Add documentation
function Alert:new(parent)
	local o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function Alert:parent()
	return self._parent
end

-- TODO: Add documentation
function Alert:app()
	return self:parent():app()
end

-- TODO: Add documentation
function Alert:UI()
	return axutils.cache(self, "_ui", function()
		axutils.childMatching(self:parent():UI(), Alert.matches)
	end,
	Alert.matches)
end

-- TODO: Add documentation
function Alert:isShowing()
	return self:UI() ~= nil
end

-- TODO: Add documentation
function Alert:hide()
	self:pressCancel()
end

-- TODO: Add documentation
function Alert:pressCancel()
	local ui = self:UI()
	if ui then
		local btn = ui:cancelButton()
		if btn then
			btn:doPress()
		end
	end
	return self
end

-- TODO: Add documentation
function Alert:pressDefault()
	local ui = self:UI()
	if ui then
		local btn = ui:defaultButton()
		if btn and btn:enabled() then
			btn:doPress()
		end
	end
	return self
end

-- TODO: Add documentation
function Alert:getTitle()
	local ui = self:UI()
	return ui and ui:title()
end

return Alert