--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.finalcutpro.ui.Button ===
---
--- Button Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("button")
local inspect						= require("hs.inspect")

local axutils						= require("cp.finalcutpro.axutils")

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

--- cp.finalcutpro.ui.Button:new(axuielement, table) -> Button
--- Function
--- Creates a new Button
function Button:new(parent, finderFn)
	o = {_parent = parent, _finder = finderFn}
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

-- TODO: Add documentation
function Button:isEnabled()
	return self:UI():enabled()
end

-- TODO: Add documentation
function Button:press()
	self:UI():doPress()
	return self
end

return Button