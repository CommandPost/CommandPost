--- === cp.apple.finalcutpro.main.Timeline ===
---
--- Timeline Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log								= require("hs.logger").new("timeline")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils							= require("cp.ui.axutils")
local Element                           = require("cp.ui.Element")
local go                                = require("cp.rx.go")
local prop								= require("cp.prop")

local EffectsBrowser					= require("cp.apple.finalcutpro.main.EffectsBrowser")
local PrimaryWindow						= require("cp.apple.finalcutpro.main.PrimaryWindow")
local SecondaryWindow					= require("cp.apple.finalcutpro.main.SecondaryWindow")
local TimelineContent					= require("cp.apple.finalcutpro.main.TimelineContents")
local TimelineToolbar					= require("cp.apple.finalcutpro.main.TimelineToolbar")
local TimelineIndex                     = require("cp.apple.finalcutpro.main.TimelineIndex")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local Do, If, WaitUntil                 = go.Do, go.If, go.WaitUntil
local cache                             = axutils.cache
local childWithRole, childMatching      = axutils.childWithRole, axutils.childMatching
local childrenWithRole                  = axutils.childrenWithRole

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Timeline = Element:subclass("cp.apple.finalcutpro.main.Timeline")

--- cp.apple.finalcutpro.main.Timeline.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`.
---
--- Notes:
---  * `element` should be an `AXGroup`, which contains an `AXSplitGroup` with an
---    `AXIdentifier` of `_NS:237` (as of Final Cut Pro 10.4)
function Timeline.static.matches(element)
    local splitGroup = childWithRole(element, "AXSplitGroup")
    return element:attributeValue("AXRole") == "AXGroup"
       and splitGroup
       and Timeline.matchesMain(splitGroup)
end

--- cp.apple.finalcutpro.main.Timeline.matchesMain(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
---
--- Notes:
---  * `element` should be an `AXSplitGroup` with an `AXIdentifier` of `_NS:237`
---    (as of Final Cut Pro 10.4)
---  * Because the timeline contents is hard to detect, we look for the timeline
---    toolbar instead.
function Timeline.static.matchesMain(element)
    local parent = element and element:attributeValue("AXParent")
    local group = parent and childWithRole(parent, "AXGroup")
    local buttons = group and childrenWithRole(group, "AXButton")
    return buttons and #buttons >= 6
end

-- _findTimeline(...) -> window | nil
-- Function
-- Gets the Timeline UI.
--
-- Parameters:
--  * ... - Table of elements.
--
-- Returns:
--  * An `axuielementObject` or `nil`
function Timeline.static._findTimeline(...)
    for i = 1,select("#", ...) do
        local window = select(i, ...)
        if window then
            local ui = window:timelineGroupUI()
            if ui then
                local timeline = childMatching(ui, Timeline.matches)
                if timeline then return timeline end
            end
        end
    end
    return nil
end

--- cp.apple.finalcutpro.main.Timeline.new(app) -> Timeline
--- Constructor
--- Creates a new `Timeline` instance.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new `Timeline` object.
function Timeline:initialize(app)

    local UI = app.UI:mutate(function()
        return cache(self, "_ui", function()
            return Timeline._findTimeline(app:secondaryWindow(), app:primaryWindow())
        end,
        Timeline.matches)
    end):monitor(app:primaryWindow().UI, app:secondaryWindow().UI)

    Element.initialize(self, app, UI)
end

--- cp.apple.finalcutpro.main.Timeline.isOnSecondary <cp.prop: boolean; read-only>
--- Field
--- Checks if the Timeline is on the Secondary Display.
function Timeline.lazy.prop:isOnSecondary()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui ~= nil and SecondaryWindow.matches(ui:window())
    end)
end

--- cp.apple.finalcutpro.main.Timeline.isOnPrimary <cp.prop: boolean; read-only>
--- Field
--- Checks if the Timeline is on the Primary Display.
function Timeline.lazy.prop:isOnPrimary()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui ~= nil and PrimaryWindow.matches(ui:window())
    end)
end

--- cp.apple.finalcutpro.main.Timeline.isShowing <cp.prop: boolean; read-only>
--- Field
--- Checks if the Timeline is showing on either the Primary or Secondary display.
function Timeline.lazy.prop:isShowing()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui ~= nil and #ui > 0
    end)
end
--- cp.apple.finalcutpro.main.Timeline.mainUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `axuielement` representing the 'timeline', or `nil` if not available.
function Timeline.lazy.prop:mainUI()
    return self.UI:mutate(function(original, self)
        return cache(self, "_main", function()
            local ui = original()
            return ui and childMatching(ui, Timeline.matchesMain)
        end,
        Timeline.matchesMain)
    end)
end

--- cp.apple.finalcutpro.main.Timeline.isPlaying <cp.prop: boolean>
--- Field
--- Is the timeline playing?
function Timeline.lazy.prop:isPlaying()
    return self:app():viewer().isPlaying:mutate(function(original)
        return original()
    end)
end

--- cp.apple.finalcutpro.main.Timeline.isLockedPlayhead <cp.prop: boolean>
--- Field
--- Is Playhead Locked?
function Timeline.lazy.prop.isLockedPlayhead()
    return prop.TRUE()
end

--- cp.apple.finalcutpro.main.Timeline.isLockedInCentre <cp.prop: boolean>
--- Field
--- Is Playhead Locked in the centre?
function Timeline.lazy.prop.isLockedInCentre()
    return prop.TRUE()
end

--- cp.apple.finalcutpro.main.Timeline.isLoaded <cp.prop: boolean; read-only>
--- Field
--- Checks if the Timeline has finished loading.
function Timeline.lazy.prop:isLoaded()
    return self:contents().isLoaded
end

--- cp.apple.finalcutpro.main.Timeline.isFocused <cp.prop: boolean; read-only>
--- Field
--- Checks if the Timeline is the focused panel.
function Timeline.lazy.prop:isFocused()
    return self:contents().isFocused
end

--- cp.apple.finalcutpro.main.Timeline:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Timeline:app()
    return self:parent()
end

-----------------------------------------------------------------------
--
-- TIMELINE UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Timeline:show() -> Timeline
--- Method
--- Show's the Timeline on the Primary Display.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `Timeline` object.
function Timeline:show()
    if not self:isShowing() then
        self:showOnPrimary()
    end
    return self
end

function Timeline.lazy.method:doShow()
    return If(self.isShowing):Is(false)
    :Then(self:doShowOnPrimary())
    :Otherwise(true)
    :Label("Timeline:doShow")
end

--- cp.apple.finalcutpro.main.Timeline:showOnPrimary() -> Timeline
--- Method
--- Show's the Timeline on the Primary Display.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `Timeline` object.
function Timeline:showOnPrimary()
    local menu = self:app():menu()

    -- if the timeline is on the secondary, we need to turn it off before enabling in primary
    if self:isOnSecondary() then
        menu:selectMenu({"Window", "Show in Secondary Display", "Timeline"})
    end
    -- Then enable it in the primary
    if not self:isOnPrimary() then
        menu:selectMenu({"Window", "Show in Workspace", "Timeline"})
    end

    return self
end

--- cp.apple.finalcutpro.main.Timeline:doShowOnPrimary() -> cp.rx.go.Statement <boolean>
--- Method
--- Returns a `Statement` that will ensure the timeline is in the primary window.
---
--- Parameters:
---  * timeout  - The timeout period for the operation.
---
--- Returns:
---  * A `Statement` which will send `true` if it successful, or `false` otherwise.
function Timeline.lazy.method:doShowOnPrimary()
    local menu = self:app():menu()

    return If(self:app().isRunning):Then(
        Do(
            If(self.isOnSecondary):Then(
                menu:doSelectMenu({"Window", "Show in Secondary Display", "Timeline"})
            )
        )
        :Then(
            If(self.isOnPrimary):Is(false):Then(
                Do(menu:doSelectMenu({"Window", "Show in Workspace", "Timeline"}))
                :Then(WaitUntil(self.isOnPrimary):TimeoutAfter(5000))
            ):Otherwise(true)
        )
    ):Otherwise(false)
    :Label("Timeline:doShowOnPrimary")
end

--- cp.apple.finalcutpro.main.Timeline:showOnSecondary() -> Timeline
--- Method
--- Show's the Timeline on the Secondary Display.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `Timeline` object.
function Timeline:showOnSecondary()
    local menu = self:app():menu()

    -- if the timeline is on the secondary, we need to turn it off before enabling in primary
    if not self:isOnSecondary() then
        menu:selectMenu({"Window", "Show in Secondary Display", "Timeline"})
    end

    return self
end


--- cp.apple.finalcutpro.main.Timeline:doShowOnSecondary() -> cp.rx.go.Statement <boolean>
--- Method
--- Returns a `Statement` that will ensure the timeline is in the secondary window.
---
--- Parameters:
---  * timeout  - The timeout period for the operation.
---
--- Returns:
---  * A `Statement` which will send `true` if it successful, or `false` otherwise.
function Timeline.lazy.method:doShowOnSecondary()
    local menu = self:app():menu()

    return If(self:app().isRunning):Then(
        If(self.isOnSecondary):Is(false)
        :Then(menu:doSelectMenu({"Window", "Show in Secondary Display", "Timeline"}))
        :Then(WaitUntil(self.isOnSecondary):TimeoutAfter(5000))
        :Otherwise(true)
    ):Otherwise(false)
    :Label("Timeline:doShowOnSecondary")
end

--- cp.apple.finalcutpro.main.Timeline:hide() -> Timeline
--- Method
--- Hide's the Timeline (regardless of whether it was on the Primary or Secondary display).
---
--- Parameters:
---  * None
---
--- Returns:
---  * `Timeline` object.
function Timeline:hide()
    local menu = self:app():menu()
    -- Uncheck it from the primary workspace
    if self:isOnSecondary() then
        menu:selectMenu({"Window", "Show in Secondary Display", "Timeline"})
    end
    if self:isOnPrimary() then
        menu:selectMenu({"Window", "Show in Workspace", "Timeline"})
    end
    return self
end

--- cp.apple.finalcutpro.main.Timeline:doHide() -> cp.rx.go.Statement
--- Method
--- Returns a `Statement` that will hide the Timeline (regardless of whether it
--- was on the Primary or Secondary window).
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Statement` ready to run.
function Timeline.lazy.method:doHide()
    local menu = self:app():menu()

    return If(self:app().isRunning):Then(
        Do(
            If(self.isOnSecondary):Then(
                menu:doSelectMenu({"Window", "Show in Secondary Display", "Timeline"})
            )
            :Then(WaitUntil(self.isOnSecondary:NOT()):TimeoutAfter(5000))
        )
        :Then(
            If(self.isOnPrimary):Then(
                menu:doSelectMenu({"Window", "Show in Workspace", "Timeline"})
            )
            :Then(WaitUntil(self.isOnPrimary:NOT()):TimeoutAfter(5000))
            :Otherwise(true)
        )
    ):Otherwise(false)
    :Label("Timeline:doHide")
