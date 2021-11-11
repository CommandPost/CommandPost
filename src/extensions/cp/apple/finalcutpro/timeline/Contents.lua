--- === cp.apple.finalcutpro.timeline.Contents ===
---
--- Timeline Contents Module.

local require = require

local log								= require "hs.logger".new("timelineContents")

local fnutils							= require "hs.fnutils"

local i18n                              = require "cp.i18n"
local prop								= require "cp.prop"
local tools                             = require "cp.tools"
local axutils							= require "cp.ui.axutils"

local Element                           = require "cp.ui.Element"
local ScrollArea                        = require "cp.ui.ScrollArea"
local Playhead							= require "cp.apple.finalcutpro.main.Playhead"

local go                                = require "cp.rx.go"
local Do, If, Throw, WaitUntil          = go.Do, go.If, go.Throw, go.WaitUntil
local toObservable                      = go.Statement.toObservable

local emptyList                         = axutils.match.emptyList

local Contents = Element:subclass("cp.apple.finalcutpro.timeline.Contents")

--- cp.apple.finalcutpro.timeline.Contents.matches(element) -> boolean
--- Function
--- Checks if an `axuielementObject` matches the `Contents` type.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if it matches, otherwise `false`.
function Contents.static.matches(element)
    return Element.matches(element)
        and element:attributeValue("AXRole") == "AXLayoutArea"
        and element:attributeValueCount("AXAuditIssues") < 1
end

--- cp.apple.finalcutpro.timeline.Contents(parent) -> Contents
--- Constructor
--- Creates a new Timeline `Contents` instance.
---
--- Parameters:
---  * parent - The parent `Timeline`
---
--- Returns:
---  * A new `Contents` object.
function Contents:initialize(parent)
    self._parent = parent

    local scrollAreaUI = parent.mainUI:mutate(function(original)
        local main = original()
        if main then
            return axutils.childMatching(main, function(child)
                if child:attributeValue("AXRole") == "AXScrollArea" then
                    local contents = child:attributeValue("AXContents")
                    return axutils.childMatching(contents, Contents.matches) ~= nil
                end
                return false
            end)
        end
        return nil
    end)

    local UI = scrollAreaUI:mutate(function(original)
        return axutils.cache(self, "_ui", function()
            local scrollArea = original()
            if scrollArea then
                return axutils.childMatching(scrollArea, Contents.matches)
            end
            return nil
        end,
        Contents.matches)
    end)

    Element.initialize(self, parent, UI)

    prop.bind(self) {

--- cp.apple.finalcutpro.timeline.Contents.scrollAreaUI <cp.prop: hs.axuielement; read-only; live>
--- Field
--- The parent `ScrollArea` UI of the Timeline Contents area.
        scrollAreaUI = scrollAreaUI
    }

    self:app():notifier():watchFor("AXUIElementDestroyed", function() scrollAreaUI:update() end)
    self:app():notifier():watchFor("AXCreated", function() scrollAreaUI:update() end)
end

--- cp.apple.finalcutpro.timeline.Contents.scrollArea <cp.ui.ScrollArea>
--- Field
--- The `ScrollArea` for the Contents element.
function Contents.lazy.value:scrollArea()
    return ScrollArea(self, self.scrollAreaUI)
end

--- cp.apple.finalcutpro.timeline.Contents.viewFrame <cp.prop: table; read-only; live>
--- Field
--- The current 'frame' of the scroll area, inside the scroll bars (if present),  or `nil` if not available.
function Contents.lazy.prop:viewFrame()
    return self.scrollArea.viewFrame
end

--- cp.apple.finalcutpro.timeline.Contents.viewFrame <cp.prop: table; read-only; live>
--- Field
--- The current 'frame' of the internal timeline content,  or `nil` if not available.
function Contents.lazy.prop:timelineFrame()
    return axutils.prop(self.UI, "AXFrame")
end

--- cp.apple.finalcutpro.timeline.Contents.children <cp.prop: table; read-only; live>
--- Field
--- The current set of child elements in the Contents.
function Contents.lazy.prop:children()
    return axutils.prop(self.UI, "AXChildren")
    :preWatch(function(_, theProp)
        self:app():notifier():watchFor("AXUIElementDestroyed", function()
            theProp:update()
        end)
    end)
end

