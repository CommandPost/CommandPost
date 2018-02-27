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

local geometry							= require("hs.geometry")

local prop								= require("cp.prop")

local axutils							= require("cp.ui.axutils")
local Button							= require("cp.ui.Button")

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


-----------------------------------------------------------------------
--
-- VIEWER UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
local function findViewerUI(...)
	for i = 1,select("#", ...) do
		local window = select(i, ...)
		if window then
			local top = window:viewerGroupUI()
			local ui = nil
			if top then
				for _,child in ipairs(top) do
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
local function findEventViewerUI(...)
	for i = 1,select("#", ...) do
		local window = select(i, ...)
		if window then
			local top = window:viewerGroupUI()
			local ui = nil
			local viewerCount = 0
			if top then
				for _,child in ipairs(top) do
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
function Viewer:UI()
	return axutils.cache(self, "_ui", function()
		local app = self:app()
		if self:isMainViewer() then
			return findViewerUI(app:secondaryWindow(), app:primaryWindow())
		else
			return findEventViewerUI(app:secondaryWindow(), app:primaryWindow())
		end
	end,
	Viewer.matches)
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
function Viewer:currentWindow()
	if self:isOnSecondary() then
		return self:app():secondaryWindow()
	else
		return self:app():primaryWindow()
	end
end

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

-- TODO: Add documentation
function Viewer:playButton()
    if not self._playButton then
		self._playButton = Button:new(self, function()
            return axutils.childFromLeft(axutils.childrenWithRole(self:bottomToolbarUI(), "AXButton"), 1)
        end)
    end
    return self._playButton
end

function Viewer:playPause()
	self:playButton():press()
	return self
end

-- hardcoded playing icon pixel
local PLAYING_PIXEL = [[data:image/png;base64,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]]

function Viewer:isPlaying()
    local playButton = self:playButton()
    local frame = playButton:frame()
	if frame then
		frame = geometry.new(frame)
		local center = frame.center
		local centerPixel = {x=center.x, y=center.y, w=1, h=1}
		-- local centerPixel = frame

		local window = self:currentWindow()

		local screen = window:hsWindow():screen()
		local screenPixel = screen:absoluteToLocal(centerPixel)

        -----------------------------------------------------------------------
        -- Save a snapshot:
        -----------------------------------------------------------------------
		local snapshot = screen:snapshot(screenPixel)

		if snapshot then
			-----------------------------------------------------------------------
			-- Get the snapshot as an encoded URL string:
			-----------------------------------------------------------------------
			local urlString = snapshot:encodeAsURLString()

			-----------------------------------------------------------------------
			-- Compare to hardcoded version
			-----------------------------------------------------------------------
			if urlString == PLAYING_PIXEL then
				return true
			end
		else
			log.ef("Unable to snapshot the play button.")
		end

    end
    return false
end

return Viewer