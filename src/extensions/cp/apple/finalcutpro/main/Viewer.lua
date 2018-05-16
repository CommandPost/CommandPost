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
local log                               = require("hs.logger").new("viewer")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local canvas                            = require("hs.canvas")
local geometry                          = require("hs.geometry")
local delayedTimer                      = require("hs.timer").delayed

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                           = require("cp.ui.axutils")
local Button                            = require("cp.ui.Button")
local StaticText                        = require("cp.ui.StaticText")

local PrimaryWindow                     = require("cp.apple.finalcutpro.main.PrimaryWindow")
local prop                              = require("cp.prop")
local SecondaryWindow                   = require("cp.apple.finalcutpro.main.SecondaryWindow")

local id                                = require("cp.apple.finalcutpro.ids") "Viewer"

local floor                             = math.floor
local match, sub                        = string.match, string.sub

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Viewer = {}

-- findViewersUI(...) -> table of hs._asm.axuielement | nil
-- Private Function
-- Finds the viewer `axuielement`s in a table. There may be more than one if the Event Viewer is enabled.
-- If none can be found, `nil` is returned.
--
-- Parameters:
-- * ...    - The list of windows to search in. Must have the `viewerGroupUI()` function.
--
-- Returns:
-- * A list of Viewer `axuielement`s, or `nil`.
local function findViewersUI(...)
    for i = 1,select("#", ...) do
        local window = select(i, ...)
        if window then
            local viewers = axutils.childrenMatching(window:viewerGroupUI(), Viewer.matches)
            if viewers then
                return viewers
            end
        end
    end
    return nil
end

-- findViewerUI(...) -> hs._asm.axuielement
-- Private Function
-- Finds the Viewer UI from the list, if present.
--
-- Parameters:
-- * ...    - the list of windows to check in.
--
-- Returns:
-- * The Viewer `axuelement`, or `nil` if not available.
local function findViewerUI(...)
    local viewers = findViewersUI(...)
    if viewers then
        return axutils.childFromRight(viewers, 1)
    end
    return nil
end

-- findEventViewerUI(...) -> hs._asm.axuielement
-- Private Function
-- Finds the Event Viewer UI from the list, if present.
--
-- Parameters:
-- * ...    - the list of windows to check in.
--
-- Returns:
-- * The Event Viewer `axuelement`, or `nil` if not available.
local function findEventViewerUI(...)
    local viewers = findViewersUI(...)
    if viewers and #viewers == 2 then
        -- The Event Viewer is always on the left, if present.
        return axutils.childFromLeft(viewers, 1)
    end
    return nil
end

-- TODO: Add documentation
function Viewer.matches(element)
    -- Viewers have a single 'AXContents' element
    local contents = element:attributeValue("AXContents")
    return contents and #contents == 1
       and contents[1]:attributeValue("AXRole") == "AXSplitGroup"
       and #(contents[1]) > 0
end

-- pixelsFromWindowCanvas(hsWindow, centerPixel) -> hs.image, hs.image
-- Function
-- Extracts two 2x2 pixel images from the screenshot of the image, centred
-- on the `centerPixel`. The first is the pixel in the centre, the second is offset by 2 pixels to the left
--
-- Parameters:
-- * hsWindow       - The `hs.window` having pixels pulled
-- * centerPixel    - The pixel to to retrieve (and offset)
--
-- Returns:
-- * Two `hs.images`, the first being the center pixel, the second being offset by 2px left.
local function pixelsFromWindowCanvas(hsWindow, centerPixel)
    local centerShot, offShot = nil, nil
    local windowShot = hsWindow:snapshot()
    if windowShot then
        local windowFrame = hsWindow:frame()
        local shotSize = windowShot:size()
        local ratio = shotSize.h/windowFrame.h

        local imagePixel = {
            x = (windowFrame.x-centerPixel.x)*ratio,
            y = (windowFrame.y-centerPixel.y)*ratio,
            w = shotSize.w,
            h = shotSize.h,
        }

        local c = canvas.new({w=1, h=1})
        c[1] = {
            type = "image",
            image = windowShot,
            imageScaling = "none",
            imageAlignment = "topLeft",
            frame = imagePixel,
        }

        centerShot = c:imageFromCanvas()

        -- shift left by 2 pixels, scaled by the ratio
        c[1].frame.x = imagePixel.x-floor(ratio*2)
        offShot = c:imageFromCanvas()

        -- delete the canvas
        c:delete()
    end
    return centerShot, offShot