end

--- cp.apple.finalcutpro.main.TimelineContents:doFocus(show) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) which will focus on the `TimelineContents`.
---
--- Parameters:
--- * show      - if `true`, the `TimelineContents` will be shown before focusing.
---
--- Returns:
--- * The `Statement`.
function Timeline:doFocus(show)
    return self:contents():doFocus(show)
    :Label("Timeline:doFocus")
end

-----------------------------------------------------------------------
--
-- CONTENT:
-- The Content is the main body of the timeline, containing the
-- Timeline Index, the Content, and the Effects/Transitions panels.
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Timeline:contents() -> TimelineContent
--- Method
--- Gets the Timeline Contents. The Content is the main body of the timeline,
--- containing the Timeline Index, the Content, and the Effects/Transitions panels.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `TimelineContent` object.
function Timeline.lazy.method:contents()
    return TimelineContent.new(self)
end

-----------------------------------------------------------------------
--
-- EFFECT BROWSER:
-- The (sometimes hidden) Effect Browser.
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Timeline:effects() -> EffectsBrowser
--- Method
--- Gets the (sometimes hidden) Effect Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `EffectsBrowser` object.
function Timeline.lazy.method:effects()
    return EffectsBrowser.new(self, EffectsBrowser.EFFECTS)
end

-----------------------------------------------------------------------
--
-- TRANSITIONS BROWSER:
-- The (sometimes hidden) Transitions Browser.
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Timeline:transitions() -> EffectsBrowser
--- Method
--- Gets the (sometimes hidden) Transitions Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `EffectsBrowser` object.
function Timeline.lazy.method:transitions()
    return EffectsBrowser.new(self, EffectsBrowser.TRANSITIONS)