--- cp.apple.finalcutpro.timeline.Contents.selectedChildren <cp.prop: table; read-only; live>
--- Field
--- The current set of selected child elements in the Contents.
function Contents.lazy.prop:selectedChildren()
    return axutils.prop(self.UI, "AXSelectedChildren", true)
    :preWatch(function(_, theProp)
        self:app():notifier():watchFor("AXUIElementDestroyed", function()
            theProp:update()
        end)
    end)
end

--- cp.apple.finalcutpro.timeline.Contents.isLoaded <cp.prop: booelan; read-only; live>
--- Field
--- Checks if the Timeline has content loaded.
function Contents.lazy.prop:isLoaded()
    return self.scrollAreaUI:ISNOT(nil)
end

-----------------------------------------------------------------------
--
-- TIMELINE CONTENT UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Contents:show()
    self:parent():show()
    return self
end

--- cp.apple.finalcutpro.timeline.Contents:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to show the Timeline Contents.
---
--- Parameters:
---  * None
---
--- Returns:
--- * The `Statement`.
function Contents.lazy.method:doShow()
    return self:parent():doShow()
end

-- TODO: Add documentation
function Contents:hide()
    self:parent():hide()
    return self
end

--- cp.apple.finalcutpro.timeline.Contents:doHide() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to hide the Timeline Contents.
---
--- Parameters:
---  * None
---
--- Returns:
--- * The `Statement`.
function Contents.lazy.method:doHide()
    return self:parent():doHide()
end

-----------------------------------------------------------------------
--
-- PLAYHEAD:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.timeline.Contents.playhead <cp.apple.finalcutpro.main.Playhead>
--- Field
--- The main Playhead.
function Contents.lazy.value:playhead()
    return Playhead(self, false, self.UI)
end

--- cp.apple.finalcutpro.timeline.Contents.skimmingPlayhead <cp.apple.finalcutpro.main.Playhead>
--- Field
--- The Playhead that tracks with the mouse pointer.
function Contents.lazy.value:skimmingPlayhead()
    return Playhead(self, true, self.UI)
end


--- cp.apple.finalcutpro.timeline.Contents:activePlayhead() -> Playhead
--- Method
--- Returns the active Playhead. If the Skimming Playhead is available, return that, otherwise, return the normal Playhead.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The active `Playhead`.
function Contents:activePlayhead()
    return self.skimmingPlayhead:isShowing() and self.skimmingPlayhead or self.playhead
end

-----------------------------------------------------------------------
--
-- VIEWING AREA:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Contents:shiftHorizontalTo(value)
    return self.scrollArea:shiftHorizontalTo(value)
end

function Contents:shiftHorizontalToX(x)
    -- update the scrollbar position
    local timelineFrame = self:timelineFrame()
    local scrollWidth = timelineFrame.w - self:viewFrame().w
    local scrollPoint = timelineFrame.x*-1 + x

    local scrollTarget = scrollPoint/scrollWidth

    self:shiftHorizontalTo(scrollTarget)
end

-----------------------------------------------------------------------
--
-- CLIPS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.timeline.Contents:selectedClipsUI(expandedGroups, filterFn) -> table of axuielements
--- Method
--- Returns a table containing the list of selected clips.
---
--- If `expandsGroups` is true any AXGroup items will be expanded to the list of contained AXLayoutItems.
---
--- If `filterFn` is provided it will be called with a single argument to check if the provided
--- clip should be included in the final table.
---
--- Parameters:
---  * expandGroups	- (optional) if true, expand AXGroups to include contained AXLayoutItems
---  * filterFn		- (optional) if provided, the function will be called to check each clip
---
--- Returns:
---  * The table of selected axuielements that match the conditions
function Contents:selectedClipsUI(expandGroups, filterFn)
    local clips = self:selectedChildren()
    if clips then
        return self:_filterClips(clips, expandGroups, filterFn)
    end
    return {}
end

--- cp.apple.finalcutpro.timeline.Contents:clipsUI(expandedGroups, filterFn) -> table of axuielements
--- Function
--- Returns a table containing the list of clips in the Timeline.
---
--- If `expandsGroups` is true any AXGroup items will be expanded to the list of contained AXLayoutItems.
---
--- If `filterFn` is provided it will be called with a single argument to check if the provided
--- clip should be included in the final table.
---
--- Parameters:
---  * expandGroups	- (optional) if true, expand AXGroups to include contained AXLayoutItems
---  * filterFn		- (optional) if provided, the function will be called to check each clip
---
--- Returns:
---  * The table of axuielements that match the conditions
function Contents:clipsUI(expandGroups, filterFn)
    local children = self:children()
    if children then
        local clips = fnutils.filter(children, function(child)
            local role = child:attributeValue("AXRole")
            return role == "AXLayoutItem" or role == "AXGroup"
        end)
        return self:_filterClips(clips, expandGroups, filterFn)
    end
    return nil
