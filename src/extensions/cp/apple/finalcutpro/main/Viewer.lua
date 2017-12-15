--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.Viewer ===
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
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")

local PrimaryWindow						= require("cp.apple.finalcutpro.main.PrimaryWindow")
local SecondaryWindow					= require("cp.apple.finalcutpro.main.SecondaryWindow")

local id								= require("cp.apple.finalcutpro.ids") "Viewer"

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
	local o = {
		_app = app,
		_eventViewer = eventViewer
	}

	return prop.extend(o, Viewer)
end

-- TODO: Add documentation
function Viewer:app()
	return self._app
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
Viewer.isEventViewer = prop.new(function(self)
	return self._eventViewer
end):bind(Viewer)

-- TODO: Add documentation
Viewer.isMainViewer = prop.new(function(self)
	return not self._eventViewer
end):bind(Viewer)

-- TODO: Add documentation
Viewer.isOnSecondary = prop.new(function(self)
	local ui = self:UI()
	return ui and SecondaryWindow.matches(ui:window())
end):bind(Viewer)

-- TODO: Add documentation
Viewer.isOnPrimary = prop.new(function(self)
	local ui = self:UI()
	return ui and PrimaryWindow.matches(ui:window())
end):bind(Viewer)

-- TODO: Add documentation
Viewer.isShowing = prop.new(function(self)
	return self:UI() ~= nil
end):bind(Viewer)

-- TODO: Add documentation
function Viewer:showOnPrimary()
	local menuBar = self:app():menuBar()

	-- if it is on the secondary, we need to turn it off before enabling in primary
	if self:isOnSecondary() then
		menuBar:selectMenu({"Window", "Show in Secondary Display", "Viewers"})
	end

	if self:isEventViewer() and not self:isShowing() then
		-- Enable the Event Viewer
		menuBar:selectMenu({"Window", "Show in Workspace", "Event Viewer"})
	end

	return self
end

-- TODO: Add documentation
function Viewer:showOnSecondary()
	local menuBar = self:app():menuBar()

	if not self:isOnSecondary() then
		menuBar:selectMenu({"Window", "Show in Secondary Display", "Viewers"})
	end

	if self:isEventViewer() and not self:isShowing() then
		-- Enable the Event Viewer
		menuBar:selectMenu({"Window", "Show in Workspace", "Event Viewer"})
	end

	return self
end

-- TODO: Add documentation
function Viewer:hide()
	local menuBar = self:app():menuBar()

	if self:isEventViewer() then
		-- Uncheck it from the primary workspace
		if self:isShowing() then
			menuBar:selectMenu({"Window", "Show in Workspace", "Event Viewer"})
		end
	elseif self:isOnSecondary() then
		-- The Viewer can only be hidden from the Secondary Display
		menuBar:selectMenu({"Window", "Show in Secondary Display", "Viewers"})
	end
	return self
end

-- TODO: Add documentation
function Viewer:topToolbarUI()
	return axutils.cache(self, "_topToolbar", function()
		local ui = self:UI()
		return ui and axutils.childFromTop(ui, 1)
	end)
end

-- TODO: Add documentation
function Viewer:bottomToolbarUI()
	return axutils.cache(self, "_bottomToolbar", function()
		local ui = self:UI()
		return ui and axutils.childFromBottom(ui, 1)
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
		return ui and axutils.childFromLeft(ui, id "Format")
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
	local titleText = axutils.childFromLeft(self:topToolbarUI(), id "Title")
	return titleText and titleText:value()
end

return Viewer