end

-----------------------------------------------------------------------
--
-- PLAYHEAD:
-- The timeline Playhead.
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Timeline:playhead() -> Playhead
--- Method
--- Gets the Timeline Playhead.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `Playhead` object.
function Timeline:playhead()
    return self:contents():playhead()
end

-----------------------------------------------------------------------
--
-- PLAYHEAD:
-- The Playhead that tracks under the mouse while skimming.
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Timeline:skimmingPlayhead() -> Playhead
--- Method
--- Gets the Playhead that tracks under the mouse while skimming.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `Playhead` object.
function Timeline:skimmingPlayhead()
    return self:contents():skimmingPlayhead()
end

-----------------------------------------------------------------------
--
-- TOOLBAR:
-- The bar at the top of the timeline.
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Timeline:toolbar() -> TimelineToolbar
--- Method
--- Gets the bar at the top of the timeline.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `TimelineToolbar` object.
function Timeline.lazy.method:toolbar()
    return TimelineToolbar.new(self)
end

--- cp.apple.finalcutpro.main.Timeline:title() -> cp.ui.StaticText
--- Method
--- Returns the [StaticText](cp.ui.StaticText.md) containing the title.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `StaticText` object.
function Timeline:title()
    return self:toolbar():title()
end

-----------------------------------------------------------------------
--
-- INDEX:
-- The Timeline Index.
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Timeline:index() -> TimelineIndex
--- Method
--- The [TimelineIndex](cp.apple.finalcutpro.main.TimelineIndex.md).
---
--- Parameters:
---  * None
---
--- Returns:
---  * `TimelineIndex` object.
function Timeline.lazy.method:index()
    return TimelineIndex(self)
end

return Timeline