end

--- cp.apple.finalcutpro.timeline.Contents:rangeSelectionUI() -> axuielements
--- Method
--- Returns the UI for the current 'Range Selection', if present.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The 'Range Selection' UI or `nil`
function Contents:rangeSelectionUI()
    local ui = self:UI()
    if ui then
        local rangeSelectionDescription = self:app():string("FFTimelineRangeSelectionAccessibilityDescription")
        return axutils.childWithDescription(ui, rangeSelectionDescription)
    end
    return nil
end

--- cp.apple.finalcutpro.timeline.Contents:positionClipsUI(position, expandedGroups, filterFn) -> table of axuielements
--- Function
--- Returns a table array containing the list of clips in the Timeline at the specified `position`, ordered with the
--- highest clips at the beginning of the array.
---
--- If `expandsGroups` is `true` any `AXGroup` items will be expanded to the list of contained `AXLayoutItems`.
---
--- If `filterFn` is provided it will be called with a single argument to check if the provided
--- clip should be included in the final table.
---
--- Parameters:
---  * position     - The `X` (or horizontal) position value to find clips under.
---  * expandGroups	- (optional) if true, expand AXGroups to include contained AXLayoutItems
---  * filterFn		- (optional) if provided, the function will be called to check each clip
---
--- Returns:
---  * The table of axuielements that match the conditions
function Contents:positionClipsUI(position, expandGroups, filterFn)
    local clips = self:clipsUI(expandGroups, function(clip)
        local frame = clip.AXFrame
        return frame and position >= frame.x and position <= (frame.x + frame.w)
           and (filterFn == nil or filterFn(clip))
    end)
    if not clips then return nil end

    table.sort(clips, function(a, b) return a.AXPosition.y < b.AXPosition.y end)
    return clips
end

--- cp.apple.finalcutpro.timeline.Contents:playheadClipsUI(expandedGroups, filterFn) -> table of axuielements
--- Function
--- Returns a table array containing the list of clips in the Timeline under the playhead, ordered with the
--- highest clips at the beginning of the array.
---
--- If `expandsGroups` is true any AXGroup items will be expanded to the list of contained `AXLayoutItems`.
---
--- If `filterFn` is provided it will be called with a single argument to check if the provided
--- clip should be included in the final table.
---
--- Parameters:
---  * expandGroups	- (optional) if true, expand AXGroups to include contained AXLayoutItems
---  * filterFn		- (optional) if provided, the function will be called to check each clip
---
--- Returns:
---  * The table of axuielements that match the conditions
function Contents:playheadClipsUI(expandGroups, filterFn)
    return self:positionClipsUI(self.playhead:position(), expandGroups, filterFn)
end

--- cp.apple.finalcutpro.timeline.Contents:skimmingPlayheadClipsUI(expandedGroups, filterFn) -> table of axuielements
--- Function
--- Returns a table array containing the list of clips in the Timeline under the skimming playhead, ordered with the
--- highest clips at the beginning of the array.
---
--- If `expandsGroups` is true any AXGroup items will be expanded to the list of contained `AXLayoutItems`.
---
--- If `filterFn` is provided it will be called with a single argument to check if the provided
--- clip should be included in the final table.
---
--- Parameters:
---  * expandGroups	- (optional) if true, expand AXGroups to include contained AXLayoutItems
---  * filterFn		- (optional) if provided, the function will be called to check each clip
---
--- Returns:
---  * The table of axuielements that match the conditions
function Contents:skimmingPlayheadClipsUI(expandGroups, filterFn)
    return self:positionClipsUI(self.skimmingPlayhead:position(), expandGroups, filterFn)
end

