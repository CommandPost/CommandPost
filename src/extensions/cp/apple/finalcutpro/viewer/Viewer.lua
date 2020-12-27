--- === cp.apple.finalcutpro.viewer.Viewer ===
---
--- Viewer Module.

local require                           = require

local log                               = require "hs.logger".new "viewer"

local eventtap                          = require "hs.eventtap"
local geometry                          = require "hs.geometry"
local timer                             = require "hs.timer"

local axutils                           = require "cp.ui.axutils"
local deferred                          = require "cp.deferred"
local go                                = require "cp.rx.go"
local Group                             = require "cp.ui.Group"
local notifier                          = require "cp.ui.notifier"
local prop                              = require "cp.prop"
local SplitGroup                        = require "cp.ui.SplitGroup"

local ControlBar                        = require "cp.apple.finalcutpro.viewer.ControlBar"
local InfoBar                           = require "cp.apple.finalcutpro.viewer.InfoBar"
local PrimaryWindow                     = require "cp.apple.finalcutpro.main.PrimaryWindow"
local SecondaryWindow                   = require "cp.apple.finalcutpro.main.SecondaryWindow"

local cache                             = axutils.cache
local childFromLeft, childFromRight     = axutils.childFromLeft, axutils.childFromRight
local childrenMatching                  = axutils.childrenMatching
local childrenWithRole                  = axutils.childrenWithRole
local childWithRole                     = axutils.childWithRole
local delayedTimer                      = timer.delayed
local Do                                = go.Do
local If                                = go.If
local topToBottom                       = axutils.compareTopToBottom

local Viewer = Group:subclass("cp.apple.finalcutpro.viewer.Viewer")

-- PLAYER_QUALITY -> table
-- Constant
-- Table of Player Quality values used by the `FFPlayerQuality` preferences value:
local PLAYER_QUALITY = {
    ORIGINAL_BETTER_QUALITY     = 10,
    ORIGINAL_BETTER_PERFORMANCE = 5,
    PROXY                       = 4,
}

-- findViewersUI(...) -> table of hs.axuielement | nil
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
            if viewers and #viewers > 0 then
                return viewers
            end
        end
    end
    return nil
end

-- findViewerUI(...) -> hs.axuielement
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
        return childFromRight(viewers, 1, Viewer.matches)
    end
    return nil
end

-- findEventViewerUI(...) -> hs.axuielement
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
        return childFromLeft(viewers, 1, Viewer.matches)
    end
    return nil
end

--- cp.apple.finalcutpro.viewer.Viewer.matches(element) -> boolean
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
    if Group.matches(element) then
        local items = axutils.children(element, topToBottom)
        return #items == 3
            and InfoBar.matches(items[1])
            and ControlBar.matches(items[3])
    end
    return false
end

--- cp.apple.finalcutpro.viewer.Viewer(app, eventViewer) -> Viewer
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
                return findViewerUI(app.secondaryWindow, app.primaryWindow)
            else
                return findEventViewerUI(app.secondaryWindow, app.primaryWindow)
            end
        end,
        Viewer.matches)
    end)

    Group.initialize(self, app, UI, SplitGroup)

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

    -----------------------------------------------------------------------
    -- Watch for spacebar presses to speed up isPlaying updates:
    -----------------------------------------------------------------------
    self._keywatcher = eventtap.new({eventtap.event.types.keyDown}, function(event)
        if event:getKeyCode() == 49 then
            self.isPlaying:update()
        end
    end)

    -----------------------------------------------------------------------
    -- Only check for spacebar presses when FCPX is frontmost:
    -----------------------------------------------------------------------
    self:app().isFrontmost:watch(function(frontmost)
        if frontmost then
            self._keywatcher:start()
        else
            self._keywatcher:stop()
        end
    end)

end

--- cp.apple.finalcutpro.viewer.Viewer:app() -> application
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

--- cp.apple.finalcutpro.viewer.Viewer.isOnSecondary <cp.prop: boolean; read-only>
--- Field
--- Checks if the Viewer is showing on the Secondary Window.
function Viewer.lazy.prop:isOnSecondary()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui and SecondaryWindow.matches(ui:attributeValue("AXWindow"))
    end)
end

--- cp.apple.finalcutpro.viewer.Viewer.isOnPrimary <cp.prop: boolean; read-only>
--- Field
--- Checks if the Viewer is showing on the Primary Window.
function Viewer.lazy.prop:isOnPrimary()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui and PrimaryWindow.matches(ui:attributeValue("AXWindow"))
    end)
end

--- cp.apple.finalcutpro.viewer.Viewer.frame <cp.prop: table; read-only>
--- Field
--- Returns the current frame for the viewer, or `nil` if it is not available.
function Viewer.lazy.prop:frame()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui and geometry.rect(ui:attributeValue("AXFrame"))
    end)
end

--- cp.apple.finalcutpro.viewer.Viewer.contentsUI <cp.prop: hs.axuielement; read-only>
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

--- cp.apple.finalcutpro.viewer.Viewer.infoBar <cp.apple.finalcutpro.viewer.InfoBar>
--- Field
--- Provides the [InfoBar](cp.apple.finalcutpro.viewer.InfoBar.md) for this `Viewer`.
--- This contains the UI elemenst for the format, title, zoom and view menus.
function Viewer.lazy.value:infoBar()
    return InfoBar(self)
end

--- cp.apple.finalcutpro.viewer.Viewer.controlBar <cp.apple.finalcutpro.viewer.ControlBar>
--- Field
--- Provides the [ControlBar](cp.apple.finalcutpro.viewer.ControlBar.md) for this `Viewer`.
--- This contains the UI elemenst for play button, timecode, audio levels and more.
function Viewer.lazy.value:controlBar()
    return ControlBar(self)
