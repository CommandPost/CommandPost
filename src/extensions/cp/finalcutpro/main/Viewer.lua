--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.finalcutpro.main.Viewer ===
---
--- Viewer Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("viewer")
local inspect							= require("hs.inspect")

local just								= require("cp.just")
local axutils							= require("cp.finalcutpro.axutils")

local PrimaryWindow						= require("cp.finalcutpro.main.PrimaryWindow")
local SecondaryWindow					= require("cp.finalcutpro.main.SecondaryWindow")

local id								= require("cp.finalcutpro.ids") "Viewer"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Viewer = {}

-- TODO: Add documentation
function Viewer.matches(element)
	-- Viewers have a single 'AXContents' element
	local contents = element:attributeValue("AXContents")
	return contents and #contents == 1
	   and contents[1]:attributeValue("AXRole") == "AXSplitGroup"
	   and #(contents[1]) > 0
end

-- TODO: Add documentation
function Viewer:new(app, eventViewer)
	o = {
		_app = app,
		_eventViewer = eventViewer
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function Viewer:app()
	return self._app
end

-- TODO: Add documentation
function Viewer:isEventViewer()
	return self._eventViewer
end

-- TODO: Add documentation
function Viewer:isMainViewer()
	return not self._eventViewer
end

-- TODO: Add documentation
function Viewer:isOnSecondary()
	local ui = self:UI()
	return ui and SecondaryWindow.matches(ui:window())
end

-- TODO: Add documentation
function Viewer:isOnPrimary()
	local ui = self:UI()
	return ui and PrimaryWindow.matches(ui:window())
end

-----------------------------------------------------------------------
--
-- BROWSER UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Viewer:UI()
	return axutils.cache(self, "_ui", function()
		local app = self:app()
		if self:isMainViewer() then
			return self:findViewerUI(app:secondaryWindow(), app:primaryWindow())
		else
			return self:findEventViewerUI(app:secondaryWindow(), app:primaryWindow())
		end
	end,
	Viewer.matches)
end

-----------------------------------------------------------------------
--
-- VIEWER UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Viewer:findViewerUI(...)
	for i = 1,select("#", ...) do
		local window = select(i, ...)
		if window then
			local top = window:viewerGroupUI()
			local ui = nil
			if top then
				for i,child in ipairs(top) do
					-- There can be two viwers enabled
					if Viewer.matches(child) then
						-- Both the event viewer and standard viewer have the ID, so pick the right-most one
						if ui == nil or ui:position().x < child:position().x then
							ui = child
						end
					end
				end
			end
			if ui then return ui end
		end
	end
	return nil
end

-----------------------------------------------------------------------
--
-- EVENT VIEWER UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Viewer:findEventViewerUI(...)
	for i = 1,select("#", ...) do
		local window = select(i, ...)
		if window then
			local top = window:viewerGroupUI()
			local ui = nil
			local viewerCount = 0
			if top then
				for i,child in ipairs(top) do
					-- There can be two viwers enabled
					if Viewer.matches(child) then
						viewerCount = viewerCount + 1
						-- Both the event viewer and standard viewer have the ID, so pick the left-most one
						if ui == nil or ui:position().x > child:position().x then
							ui = child
						end
					end
				end
			end
			-- Can only be the event viewer if there are two viewers.
			if viewerCount == 2 then
				return ui
			end
		end
	end
	return nil
end

-- TODO: Add documentation
function Viewer:isShowing()
	return self:UI() ~= nil
end

-- TODO: Add documentation
function Viewer:showOnPrimary()
	local menuBar = self:app():menuBar()

	-- if the browser is on the secondary, we need to turn it off before enabling in primary
	menuBar:uncheckMenu("Window", "Show in Secondary Display", "Viewers")

	if self:isEventViewer() then
		-- Enable the Event Viewer
		menuBar:checkMenu("Window", "Show in Workspace", "Event Viewer")
	end

	return self
end

-- TODO: Add documentation
function Viewer:showOnSecondary()
	local menuBar = self:app():menuBar()

	menuBar:checkMenu("Window", "Show in Secondary Display", "Viewers")

	if self:isEventViewer() then
		-- Enable the Event Viewer
		menuBar:checkMenu("Window", "Show in Workspace", "Event Viewer")
	end

	return self
end

-- TODO: Add documentation
function Viewer:hide()
	local menuBar = self:app():menuBar()

	if self:isEventViewer() then
		-- Uncheck it from the primary workspace
		menuBar:uncheckMenu("Window", "Show in Workspace", "Event Viewer")
	elseif self:isOnSecondary() then
		-- The Viewer can only be hidden from the Secondary Display
		menuBar:uncheckMenu("Window", "Show in Secondary Display", "Viewers")
	end
	return self
end

-- TODO: Add documentation
function Viewer:topToolbarUI()
	return axutils.cache(self, "_topToolbar", function()
		local ui = self:UI()
		if ui then
			for i,child in ipairs(ui) do
				if axutils.childWith(child, "AXIdentifier", id "Title") then
					return child
				end
			end
		end
		return nil
	end)
end

-- TODO: Add documentation
function Viewer:bottomToolbarUI()
	return axutils.cache(self, "_bottomToolbar", function()
		local ui = self:UI()
		if ui then
			for i,child in ipairs(ui) do
				if _highlight(axutils.childWith(child, "AXIdentifier", id "Timecode")) then
					return child
				end
			end
		end
		return nil
	end)
end

-- TODO: Add documentation
function Viewer:hasPlayerControls()
	return self:bottomToolbarUI() ~= nil
end

-- TODO: Add documentation
function Viewer:formatUI()
	return axutils.cache(self, "_format", function()
		local ui = self:topToolbarUI()
		return ui and axutils.childWith(ui, "AXIdentifier", id "Format")
	end)
end

-- TODO: Add documentation
function Viewer:getFormat()
	local format = self:formatUI()
	return format and format:value()
end

-- TODO: Add documentation
function Viewer:getFramerate()
	local format = self:getFormat()
	local framerate = format and string.match(format, ' %d%d%.?%d?%d?[pi]')
	return framerate and tonumber(string.sub(framerate, 1,-2))
end

-- TODO: Add documentation
function Viewer:getTitle()
	local titleText = axutils.childWithID(self:topToolbarUI(), id "Title")
	return titleText and titleText:value()
end

return Viewer