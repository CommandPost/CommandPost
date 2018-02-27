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

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("viewer")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local canvas                            = require("hs.canvas")
local inspect							= require("hs.inspect")
local screen                            = require("hs.screen")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils							= require("cp.ui.axutils")
local Button                            = require("cp.ui.Button")
local id								= require("cp.apple.finalcutpro.ids") "Viewer"
local just								= require("cp.just")
local PrimaryWindow						= require("cp.apple.finalcutpro.main.PrimaryWindow")
local prop								= require("cp.prop")
local SecondaryWindow					= require("cp.apple.finalcutpro.main.SecondaryWindow")

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

-- TODO: Add documentation
function Viewer:playButton()
    if not self._playButton then
        self._playButton = Button:new(self, function()
            local buttons = axutils.childrenWithRole(self:bottomToolbarUI(), "AXButton")
            return buttons and buttons[2]
        end)
    end
    return self._playButton
end

-- TODO: Add documentation
function Viewer:isPlaying()
    local playButton = self:playButton()
    local playButtonUI = playButton:UI()
    local playButtonFrame = playButton and playButton:frame()
    if playButtonUI and playButtonFrame then

        -----------------------------------------------------------------------
        -- Get Parent Window AX Object:
        -----------------------------------------------------------------------
        local parentWindow = playButtonUI
        while parentWindow:attributeValue("AXRole") ~= "AXWindow" do
            parentWindow = parentWindow:attributeValue("AXParent")
        end

        -----------------------------------------------------------------------
        -- Get hs.window object:
        -----------------------------------------------------------------------
        local playButtonWindow = parentWindow:asHSWindow()

        -----------------------------------------------------------------------
        -- Get hs.screen object:
        -----------------------------------------------------------------------
        local playButtonScreen = playButtonWindow:screen()

        -----------------------------------------------------------------------
        -- Save a snapshot:
        -----------------------------------------------------------------------
        local snapshot = playButtonScreen:snapshot(playButtonFrame)

        -----------------------------------------------------------------------
        -- Process the snapshot:
        -----------------------------------------------------------------------
        local a = canvas.new{x = 0, y = 0, w = 30, h = 30 }
        a[1] = {
          type="image",
          image = snapshot,
          frame = { x = 0, y = 0, h = "100%", w = "100%" },
        }

        -----------------------------------------------------------------------
        -- TODO: Make the snapshot B&W and transparent:
        -----------------------------------------------------------------------
        --[[
        a[2] = {
          type = "rectangle",
          action = "fill",
          fillColor = { white = 1 },
          compositeRule = "sourceAtop",
        }
        --]]
        local newImage = a:imageFromCanvas()

        -----------------------------------------------------------------------
        -- Get the snapshot as an encoded URL string:
        -----------------------------------------------------------------------
        local urlString = newImage:encodeAsURLString()

        -----------------------------------------------------------------------
        -- Processed Play Icon:
        -----------------------------------------------------------------------
        local playIcon = [[data:image/png;base64,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]]

        -----------------------------------------------------------------------
        -- Check to see if current snapshot matches above snapshot:
        -----------------------------------------------------------------------
        if urlString ~= playIcon then
            return true
        end

    end
    return false
end

return Viewer