end

--- cp.apple.finalcutpro.viewer.Viewer.timecodeField <cp.ui.StaticText>
--- Field
--- The [StaticText](cp.ui.StaticText.md) containing the timecode value.
function Viewer.lazy.value:timecodeField()
    return self.controlBar.timecodeField
end

--- cp.apple.finalcutpro.viewer.Viewer.timecode <cp.prop: string; live>
--- Field
--- The current timecode value, with the format "hh:mm:ss:ff". Setting also supports "hh:mm:ss;ff".
--- The property can be watched to get notifications of changes.
function Viewer.lazy.prop:timecode()
    return self.controlBar.timecode
end

--- cp.apple.finalcutpro.viewer.Viewer.playerQuality <cp.prop: string>
--- Field
--- The current player quality value.
function Viewer.lazy.prop:playerQuality()
    return self:app().preferences:prop("FFPlayerQuality")
end

--- cp.apple.finalcutpro.viewer.Viewer.hasPlayerControls <cp.prop: boolean; read-only>
--- Field
--- Checks if the viewer has Player Controls visible.
function Viewer.lazy.prop:hasPlayerControls()
    return self.controlBar.isShowing
end

--- cp.apple.finalcutpro.viewer.Viewer.title <cp.ui.StaticText>
--- Field
--- Provides the Title of the clip in the Viewer as a [StaticText](cp.ui.StaticText.md)
function Viewer.lazy.prop:title()
    return self.infoBar.title
end

function Viewer.lazy.value:viewMenu()
    return self.infoBar.viewMenu
end

--- cp.apple.finalcutpro.main.Viewer.isPlaying <cp.prop: boolean>
--- Field
--- The 'playing' status of the viewer. If true, it is playing, if not it is paused.
--- This can be set via `viewer:isPlaying(true|false)`, or toggled via `viewer.isPlaying:toggle()`.
function Viewer.lazy.prop:isPlaying()
    return self.controlBar.isPlaying
end

--- cp.apple.finalcutpro.viewer.Viewer.usingProxies <cp.prop: boolean>
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
                        self.viewMenu:selectItemMatching(itemValue)
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

--- cp.apple.finalcutpro.viewer.Viewer.betterQuality <cp.prop: boolean>
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
                        self.viewMenu:selectItemMatching(itemValue)
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

--- cp.apple.finalcutpro.viewer.Viewer.getFormat <cp.prop: string; read-only>
--- Field
--- Provides the format text value, or `nil` if none is available.
function Viewer.lazy.prop:format()
    return self.infoBar.format
end

--- cp.apple.finalcutpro.viewer.Viewer.framerate <cp.prop: number; read-only>
--- Field
--- Provides the framerate as a number, or nil if not available.
function Viewer.lazy.prop:framerate()
    return self.infoBar.framerate
end

-----------------------------------------------------------------------
--
-- BROWSER UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.viewer.Viewer.isMainViewer <cp.prop: boolean>
--- Field
--- Returns `true` if this is the main Viewer.
function Viewer.lazy.prop:isMainViewer()
    return self.isEventViewer:NOT()
end

--- cp.apple.finalcutpro.viewer.Viewer.isEventViewer <cp.prop: boolean>
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

--- cp.apple.finalcutpro.viewer.Viewer:currentWindow() -> PrimaryWindow | SecondaryWindow
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
        return self:app().secondaryWindow
    else
        return self:app().primaryWindow
    end
end

--- cp.apple.finalcutpro.viewer.Viewer:showOnPrimary() -> self
--- Method
--- Shows the Viewer on the Primary display.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Self
function Viewer:showOnPrimary()
    local menuBar = self:app().menu

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

--- cp.apple.finalcutpro.viewer.Viewer:doShowOnPrimary() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that shows the Viewer on the Primary display.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Statement`, which resolves to `true`, or sends an error message.
function Viewer.lazy.method:doShowOnPrimary()
    local menuBar = self:app().menu

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

--- cp.apple.finalcutpro.viewer.Viewer:showOnSecondary() -> self
--- Method
--- Shows the Viewer on the Seconary display.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Self
function Viewer:showOnSecondary()
    local menuBar = self:app().menu

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

--- cp.apple.finalcutpro.viewer.Viewer:doShowOnSecondary() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that shows the Viewer on the Secondary display.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Statement`, resolving to `true`, or sending an error message.
function Viewer.lazy.method:doShowOnSecondary()
    local menuBar = self:app().menu

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

--- cp.apple.finalcutpro.viewer.Viewer:hide() -> self
--- Method
--- Hides the Viewer.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Self
function Viewer:hide()
    local menuBar = self:app().menu

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

--- cp.apple.finalcutpro.viewer.Viewer:doHide() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that hides the Viewer.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Statement`, resolving to `true`, or sends an error.
function Viewer.lazy.method:doHide()
    local menuBar = self:app().menu

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

--- cp.apple.finalcutpro.viewer.Viewer.playButton <cp.ui.Button>
--- Field
--- The Play [Button](cp.ui.Button.md) object.
---
--- Parameters:
--- * None
---
--- Returns:
--- * A Button
function Viewer.lazy.value:playButton()
    return self.controlBar.playButton
end

--- cp.apple.finalcutpro.viewer.Viewer:notifier() -> cp.ui.notifier
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
    return string.format("%s: %s", self.class.name, self._eventViewer and "event" or "main")
end

return Viewer
