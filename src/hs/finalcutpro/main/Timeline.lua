local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("hs.just")
local axutils							= require("hs.finalcutpro.axutils")

local TimelineContent					= require("hs.finalcutpro.main.TimelineContent")

local Timeline = {}

function Timeline.isTimeline(element)
	return element:attributeValue("AXRole") == "AXGroup"
end

function Timeline:new(parent, secondary)
	o = {_parent = parent, _secondary = secondary}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Timeline:parent()
	return self._parent
end

function Timeline:app()
	return self:parent():app()
end

function Timeline:isOnSecondaryWindow()
	return self._secondary
end

function Timeline:isOnPrimaryWindow()
	return not self._secondary
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- TIMELINE UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Timeline:UI()
	local top = self:parent():timelineGroupUI()
	if top then
		for i,child in ipairs(top) do
			if Timeline.isTimeline(child) then
				return child
			end
		end
	end
	return nil
end

function Timeline:isShowing()
	return self:UI() ~= nil
end

function Timeline:show()
	local menuBar = self:app():menuBar()
	
	if self:isOnPrimaryWindow() then
		-- if the timeline is on the secondary, we need to turn it off before enabling in primary
		menuBar:uncheckMenu("Window", "Show in Secondary Display", "Timeline")
		-- Then enable it in the primary
		menuBar:checkMenu("Window", "Show in Workspace", "Timeline")
	else
		menuBar:checkMenu("Window", "Show in Secondary Display", "Timeline")
	end

	return self
end

function Timeline:hide()
	local menuBar = self:app():menuBar()
	-- Uncheck it from the primary workspace
	menuBar:uncheckMenu("Window", "Show in Secondary Display", "Timeline")
	menuBar:uncheckMenu("Window", "Show in Workspace", "Timeline")
	return self
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- MAIN UI
--- The Canvas is the main body of the timeline, containing the
--- Timeline Index, the canvas, and the Effects/Transitions panels.
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Timeline:mainUI()
	local ui = self:UI()
	if ui then
		for i,child in ipairs(ui) do
			if self:_isMain(child) then
				return child
			end
		end
	end
	return nil
end

function Timeline:_isMain(element)
	return element:attributeValue("AXIdentifier") == "_NS:237"
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- CONTENT UI
--- The Content is the main body of the timeline, containing the
--- Timeline Index, the Content, and the Effects/Transitions panels.
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Timeline:content()
	if not self._content then
		self._content = TimelineContent:new(self)
	end
	return self._content
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- MAIN UI
--- The Canvas is the main body of the timeline, containing the
--- Timeline Index, the canvas, and the Effects/Transitions panels.
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function Timeline:toolbarUI()
	local ui = self:UI()
	if ui then
		for i,child in ipairs(ui) do
			if not self:_isMain(child) then
				return child
			end
		end
	end
	return nil
end

return Timeline