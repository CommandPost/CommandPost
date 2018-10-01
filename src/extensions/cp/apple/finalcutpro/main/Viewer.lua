--- === cp.apple.finalcutpro.main.Viewer ===
---
--- Viewer Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                               = require("hs.logger").new("viewer")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local canvas					        = require("hs.canvas")
local eventtap                          = require("hs.eventtap")
local geometry                          = require("hs.geometry")
-- local inspect                           = require("hs.inspect")
local timer                             = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                           = require("cp.ui.axutils")
local Element                           = require("cp.ui.Element")
local Button                            = require("cp.ui.Button")
local deferred                          = require("cp.deferred")
local flicks                            = require("cp.time.flicks")
local just                              = require("cp.just")
local MenuButton                        = require("cp.ui.MenuButton")
local notifier                          = require("cp.ui.notifier")
local prop                              = require("cp.prop")
local StaticText                        = require("cp.ui.StaticText")
local tools                             = require("cp.tools")

local PrimaryWindow                     = require("cp.apple.finalcutpro.main.PrimaryWindow")
local SecondaryWindow                   = require("cp.apple.finalcutpro.main.SecondaryWindow")

local id                                = require("cp.apple.finalcutpro.ids") "Viewer"

local go                                = require("cp.rx.go")
local Do, If                            = go.Do, go.If

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local cache                             = axutils.cache
local childFromLeft, childFromRight     = axutils.childFromLeft, axutils.childFromRight
local childFromTop, childFromBottom     = axutils.childFromTop, axutils.childFromBottom
local childrenMatching                  = axutils.childrenMatching
local childrenWithRole                  = axutils.childrenWithRole
local childWithRole                     = axutils.childWithRole
local delayedTimer                      = timer.delayed
local match, sub, find                  = string.match, string.sub, string.find

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Viewer = Element:subclass("cp.apple.finalcutpro.main.Viewer")

-- PLAYER_QUALITY -> table
-- Constant
-- Table of Player Quality values used by the `FFPlayerQuality` preferences value:
local PLAYER_QUALITY = {
    ORIGINAL_BETTER_QUALITY     = 10,
    ORIGINAL_BETTER_PERFORMANCE = 5,
    PROXY                       = 4,
}

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
            local viewers = childrenMatching(window:viewerGroupUI(), Viewer.matches)
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
        return childFromRight(viewers, 1)
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
        -----------------------------------------------------------------------
        -- The Event Viewer is always on the left, if present:
        -----------------------------------------------------------------------
        return childFromLeft(viewers, 1)
    end
    return nil
end

--- cp.apple.finalcutpro.main.Viewer.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function Viewer.static.matches(element)
    -- Viewers have a single 'AXContents' element
    if Element.matches(element) then
        local contents = element:attributeValue("AXContents")
        return contents and #contents == 1
            and contents[1]:attributeValue("AXRole") == "AXSplitGroup"
            and #(contents[1]) > 0
    end
    return false
end

--- cp.apple.finalcutpro.main.Viewer(app, eventViewer) -> Viewer
--- Constructor
--- Creates a new `Viewer` instance.
---
--- Parameters:
--- * app           - The FCP application.
--- * eventViewer   - If `true`, the viewer is the Event Viewer.
---
--- Returns:
--- * The new `Viewer` instance.
function Viewer:initialize(app, eventViewer)
    -- The UI finder
    local UI = prop(function()
        return cache(self, "_ui", function()
            if self:isMainViewer() then
                return findViewerUI(app:secondaryWindow(), app:primaryWindow())
            else
                return findEventViewerUI(app:secondaryWindow(), app:primaryWindow())
            end
        end,
        Viewer.matches)
    end)

    Element.initialize(self, app, UI)

    self._eventViewer = eventViewer

    local checker
    checker = delayedTimer.new(0.2, function()
        if self.isPlaying:update() then
            -----------------------------------------------------------------------
            -- It hasn't actually finished yet, so keep running:
            -----------------------------------------------------------------------
            checker:start()
        end
    end)

    -----------------------------------------------------------------------
    -- Watch the `timecode` field and update `isPlaying`:
    -----------------------------------------------------------------------
    self.timecode:watch(function()
        if not checker:running() then
            -----------------------------------------------------------------------
            -- Update the first time:
            -----------------------------------------------------------------------
            self.isPlaying:update()
        end
        checker:start()
    end)

    -----------------------------------------------------------------------
    -- Reduce the amount of AX notifications when a Final Cut Pro window
    -- is moved or resized:
    -----------------------------------------------------------------------
    local frameUpdater
    frameUpdater = deferred.new(0.001):action(function()
        self.frame:update()
    end)

    -----------------------------------------------------------------------
    -- Watch for the Viewer being resized:
    -----------------------------------------------------------------------
    app:notifier():watchFor({"AXWindowResized", "AXWindowMoved", "AXSelectedChildrenChanged"}, function()
        frameUpdater:run()
    end)
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
    return self:parent()