end

--- cp.apple.finalcutpro.main.Viewer.new(app, eventViewer) -> Viewer
--- Constructor
--- Creates a new `Viewer` instance.
---
--- Parameters:
--- * app           - The FCP application.
--- * eventViewer   - If `true`, the viewer is the Event Viewer.
---
--- Returns:
--- * The new `Viewer` instance.
function Viewer.new(app, eventViewer)
    local o = prop.extend({
        _app = app,
        _eventViewer = eventViewer
    }, Viewer)

    -- The UI finder
    local UI = prop(function(self)
        return axutils.cache(o, "_ui", function()
            if self:isMainViewer() then
                return findViewerUI(app:secondaryWindow(), app:primaryWindow())
            else
                return findEventViewerUI(app:secondaryWindow(), app:primaryWindow())
            end
        end,
        Viewer.matches)
    end)

    prop.bind(o) {
        --- cp.apple.finalcutpro.main.Viewer.UI <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- The `axuielement` for the Viewer.
        UI = UI,

        --- cp.apple.finalcutpro.main.Viewer.isShowing <cp.prop: boolean; read-only>
        --- Field
        --- Checks if the Viewer is showing.
        isShowing = UI:mutate(function(original)
            return original() ~= nil
        end),

        --- cp.apple.finalcutpro.main.Viewer.isOnSecondary <cp.prop: boolean; read-only>
        --- Field
        --- Checks if the Viewer is showing on the Secondary Window.
        isOnSecondary = UI:mutate(function(original)
            local ui = original()
            return ui and SecondaryWindow.matches(ui:window())
        end),

        --- cp.apple.finalcutpro.main.Viewer.isOnPrimary <cp.prop: boolean; read-only>
        --- Field
        --- Checks if the Viewer is showing on the Primary Window.
        isOnPrimary = UI:mutate(function(original)
            local ui = original()
            return ui and PrimaryWindow.matches(ui:window())
        end),
    }

    local topToolbarUI = UI:mutate(function(original)
        return axutils.cache(o, "_topToolbar", function()
            local ui = original()
            return ui and axutils.childFromTop(ui, 1)
        end)
    end)

    local bottomToolbarUI = UI:mutate(function(original)
        return axutils.cache(o, "_bottomToolbar", function()
            local ui = original()
            return ui and axutils.childFromBottom(ui, 1)
        end)
    end)

    -- The StaticText that contains the timecode.
    o._timecode = StaticText.new(o, function()
        local ui = bottomToolbarUI()
        return ui and axutils.childFromLeft(axutils.childrenWithRole(ui, "AXStaticText"), 1)
    end)

    prop.bind(o) {
        --- cp.apple.finalcutpro.main.Viewer.topToolbarUI <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- Provides the `axuielement` for the top toolbar of the Viewer, or `nil` if not available.
        topToolbarUI = topToolbarUI,

        --- cp.apple.finalcutpro.main.Viewer.bottomToolbarUI <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- Provides the `axuielement` for the bottom toolbar of the Viewer, or `nil` if not available.
        bottomToolbarUI = bottomToolbarUI,

        --- cp.apple.finalcutpro.main.Viewer.hasPlayerControls <cp.prop: boolean; read-only>
        --- Field
        --- Checks if the viewer has Player Controls visible.
        hasPlayerControls = bottomToolbarUI:mutate(function(original)
            return original() ~= nil
        end),

        --- cp.apple.finalcutpro.main.Viewer.title <cp.prop: string; read-only>
        --- Field
        --- Provides the Title of the clip in the Viewer as a string, or `nil` if not available.
        title = topToolbarUI:mutate(function(original)
            local titleText = axutils.childFromLeft(original(), id "Title")
            return titleText and titleText:value()
        end),

        --- cp.apple.finalcutpro.main.Viewer.timecode <cp.prop: string>
        --- Field
        --- The current timecode value. The property can be watched to get notifications of changes.
        timecode = o._timecode.value,

        --- cp.apple.finalcut.main.Viewer.isPlaying <cp.prop: boolean>
        --- Field
        --- The 'playing' status of the viewer. If true, it is playing, if not it is paused.
        --- This can be set via `viewer:isPlaying(true|false)`, or toggled via `viewer.isPlaying:toggle()`.
        isPlaying = prop(
            function(self)
                local playButton = self:playButton()
                local frame = playButton:frame()
                if frame then
                    frame = geometry.new(frame)
                    local center = frame.center
                    local centerPixel = {x=floor(center.x), y=floor(center.y), w=1, h=1}

                    local window = self:currentWindow()
                    local hsWindow = window:hsWindow()

                    -----------------------------------------------------------------------
                    -- Save a snapshot:
                    -----------------------------------------------------------------------
                    local centerShot, offShot = pixelsFromWindowCanvas(hsWindow, centerPixel)

                    if centerShot then
                        -- centerShot:saveToFile("~/Desktop/viewer_center.png")
                        -- offShot:saveToFile("~/Desktop/viewer_off.png")
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
            function(newValue, owner, thisProp)
                local value = thisProp:value()
                if newValue ~= value then
                    owner:playButton():press()
                end
            end
        ),
    }

    o._isPlayingChecker = delayedTimer.new(0.1, function()
        if o.isPlaying:update() then
            -- it hasn't actually finished yet, so keep running.
            o._isPlayingChecker:start()
        end
    end)

    -- watch the `timecode` field and update `isPlaying`.
    o.timecode:watch(function(_)
        local checker = o._isPlayingChecker
        if o.isPlaying:update() then
            checker:start()
        else
            checker:stop()
        end
    end)

    --- cp.apple.finalcutpro.main.Viewer.formatUI <cp.prop: hs._asm.axuielement; read-only>
    --- Field
    --- Provides the `axuielement` for the Format text.
    local formatUI = topToolbarUI:mutate(function(original)
        return axutils.cache(o, "_format", function()
            local ui = original()
            return ui and axutils.childFromLeft(ui, id "Format")
        end)
    end):bind(o, "formatUI")

    --- cp.apple.finalcutpro.main.Viewer.getFormat <cp.prop: string; read-only>
    --- Field
    --- Provides the format text value, or `nil` if none is available.
    local format = formatUI:mutate(function(original)
            local format = original()
            return format and format:value()
    end):bind(o, "format")

    --- cp.apple.finalcutpro.main.Viewer.framerate <cp.prop: number; read-only>
    --- Field
    --- Provides the framerate as a number, or nil if not available.
    format:mutate(function(original)
        local formatValue = original()
        local framerate = format and match(formatValue, ' %d%d%.?%d?%d?[pi]')
        return framerate and tonumber(sub(framerate, 1,-2))
    end):bind(o, "framerate")

    return o
