--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.Button ===
---
--- Button Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
-- local log							= require("hs.logger").new("button")

local axutils						= require("cp.ui.axutils")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Button = {}

-- TODO: Add documentation
function Button.matches(element)
	return element and element:attributeValue("AXRole") == "AXButton"
end

--- cp.ui.Button:new(axuielement, table) -> Button
--- Function
--- Creates a new Button
function Button:new(parent, finderFn)
	local o = {_parent = parent, _finder = finderFn}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function Button:parent()
	return self._parent
end

function Button:isShowing()
	return self:UI() ~= nil and self:parent():isShowing()
end

-- TODO: Add documentation
function Button:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end,
	Button.matches)
end

function Button:frame()
	local ui = self:UI()
	return ui and ui:frame() or nil
end

-- TODO: Add documentation
function Button:isEnabled()
	local ui = self:UI()
	return ui and ui:enabled()
end

-- TODO: Add documentation
function Button:press()
	local ui = self:UI()
	if ui then ui:doPress() end
	return self
end

-- TODO: Add documentation
function Button:frame()
    local ui = self:UI()
    return ui and ui:attributeValue("AXFrame")
end

return Button