-- cp.apple.finalcutpro.timeline.Contents:_filterClips(clips, expandGroups, filterFn) -> table of axuielements
-- Method
-- Filters the provided clips table, expanding any AXGroup items if `expandGroups` is true.
--
-- If `filterFn` is provided it will be called with a single argument to check if the provided
-- clip should be included in the final table.
--
-- Parameters:
--  * clips         - The table of axuielements to filter.
--  * expandGroups	- (optional) if true, expand AXGroups to include contained AXLayoutItems
--  * filterFn		- (optional) if provided, the function will be called to check each clip
--
-- Returns:
--  * The table of axuielements that match the conditions
function Contents:_filterClips(clips, expandGroups, filterFn)
    if expandGroups then
        return self:_expandClips(clips, filterFn)
    elseif type(filterFn) == "function" and type(clips) == "table" then
        return fnutils.filter(clips, filterFn)
    else
        return clips
    end
end

-- cp.apple.finalcutpro.timeline.Contents:_expandClips(clips, filterFn) -> table of axuielements
-- Method
-- Expands any AXGroup items in the provided clips table, and filters the results.
--
-- If `filterFn` is provided it will be called with a single argument to check if the provided
-- clip should be included in the final table.
--
-- Parameters:
--  * clips         - The table of axuielements to filter.
--  * filterFn		- (optional) if provided, the function will be called to check each clip
--
-- Returns:
--  * The table of axuielements that match the conditions
function Contents:_expandClips(clips, filterFn)
    return fnutils.mapCat(clips, function(child)
        local role = child:attributeValue("AXRole")
        if role == "AXLayoutItem" then
            if filterFn == nil or filterFn(child) then
                return {child}
            end
        elseif role == "AXGroup" then
            return self:_expandClips(child:attributeValue("AXChildren"), filterFn)
        end
        return {}
    end)
end

function Contents:selectNone()
    local ui = self:UI()
    if ui then
        self:app():selectMenu({"Edit", "Deselect All"})
    end
end

-- TODO: Add documentation
function Contents:selectClips(clipsUI)
    local ui = self:UI()
    if ui then
        local selectedClips = {}
        for i,clip in ipairs(clipsUI) do
            selectedClips[i] = clip
        end
        ui:setAttributeValue("AXSelectedChildren", selectedClips)
    end
    return self
end

-- TODO: Add documentation
function Contents:selectClip(clipUI)
    return self:selectClips({clipUI})
end

-- containsOnly(values) -> function
-- Function
-- Returns a "match" function which will check its input value to see if it is a table which contains the same values in any order.
--
-- Parameters:
-- * values     - A [Set](cp.collect.Set.md) or `table` specifying exactly what items must be in the matching table, in any order.
--
-- Returns:
-- * A `function` that will accept a single input value, which will only return `true` the input is a `table` containing exactly the items in `values` in any order.
local function containsOnly(values)
    return function(other)
        if other and values and #other == #values then
            for _,v in ipairs(other) do
                if not tools.tableContains(values, v) then
                    return false
                end
            end
            return true
        end
        return false
    end
end

--- cp.apple.finalcutpro.timeline.Contents:doSelectNone() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will clear any clip selection.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md)
function Contents.lazy.method:doSelectNone()
    return If(self.selectedChildren):Then(function(selectedChildren)
        if #selectedChildren > 0 then
            return Do(self:doFocus())
            :Then(self:app():doSelectMenu({"Edit", "Deselect All"}))
        end
        return true
    end)
    :Then(WaitUntil(self.selectedChildren):Matches(emptyList))
    :TimeoutAfter(2000)
    :Label("cp.apple.finalcutpro.timeline.contents:doSelectNone()")
end

--- cp.apple.finalcutpro.timeline.Contents:doSelectClips(clipsUI) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) which will select the specified list of `hs.axuielement` values in the Timeline Contents area.
---
--- Parameters:
--- * clipsUI       - The table of `hs._asm.axuilement` values to select.
---
--- Returns:
--- * A [Statement](cp.rx.go.Statement.md) that will select the clips or throw an error if there is an issue.
function Contents:doSelectClips(clipsUI)
    return If(self.isShowing)
    :Then(function()
        if not clipsUI or #clipsUI == 0 then
            return self:doSelectNone()
        end
        local selectedClips = {}
        for i,clip in ipairs(clipsUI) do
            selectedClips[i] = clip
        end
        self:selectedChildren(selectedClips)
        return true
    end)
    :Then(WaitUntil(self.selectedChildren):Matches(containsOnly(clipsUI)))
    :TimeoutAfter(5000)
    :Label("cp.apple.finalcutpro.timeline.Contents:doSelectClips(clipsUI)")
