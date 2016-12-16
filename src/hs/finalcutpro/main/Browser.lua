local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local Browser = {}

Browser.ID = 2

function Browser:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Browser:parent()
	return self._parent
end

function Browser:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- BROWSER UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Browser:UI()
	return self:parent():browserUI()
end

function Browser:isShowing()
	return self:UI() ~= nil
end

function Browser:show()
	local parent = self:parent()
	-- show the parent.
	if parent:show() then
		local menuBar = self:app():menuBar()
		if menuBar:isChecked("Window", "Show in Secondary Display", "Browser") then
			menuBar:selectMenu("Window", "Show in Secondary Display", "Browser")
		else
			menuBar:checkMenu("Window", "Show in Secondary Display", "Browser")
		end
	end
	return false
end

return Browser