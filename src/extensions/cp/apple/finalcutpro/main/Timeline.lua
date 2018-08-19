--- === cp.apple.finalcutpro.main.Timeline ===
---
--- Timeline Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local require = require
--local log								= require("hs.logger").new("timeline")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils							= require("cp.ui.axutils")
local prop								= require("cp.prop")

local id								= require("cp.apple.finalcutpro.ids") "Timeline"

local EffectsBrowser					= require("cp.apple.finalcutpro.main.EffectsBrowser")
local PrimaryWindow						= require("cp.apple.finalcutpro.main.PrimaryWindow")
local SecondaryWindow					= require("cp.apple.finalcutpro.main.SecondaryWindow")
local TimelineContent					= require("cp.apple.finalcutpro.main.TimelineContents")
local TimelineToolbar					= require("cp.apple.finalcutpro.main.TimelineToolbar")

local go                                = require("cp.rx.go")
local Do, If, WaitUntil                 = go.Do, go.If, go.WaitUntil

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Timeline = {}

--- cp.apple.finalcutpro.main.Timeline.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`.
function Timeline.matches(element)
    return element:attributeValue("AXRole") == "AXGroup"
       and axutils.childWith(element, "AXIdentifier", id "Contents") ~= nil
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
function Timeline.matchesMain(element)
    return element:attributeValue("AXIdentifier") == id "Contents"
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
function Timeline._findTimeline(...)
    for i = 1,select("#", ...) do
        local window = select(i, ...)
        if window then
            local ui = window:timelineGroupUI()
            if ui then
                local timeline = axutils.childMatching(ui, Timeline.matches)
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
function Timeline.new(app)

    local o = prop.extend({
        _app = app,
    },	Timeline)

    local UI = app.UI:mutate(function(_, self)
        return axutils.cache(self, "_ui", function()
            return Timeline._findTimeline(app:secondaryWindow(), app:primaryWindow())
        end,
        Timeline.matches)
    end):monitor(app:primaryWindow().UI, app:secondaryWindow().UI)

    prop.bind(o) {

        --- cp.apple.finalcutpro.main.Timeline.UI <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- Returns the `axuielement` representing the 'timeline', or `nil` if not available.
        UI = UI,

        --- cp.apple.finalcutpro.main.Timeline.isOnSecondary <cp.prop: boolean; read-only>
        --- Field
        --- Checks if the Timeline is on the Secondary Display.
        isOnSecondary = UI:mutate(function(original)
            local ui = original()
            return ui ~= nil and SecondaryWindow.matches(ui:window())
        end),

        --- cp.apple.finalcutpro.main.Timeline.isOnPrimary <cp.prop: boolean; read-only>
        --- Field
        --- Checks if the Timeline is on the Primary Display.
        isOnPrimary = UI:mutate(function(original)
            local ui = original()
            return ui ~= nil and PrimaryWindow.matches(ui:window())
        end),

        --- cp.apple.finalcutpro.main.Timeline.isShowing <cp.prop: boolean; read-only>
        --- Field
        --- Checks if the Timeline is showing on either the Primary or Secondary display.
        isShowing = UI:mutate(function(original)
            local ui = original()
            return ui ~= nil and #ui > 0
        end),

        --- cp.apple.finalcutpro.main.Timeline.mainUI <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- Returns the `axuielement` representing the 'timeline', or `nil` if not available.
        mainUI = UI:mutate(function(original, self)
            return axutils.cache(self, "_main", function()
                local ui = original()
                return ui and axutils.childMatching(ui, Timeline.matchesMain)
            end,
            Timeline.matchesMain)
        end),

        --- cp.apple.finalcutpro.main.Timeline.isPlaying <cp.prop: boolean>
        --- Field
        --- Is the timeline playing?
        isPlaying = app:viewer().isPlaying:mutate(function(original)
            return original()
        end),

        --- cp.apple.finalcutpro.main.Timeline.isLockedPlayhead <cp.prop: boolean>
        --- Field
        --- Is Playhead Locked?
        isLockedPlayhead = prop.new(function(self)
            return self._locked == true
        end),

        --- cp.apple.finalcutpro.main.Timeline.isLockedInCentre <cp.prop: boolean>
        --- Field
        --- Is Playhead Locked in the centre?
        isLockedInCentre = prop.new(function(self)
            return self._lockInCentre == true
        end),
    }

    -- These are bound separately because TimelineContents uses `UI` and `mainUI`
    prop.bind(o) {
        --- cp.apple.finalcutpro.main.Timeline.isLoaded <cp.prop: boolean; read-only>
        --- Field
        --- Checks if the Timeline has finished loading.
        isLoaded = o:contents().isLoaded,

        --- cp.apple.finalcutpro.main.Timeline.isFocused <cp.prop: boolean; read-only>
        --- Field
        --- Checks if the Timeline is the focused panel.
        isFocused = o:contents().isFocused,
    }

    return o
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
    return self._app
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

function Timeline:doShow()
    return If(self.isShowing):Is(false)
    :Then(self:doShowOnPrimary())
    :Otherwise(false)
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
function Timeline:doShowOnPrimary()
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
function Timeline:doShowOnSecondary()
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
function Timeline:doHide()
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
function Timeline:contents()
    if not self._content then
        self._content = TimelineContent.new(self)
    end
    return self._content
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
function Timeline:effects()
    if not self._effects then
        self._effects = EffectsBrowser.new(self, EffectsBrowser.EFFECTS)
    end
    return self._effects
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
function Timeline:transitions()
    if not self._transitions then
        self._transitions = EffectsBrowser.new(self, EffectsBrowser.TRANSITIONS)
    end
    return self._transitions
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
function Timeline:toolbar()
    if not self._toolbar then
        self._toolbar = TimelineToolbar.new(self)
    end
    return self._toolbar
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

return Timeline
