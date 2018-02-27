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

local canvas							= require("hs.canvas")
local geometry							= require("hs.geometry")

local prop								= require("cp.prop")

local axutils							= require("cp.ui.axutils")
local Button							= require("cp.ui.Button")

local PrimaryWindow						= require("cp.apple.finalcutpro.main.PrimaryWindow")
local SecondaryWindow					= require("cp.apple.finalcutpro.main.SecondaryWindow")

local id								= require("cp.apple.finalcutpro.ids") "Viewer"

local floor								= math.floor

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

--- cp.apple.finalcutpro.main.Viewer:togglePlaying() -> self
--- Method
--- Toggles if the viewer is playing.
--- If there is nothing available to play, this will have no effect.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Viewer` instance.
function Viewer:togglePlaying()
	self:playButton():press()
	return self
end

-- pixelsFromWindowCanvas(hsWindow, centerPixel) -> hs.image, hs.image
-- Function
-- Extracts two 2x2 pixel images from the screenshot of the image, centred
-- on the `centerPixel`. The first is the pixel in the centre, the second is offset by 2 pixels to the left
--
-- Parameters:
-- * hsWindow		- The `hs.window` having pixels pulled
-- * centerPixel	- The pixel to to retrieve (and offset)
--
-- Returns:
-- * Two `hs.images`, the first being the center pixel, the second being offset by 2px left.
local function pixelsFromWindowCanvas(hsWindow, centerPixel)
	local centerShot, offShot = nil, nil
	local windowShot = hsWindow:snapshot()
	if windowShot then
		-- log.df("windowShot:size(): %s", hs.inspect(windowShot:size()))
		local windowFrame = hsWindow:frame()
		local shotSize = windowShot:size()
		local ratio = shotSize.h/windowFrame.h

		-- log.df("windowFrame: %s", hs.inspect(windowFrame))
		local imagePixel = {
			x = (windowFrame.x-centerPixel.x)*ratio,
			y = (windowFrame.y-centerPixel.y)*ratio,
			w = shotSize.w,
			h = shotSize.h,
		}

		-- local c = canvas.new({w=1,h=1})
		local c = canvas.new({w=1, h=1})
		c[1] = {
			type = "image",
			image = windowShot,
			imageScaling = "none",
			imageAlignment = "topLeft",
			frame = imagePixel,
		}

		centerShot = c:imageFromCanvas()

		-- shift left
		c[1].frame.x = imagePixel.x+2
		offShot = c:imageFromCanvas()
	end
	return centerShot, offShot
end

--- cp.apple.finalcut.main.Viewer.isPlaying <cp.prop: boolean>
--- Field
--- The 'playing' status of the viewer. If true, it is playing, if not it is paused.
--- This can be set via `viewer:isPlaying(true|false)`, or toggled via `viewer.isPlaying:toggle()`.
Viewer.isPlaying = prop(
	function(self)
		local playButton = self:playButton()
		local frame = playButton:frame()
		if frame then
			frame = geometry.new(frame)
			local center = frame.center
			local centerPixel = {x=floor(center.x), y=floor(center.y), w=1, h=1}
			-- log.df("centerPixel = %s", hs.inspect(centerPixel))

			local window = self:currentWindow()
			local hsWindow = window:hsWindow()

			-----------------------------------------------------------------------
			-- Save a snapshot:
			-----------------------------------------------------------------------
			local centerShot, offShot = pixelsFromWindowCanvas(hsWindow, centerPixel)

			if centerShot then

				-----------------------------------------------------------------------
				-- Get the snapshots as encoded URL strings:
				-----------------------------------------------------------------------
				local centerString = centerShot:encodeAsURLString()
				local offString = offShot:encodeAsURLString()

				-----------------------------------------------------------------------
				-- Compare to hardcoded version
				-----------------------------------------------------------------------
				if centerString ~= offString then
					return true
				end
			else
				log.ef("Unable to snapshot the play button.")
			end
		end
		return false
	end,
	function(newValue, self, thisProp)
		local value = thisProp:value()
		if newValue ~= value then
			self:playButton():press()
		end
	end
):bind(Viewer)

return Viewer