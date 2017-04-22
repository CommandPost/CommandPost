--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.export.ReplaceAlert ===
---
--- Replace Alert

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local axutils						= require("cp.apple.finalcutpro.axutils")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ReplaceAlert = {}

-- TODO: Add documentation
function ReplaceAlert.matches(element)
	if element then
		return element:attributeValue("AXRole") == "AXSheet"			-- it's a sheet
		   and axutils.childWithRole(element, "AXTextField") == nil 	-- with no text fields
	end
	return false
end

-- TODO: Add documentation
function ReplaceAlert:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function ReplaceAlert:parent()
	return self._parent
end

-- TODO: Add documentation
function ReplaceAlert:app()
	return self:parent():app()
end

-- TODO: Add documentation
function ReplaceAlert:UI()
	return axutils.cache(self, "_ui", function()
		return axutils.childMatching(self:parent():UI(), ReplaceAlert.matches)
	end,
	ReplaceAlert.matches)
end

-- TODO: Add documentation
function ReplaceAlert:isShowing()
	return self:UI() ~= nil
end

-- TODO: Add documentation
function ReplaceAlert:hide()
	self:pressCancel()
end

-- TODO: Add documentation
function ReplaceAlert:pressCancel()
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
function ReplaceAlert:pressReplace()
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
function ReplaceAlert:getTitle()
	local ui = self:UI()
	return ui and ui:title()
end

return ReplaceAlert