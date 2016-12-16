local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local Viewer = {}

function Viewer:new(parent, eventViewer)
	o = {_parent = parent, _eventViewer = eventViewer}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Viewer:parent()
	return self._parent
end

function Viewer:app()
	return self:parent():app()
end

function Viewer:isEventViewer()
	return self._eventViewer
end

function Viewer:isMainViewer()
	return not self._eventViewer
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- BROWSER UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Viewer:UI()
	if self:isMainViewer() then
		return self:parent():viewerUI()
	else
		return self:parent():eventViewerUI()
	end
end

function Viewer:isShowing()
	return self:UI() ~= nil
end

function Viewer:show()
	local menuBar = self:app():menuBar()
	-- if the browser is on the secondary, we need to turn it off before enabling in primary
	menuBar:uncheckMenu("Window", "Show in Secondary Display", "Viewers")
	-- Then enable it in the primary
	if self:isEventViewer() then
		menuBar:checkMenu("Window", "Show in Workspace", "Event Viewer")
	end
	return self
end

function Viewer:hide()
	local menuBar = self:app():menuBar()
	-- Only the event viewer can actually be hidden in the primary window
	if self:isEventViewer() then
		-- Uncheck it from the primary workspace
		menuBar:uncheckMenu("Window", "Show in Workspace", "Event Viewer")
	end
	return self
end


return Viewer