end

--- cp.apple.finalcutpro.main.Viewer.isOnSecondary <cp.prop: boolean; read-only>
--- Field
--- Checks if the Viewer is showing on the Secondary Window.
function Viewer.lazy.prop:isOnSecondary()
    return self:mutate(function(original)
        local ui = original()
        return ui and SecondaryWindow.matches(ui:window())
    end)
end

--- cp.apple.finalcutpro.main.Viewer.isOnPrimary <cp.prop: boolean; read-only>
--- Field
--- Checks if the Viewer is showing on the Primary Window.
function Viewer.lazy.prop:isOnPrimary()
    return self:mutate(function(original)
        local ui = original()
        return ui and PrimaryWindow.matches(ui:window())
    end)
end

--- cp.apple.finalcutpro.main.Viewer.frame <cp.prop: table; read-only>
--- Field
--- Returns the current frame for the viewer, or `nil` if it is not available.
function Viewer.lazy.prop:frame()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui and geometry.rect(ui:attributeValue("AXFrame"))
    end)
end

--- cp.apple.finalcutpro.main.Viewer.topToolbarUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Provides the `axuielement` for the top toolbar of the Viewer, or `nil` if not available.
function Viewer.lazy.prop:topToolbarUI()
    return self.UI:mutate(function(original)
        return cache(self, "_topToolbar", function()
            local ui = original()
            return ui and childFromTop(ui, 1)
        end)
    end)
end

