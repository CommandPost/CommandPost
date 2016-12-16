local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local Inspector = {}

Inspector.ID = 2

function Inspector:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Inspector:parent()
	return self._parent
end

function Inspector:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- Inspector UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Inspector:UI()
	return self:parent():inspectorUI()
end

function Inspector:isShowing()
	return self:UI() ~= nil
end

function Inspector:show()
	local parent = self:parent()
	-- show the parent.
	if parent:show() then
		local menuBar = self:app():menuBar()
		-- Enable it in the primary
		menuBar:checkMenu("Window", "Show in Workspace", "Inspector")
		return true
	end
	return false
end


function Inspector:hide()
	local menuBar = self:app():menuBar()
	-- Uncheck it from the primary workspace
	menuBar:uncheckMenu("Window", "Show in Workspace", "Inspector")
	return true
end


return Inspector