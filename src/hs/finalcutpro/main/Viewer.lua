local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local Viewer = {}


function Viewer.isViewer(element)
	-- Viewers have a single 'AXContents' element
	local contents = element:attributeValue("AXContents")
	return contents and #contents == 1 
	   and contents[1]:attributeValue("AXRole") == "AXSplitGroup"
	   and #(contents[1]) > 0
end

function Viewer:new(parent, eventViewer, secondary)
	o = {
		_parent = parent, 
		_eventViewer = eventViewer,
		_secondary = secondary
	}
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

function Viewer:isOnSecondaryWindow()
	return self._secondary
end

function Viewer:isOnPrimaryWindow()
	return not self._secondary
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- BROWSER UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Viewer:UI()
	if self:isMainViewer() then
		return self:viewerUI()
	else
		return self:eventViewerUI()
	end
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- VIEWER UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Viewer:viewerUI()
	local top = self:parent():viewerGroupUI()
	local ui = nil
	if top then
		for i,child in ipairs(top) do
			-- There can be two viwers enabled
			if Viewer.isViewer(child) then
				-- Both the event viewer and standard viewer have the ID, so pick the right-most one
				if ui == nil or ui:position().x < child:position().x then
					ui = child
				end
			end
		end
	end
	return ui
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- EVENT VIEWER UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Viewer:eventViewerUI()
	local top = self:parent():viewerGroupUI()
	local ui = nil
	local viewerCount = 0
	for i,child in ipairs(top) do
		-- There can be two viwers enabled
		if Viewer.isViewer(child) then
			viewerCount = viewerCount + 1
			-- Both the event viewer and standard viewer have the ID, so pick the left-most one
			if ui == nil or ui:position().x > child:position().x then
				ui = child
			end
		end
	end
	-- Can only be the event viewer if there are two viewers.
	if viewerCount == 2 then
		return ui
	else
		return nil
	end
end


function Viewer:isShowing()
	return self:UI() ~= nil
end

function Viewer:show()
	local menuBar = self:app():menuBar()
	
	if self:isOnPrimaryWindow() then
		-- if the browser is on the secondary, we need to turn it off before enabling in primary
		menuBar:uncheckMenu("Window", "Show in Secondary Display", "Viewers")
	else
		menuBar:checkMenu("Window", "Show in Secondary Display", "Viewers")
	end
	
	if self:isEventViewer() then
		-- Enable the Event Viewer
		menuBar:checkMenu("Window", "Show in Workspace", "Event Viewer")
	end
	
	return self
end

function Viewer:hide()
	local menuBar = self:app():menuBar()
	
	if self:isEventViewer() then
		-- Uncheck it from the primary workspace
		menuBar:uncheckMenu("Window", "Show in Workspace", "Event Viewer")
	elseif self:isOnSecondaryWindow() then
		-- The Viewer can only be hidden from the Secondary Display
		menuBar:uncheckMenu("Window", "Show in Secondary Display", "Viewers")
	end
	return self
end


return Viewer