--- cp.apple.finalcutpro.main.Viewer.contentsUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Provides the `axuielement` for the media contents of the Viewer, or `nil` if not available.
function Viewer.lazy.prop:contentsUI()
    return self.UI:mutate(function(original)
        return cache(self, "_contents", function()
            local ui = original()
            local splitGroup = ui and childWithRole(ui, "AXSplitGroup")
            local groups = splitGroup and childrenWithRole(splitGroup, "AXGroup")
            local contentGroup = groups and groups[#groups]
            return contentGroup
        end)
    end)
end

--- cp.apple.finalcutpro.main.Viewer.bottomToolbarUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Provides the `axuielement` for the bottom toolbar of the Viewer, or `nil` if not available.
function Viewer.lazy.prop:bottomToolbarUI()
    return self.UI:mutate(function(original)
        return cache(self, "_bottomToolbar", function()
            local ui = original()
            return ui and childFromBottom(ui, 1)
        end)
    end)
end

-----------------------------------------------------------------------
-- The StaticText that contains the timecode:
-----------------------------------------------------------------------
function Viewer.lazy.method:timecodeText()
    return StaticText(self, self.bottomToolbarUI:mutate(function(original)
        local ui = original()
        return ui and childFromLeft(childrenWithRole(ui, "AXStaticText"), 1)
    end))
end

function Viewer.lazy.method:viewMenu()
    return MenuButton(self, self.topToolbarUI:mutate(function(original)
        local ui = original()
        return ui and childFromRight(childrenWithRole(ui, "AXMenuButton"), 1)
    end))
end

--- cp.apple.finalcutpro.main.Viewer.timecode <cp.prop: string; live>
--- Field
--- The current timecode value, with the format "hh:mm:ss:ff". Setting also supports "hh:mm:ss;ff".
--- The property can be watched to get notifications of changes.
function Viewer.lazy.prop:timecode()
    return self:timecodeText().value:mutate(
        function(original)
            return original()
        end,
        function(timecodeValue, original)
            local tcField = self:timecodeText()
            if not tcField:isShowing() then
                return
            end
            local framerate = self:framerate()
            local tc = framerate and flicks.parse(timecodeValue, framerate)
            if tc then
                local center = geometry(tcField:frame()).center
                --------------------------------------------------------------------------------
                -- Double click the timecode value in the Viewer:
                --------------------------------------------------------------------------------
                self:app():launch()
                local result = just.doUntil(function()
                    return self:app():isFrontmost()
                end)
                if not result then
                    log.ef("Failed to make Final Cut Pro frontmost (cp.apple.finalcutpro.main.Viewer.timecode).")
                end
                tools.ninjaMouseClick(center)

                --------------------------------------------------------------------------------
                -- Wait until the click has been registered (give it 5 seconds):
                --------------------------------------------------------------------------------
                local toolbar = self:bottomToolbarUI()
                local ready = just.doUntil(function()
                    return #toolbar < 5 and find(original(), "00:00:00[:;]00") ~= nil
                end, 5)
                if ready then
                    --------------------------------------------------------------------------------
                    -- Type in Original Timecode & Press Return Key:
                    --------------------------------------------------------------------------------
                    eventtap.keyStrokes(tc:toTimecode(framerate))
                    eventtap.keyStroke({}, 'return')
                    return self
                end
            else
                log.ef("Timecode value is invalid: %s", timecodeValue)
            end
        end
    )
end

--- cp.apple.finalcutpro.main.Viewer.playerQuality <cp.prop: string>
--- Field
--- The currentplayer quality value.
function Viewer.lazy.prop:playerQuality()
    return self:app().preferences:prop("FFPlayerQuality")
end

--- cp.apple.finalcutpro.main.Viewer.hasPlayerControls <cp.prop: boolean; read-only>
--- Field
--- Checks if the viewer has Player Controls visible.
function Viewer.lazy.prop:hasPlayerControls()
    return self.bottomToolbarUI:mutate(function(original)
        return original() ~= nil
    end)
end

--- cp.apple.finalcutpro.main.Viewer.title <cp.prop: string; read-only>
--- Field
--- Provides the Title of the clip in the Viewer as a string, or `nil` if not available.
function Viewer.lazy.prop:title()
    return self.topToolbarUI:mutate(function(original)
        local titleText = childFromLeft(original(), id "Title")
        return titleText and titleText:value()
    end)
end

--- cp.apple.finalcut.main.Viewer.isPlaying <cp.prop: boolean>
--- Field
--- The 'playing' status of the viewer. If true, it is playing, if not it is paused.
--- This can be set via `viewer:isPlaying(true|false)`, or toggled via `viewer.isPlaying:toggle()`.
function Viewer.lazy.prop:isPlaying()
    return prop(
        function()
            local element = self:playButton():UI()
            if element then
                local window = element:attributeValue("AXWindow")

                local hsWindow = window:asHSWindow()
                local windowSnap = hsWindow:snapshot()
                local windowFrame = window:frame()
                local shotSize = windowSnap:size()

                local ratio = shotSize.h/windowFrame.h
                local elementFrame = element:frame()

                local imageFrame = {
                    x = (windowFrame.x-elementFrame.x)*ratio,
                    y = (windowFrame.y-elementFrame.y)*ratio,
                    w = shotSize.w,
                    h = shotSize.h,
                }

                --------------------------------------------------------------------------------
                -- TODO: Replace this hs.canvas using hs.image:croppedCopy(rectangle)
                --------------------------------------------------------------------------------

                local c = canvas.new({w=elementFrame.w*ratio, h=elementFrame.h*ratio})
                c[1] = {
                    type = "image",
                    image = windowSnap,
                    imageScaling = "none",
                    imageAlignment = "topLeft",
                    frame = imageFrame,
                }

                local elementSnap = c:imageFromCanvas()
                c:delete()

                if elementSnap then
                    elementSnap:size({h=60,w=60})
                    local spot = elementSnap:colorAt({x=31,y=31})
                    return spot and spot.blue < 0.5
                end
            end
            return false
        end,
        function(newValue, owner, thisProp)
            local currentValue = thisProp:value()
            if newValue ~= currentValue then
                owner:playButton():press()
            end
        end
    )
end

--- cp.apple.finalcutpro.main.Viewer.usingProxies <cp.prop: boolean>
--- Field
--- Indicates if the viewer is using Proxies (`true`) or Optimized/Original media (`false`).
function Viewer.lazy.prop:usingProxies()
    return self.playerQuality:mutate(
        function(original)
            return original() == PLAYER_QUALITY.PROXY
        end,
        function(proxies, original, _, theProp)
            local currentValue = theProp()
            if currentValue ~= proxies then -- got to switch
                if self:isShowing() then
                    local itemKey = proxies and "CPViewerViewProxy" or "CPViewerViewOptimized"
                    local itemValue = self:app().strings:find(itemKey)
                    if itemValue then
                        self:viewMenu():selectItemMatching(itemValue)
                    else
                        log.ef("Unable to find the '%s' string in '%s'", itemKey, self:app():currentLocale())
                    end
                else
                    local quality = proxies and PLAYER_QUALITY.PROXY or PLAYER_QUALITY.ORIGINAL_BETTER_PERFORMANCE
                    original(quality)
                end
            end
        end
    )
end

--- cp.apple.finalcutpro.main.Viewer.betterQuality <cp.prop: boolean>
--- Field
--- Indicates if the viewer is using playing with better quality (`true`) or performance (`false).
--- If we are `usingProxies` then it will always be `false`.
function Viewer.lazy.prop:betterQuality()
    return self.playerQuality:mutate(
        function(original)
            return original() == PLAYER_QUALITY.ORIGINAL_BETTER_QUALITY
        end,
        function(quality, original, _, theProp)
            local currentQuality = theProp()
            if quality ~= currentQuality then
                if self:isShowing() then
                    local itemKey = quality and "CPViewerViewBetterQuality" or "CPViewerViewBetterPerformance"
                    local itemValue = self:app().strings:find(itemKey)
                    if itemValue then
                        self:viewMenu():selectItemMatching(itemValue)
                    else
                        log.ef("Unable to find '%s' string in '%s'", itemValue, self:app():currentLocale())
                    end
                else
                    local qualityValue = quality and PLAYER_QUALITY.ORIGINAL_BETTER_QUALITY or PLAYER_QUALITY.ORIGINAL_BETTER_PERFORMANCE
                    original(qualityValue)
                end
            end
        end
    )
end

--- cp.apple.finalcutpro.main.Viewer.formatUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Provides the `axuielement` for the Format text.
function Viewer.lazy.prop:formatUI()
    return self.topToolbarUI:mutate(function(original)
        return cache(self, "_format", function()
            local ui = original()
            return ui and childFromLeft(ui, id "Format")
        end)
    end)
end

--- cp.apple.finalcutpro.main.Viewer.getFormat <cp.prop: string; read-only>
--- Field
--- Provides the format text value, or `nil` if none is available.
function Viewer.lazy.prop:format()
    return self.formatUI:mutate(function(original)
        local format = original()
        return format and format:value()
    end)
end

--- cp.apple.finalcutpro.main.Viewer.framerate <cp.prop: number; read-only>
--- Field
--- Provides the framerate as a number, or nil if not available.
function Viewer.lazy.prop:framerate()
    return self.format:mutate(function(original)
        local formatValue = original()
        local framerate = formatValue and match(formatValue, ' %d%d%.?%d?%d?[pi]')
        return framerate and tonumber(sub(framerate, 1,-2))
    end)
end

-----------------------------------------------------------------------
--
-- BROWSER UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Viewer.isMainViewer <cp.prop: boolean>
--- Field
--- Returns `true` if this is the main Viewer.
function Viewer.lazy.prop:isMainViewer()
    return self.isEventViewer:NOT()
end

--- cp.apple.finalcutpro.main.Viewer.isEventViewer <cp.prop: boolean>
--- Field
--- Returns `true` if this is the Event Viewer.
function Viewer.lazy.prop:isEventViewer()
    return prop(function() return self._eventViewer end)
end

-----------------------------------------------------------------------
--
-- VIEWER UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Viewer:currentWindow() -> PrimaryWindow | SecondaryWindow
--- Method
--- Gets the current window object.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `PrimaryWindow` or the `SecondaryWindow`.
function Viewer:currentWindow()
    if self:isOnSecondary() then
        return self:app():secondaryWindow()
    else
        return self:app():primaryWindow()
    end
end

--- cp.apple.finalcutpro.main.Viewer:showOnPrimary() -> self
--- Method
--- Shows the Viewer on the Primary display.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Self
function Viewer:showOnPrimary()
    local menuBar = self:app():menu()

    -----------------------------------------------------------------------
    -- If it is on the secondary, we need to turn it off before
    -- enabling in primary:
    -----------------------------------------------------------------------
    if self:isOnSecondary() then
        menuBar:selectMenu({"Window", "Show in Secondary Display", "Viewers"})
    end

    if self:isEventViewer() and not self:isShowing() then
        -----------------------------------------------------------------------
        -- Enable the Event Viewer:
        -----------------------------------------------------------------------
        menuBar:selectMenu({"Window", "Show in Workspace", "Event Viewer"})
    end

    return self
end

--- cp.apple.finalcutpro.main.Viewer:doShowOnPrimary() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that shows the Viewer on the Primary display.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Statement`, which resolves to `true`, or sends an error message.
function Viewer.lazy.method:doShowOnPrimary()
    local menuBar = self:app():menu()

    return Do(
        If(self.isOnSecondary):Then(
            menuBar:doSelectMenu({"Window", "Show in Secondary Display", "Viewers"})
        )
    ):Then(
        If(self.isEventViewer:AND(self.isShowing:NOT())):Then(
            -----------------------------------------------------------------------
            -- Enable the Event Viewer:
            -----------------------------------------------------------------------
            menuBar:doSelectMenu({"Window", "Show in Workspace", "Event Viewer"})
        ):Otherwise(true)
    ):Label("Viewer:doShowOnPrimary")
end

--- cp.apple.finalcutpro.main.Viewer:showOnSecondary() -> self
--- Method
--- Shows the Viewer on the Seconary display.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Self
function Viewer:showOnSecondary()
    local menuBar = self:app():menu()

    if not self:isOnSecondary() then
        menuBar:selectMenu({"Window", "Show in Secondary Display", "Viewers"})
    end

    if self:isEventViewer() and not self:isShowing() then
        -----------------------------------------------------------------------
        -- Enable the Event Viewer:
        -----------------------------------------------------------------------
        menuBar:selectMenu({"Window", "Show in Workspace", "Event Viewer"})
    end

    return self
end

--- cp.apple.finalcutpro.main.Viewer:doShowOnSecondary() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that shows the Viewer on the Secondary display.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Statement`, resolving to `true`, or sending an error message.
function Viewer.lazy.method:doShowOnSecondary()
    local menuBar = self:app():menu()

    return Do(
        If(self.isOnSecondary):Is(false):Then(
            menuBar:doSelectMenu({"Window", "Show in Secondary Display", "Viewers"})
        )
    ):Then(
        If(self.isEventViewer:AND(self.isShowing:NOT())):Then(
            -----------------------------------------------------------------------
            -- Enable the Event Viewer:
            -----------------------------------------------------------------------
            menuBar:doSelectMenu({"Window", "Show in Workspace", "Event Viewer"})
        ):Otherwise(true)
    )
end

--- cp.apple.finalcutpro.main.Viewer:hide() -> self
--- Method
--- Hides the Viewer.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Self
function Viewer:hide()
    local menuBar = self:app():menu()

    if self:isEventViewer() then
        -----------------------------------------------------------------------
        -- Uncheck it from the primary workspace:
        -----------------------------------------------------------------------
        if self:isShowing() then
            menuBar:selectMenu({"Window", "Show in Workspace", "Event Viewer"})
        end
    elseif self:isOnSecondary() then
        -----------------------------------------------------------------------
        -- The Viewer can only be hidden from the Secondary Display:
        -----------------------------------------------------------------------
        menuBar:selectMenu({"Window", "Show in Secondary Display", "Viewers"})
    end
    return self
end

--- cp.apple.finalcutpro.main.Viewer:doHide() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that hides the Viewer.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Statement`, resolving to `true`, or sends an error.
function Viewer.lazy.method:doHide()
    local menuBar = self:app():menu()

    return If(self.isEventViewer):Then(
        -----------------------------------------------------------------------
        -- Uncheck it from the primary workspace:
        -----------------------------------------------------------------------
        If(self.isShowing):Then(
            menuBar:doSelectMenu({"Window", "Show in Workspace", "Event Viewer"})
        )
    ):Otherwise(
        If(self.isOnSecondary):Then(
            -----------------------------------------------------------------------
            -- The Viewer can only be hidden from the Secondary Display:
            -----------------------------------------------------------------------
            menuBar:doSelectMenu({"Window", "Show in Secondary Display", "Viewers"})
        ):Otherwise(true)
    )
end

--- cp.apple.finalcutpro.main.Viewer:playButton() -> Button
--- Method
--- Gets the Play Button object.
---
--- Parameters:
--- * None
---
--- Returns:
--- * A Button
function Viewer.lazy.method:playButton()
    return Button(self, self.bottomToolbarUI:mutate(function(original)
        return childFromLeft(childrenWithRole(original(), "AXButton"), 1)
    end))
end

--- cp.apple.finalcutpro.main.Viewer:notifier() -> cp.ui.notifier
--- Method
--- Returns a `notifier` that is tracking the application UI element. It has already been started.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The notifier.
function Viewer.lazy.method:notifier()
    local theApp = self:app()
    local bundleID = theApp:bundleID()
    return notifier.new(bundleID, function() return self:UI() end):start()
end

function Viewer:__tostring()
    return string.format("%s: %s", self.class.name, self.eventViewer and "event" or "main")
end

return Viewer