end

--- cp.apple.finalcutpro.timeline.Contents:doSelectClip(clipUI) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) which will select the specified single `hs.axuielement` value in the Timeline Contents area.
---
--- Parameters:
--- * clipUI       - The `hs._asm.axuilement` values to select.
---
--- Returns:
--- * A [Statement](cp.rx.go.Statement.md) that will select the clip or throw an error if there is an issue.
function Contents:doSelectClip(clipUI)
    return If(self.isShowing)
    :Then(function()
        if not clipUI then
            return self:doSelectNone()
        end
        return self:doSelectClips({clipUI})
    end)
    :Label("cp.apple.finalcutpro.timeline.Contents:doSelectClip(clipUI)")
end


--- cp.apple.finalcutpro.timeline.Contents:doSelectTopClip([position]) -> cp.rx.go.Statement
--- Method
--- Creates a [Statement](cp.rx.go.Statement.md) that will select the top clip at the given position,
--- resolving to the top clip if available.
---
--- Parameters:
---  * position - (optional) The position `table` to select the top clip at.
---     If not provided, the current active playhead position is used.
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement)
function Contents:doSelectTopClip(position)
    return Do(function()
        position = position or self:activePlayhead():position()

        local clipsUI = self:positionClipsUI(position)
        if not clipsUI or #clipsUI == 0 then
            return Throw(i18n("doSelectTopClip_noclips_error"))
        end

        local topClip = clipsUI[1]
        return Do(self:doSelectClip(topClip))
        :Then(toObservable(topClip))
    end)
    :Label("cp.apple.finalcutpro.timeline.Contents:doSelectTopClip(position)")
end

--- cp.apple.finalcutpro.timeline.Contents:doFocus(show) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) which will focus on the `Contents`.
---
--- Parameters:
--- * show      - if `true`, the `Contents` will be shown before focusing.
---
--- Returns:
--- * The `Statement`.
function Contents:doFocus(show)
    show = show or false
    local menu = self:app().menu

    return Do(If(show):Then(self:doShow()))
    :Then(
        If(self.isFocused):Is(false):Then(
            menu:doSelectMenu({"Window", "Go To", "Timeline"}) --:Debug("Go To Timeline")
        )
        :Then(WaitUntil(self.isFocused):TimeoutAfter(2000))
        :Otherwise(true)
    )
    :Label("cp.apple.finalcutpro.timeline.Contents:doFocus(show)")
end

-----------------------------------------------------------------------
--
-- MULTICAM ANGLE EDITOR:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Contents:anglesUI()
    return self:clipsUI()
end

-- TODO: Add documentation
function Contents:angleButtonsUI(angleNumber)
    local angles = self:anglesUI()
    if angles then
        local angle = angles[angleNumber]
        if angle then
            return axutils.childrenWithRole(angle, "AXButton")
        end
    end
    return nil
end

-- TODO: Add documentation
function Contents:monitorVideoInAngle(angleNumber)
    local buttons = self:angleButtonsUI(angleNumber)
    if buttons and buttons[1] then
        buttons[1]:performAction("AXPress")
    end
end

-- TODO: Add documentation
function Contents:toggleAudioInAngle(angleNumber)
    local buttons = self:angleButtonsUI(angleNumber)
    if buttons and buttons[2] then
        buttons[2]:performAction("AXPress")
    end
end

-- TODO: Add documentation
-- Selects the clip under the playhead in the specified angle.
-- NOTE: This will only work in multicam clips
function Contents:selectClipInAngle(angleNumber)
    local clipsUI = self:anglesUI()
    if clipsUI then
        local angleUI = clipsUI[angleNumber]

        local playheadPosition = self.playhead:position()
        local clipUI = axutils.childMatching(angleUI, function(child)
            local frame = child:attributeValue("AXFrame")
            return child:attributeValue("AXRole") == "AXLayoutItem"
               and frame.x <= playheadPosition and (frame.x+frame.w) >= playheadPosition
        end)

        self:monitorVideoInAngle(angleNumber)

        if clipUI then
            self:selectClip(clipUI)
        else
            log.df("Unable to find the clip under the playhead for angle "..angleNumber..".")
        end
    end
    return self
end

return Contents