end

--- cp.apple.finalcutpro.main.Viewer:app() -> application
--- Method
--- Returns the application.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The application.
function Viewer:app()
    return self._app
end

-----------------------------------------------------------------------
--
-- BROWSER UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Viewer:isMainViewer() -> boolean
--- Method
--- Returns `true` if this is the main Viewer.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if this is the main Viewer.
function Viewer:isMainViewer()
    return not self._eventViewer
end

--- cp.apple.finalcutpro.main.Viewer:isEventViewer() -> boolean
--- Method
--- Returns `true` if this is the Event Viewer.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if this is the Event Viewer.
function Viewer:isEventViewer()
    return self._eventViewer
end

-----------------------------------------------------------------------
--
-- VIEWER UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Viewer:currentWindow()
    if self:isOnSecondary() then
        return self:app():secondaryWindow()
    else
        return self:app():primaryWindow()
    end
end

-- TODO: Add documentation
function Viewer:showOnPrimary()
    local menuBar = self:app():menu()

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
    local menuBar = self:app():menu()

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
    local menuBar = self:app():menu()

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
function Viewer:playButton()
    if not self._playButton then
        self._playButton = Button.new(self, function()
            return axutils.childFromLeft(axutils.childrenWithRole(self:bottomToolbarUI(), "AXButton"), 1)
        end)
    end
    return self._playButton
end

return Viewer