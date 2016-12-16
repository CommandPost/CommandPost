local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local Playhead = {}

function Playhead:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Playhead:parent()
	return self._parent
end

function Playhead:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- BROWSER UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Playhead:UI()
	local ui = self:parent():UI()
	if ui then
		return axutils.childWith(ui, "AXRole", "AXValueIndicator")
	end
	return nil
end

function Playhead:isShowing()
	return self:UI() ~= nil
end

function Playhead:show()
	local parent = self:parent()
	-- show the parent.
	if parent:show() then
		-- ensure the playhead is visible
		-- TODO
	end
	return self
end

function Playhead:hide()
	return self:parent():hide()
end

function Playhead:getTimecode()
	local ui = self:UI()
	return ui and ui:attributeValue("AXValue")
end

return Playhead