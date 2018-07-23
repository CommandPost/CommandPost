--- === cp.apple.finalcutpro.main.TimelineContents ===
---
--- Timeline Contents Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local require = require
local log								= require("hs.logger").new("timelineContents")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fnutils							= require("hs.fnutils")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")

local Playhead							= require("cp.apple.finalcutpro.main.Playhead")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TimelineContents = {}

-- TODO: Add documentation
function TimelineContents.matches(element)
    return element
        and element:attributeValue("AXRole") == "AXLayoutArea"
        and element:attributeValueCount("AXAuditIssues") < 1
end

-- TODO: Add documentation
function TimelineContents.new(parent)
    local o = prop.extend({
        _parent = parent
    }, TimelineContents)

    -- TODO: Add documentation
    local scrollAreaUI = parent.mainUI:mutate(function(original)
        local main = original()
        if main then
            return axutils.childMatching(main, function(child)
                if child:attributeValue("AXRole") == "AXScrollArea" then
                    local contents = child:attributeValue("AXContents")
                    return axutils.childMatching(contents, TimelineContents.matches) ~= nil
                end
                return false
            end)
        end
        return nil
    end)
    o:app():notifier():watchFor("AXUIElementDestroyed", function() scrollAreaUI:update() end)
    o:app():notifier():watchFor("AXCreated", function() scrollAreaUI:update() end)

    -- TODO: Add documentation
    local UI = scrollAreaUI:mutate(function(original, self)
        return axutils.cache(self, "_ui", function()
            local scrollArea = original()
            if scrollArea then
                return axutils.childMatching(scrollArea, TimelineContents.matches)
            end
            return nil
        end,
        TimelineContents.matches)
    end)

    local isFocused = UI:mutate(function(original)
        local ui = original()
        return ui ~= nil and ui:attributeValue("AXFocused") == true
    end)

    local horizontalScrollBarUI = scrollAreaUI:mutate(function(original)
        local ui = original()
        return ui and ui:attributeValue("AXHorizontalScrollBar")
    end)

    local verticalScrollBarUI = scrollAreaUI:mutate(function(original)
        local ui = original()
        return ui and ui:attributeValue("AXVerticalScrollBar")
    end)

    local viewFrame = scrollAreaUI:mutate(function(original)
        local ui = original()

        if not ui then return nil end

        local hScroll = horizontalScrollBarUI()
        local vScroll = verticalScrollBarUI()

        local frame = ui:frame()

        if hScroll then
            frame.h = frame.h - hScroll:frame().h
        end

        if vScroll then
            frame.w = frame.w - vScroll:frame().w
        end
        return frame
    end):monitor(horizontalScrollBarUI, verticalScrollBarUI)

    local timelineFrame = UI:mutate(function(original)
        local ui = original()
        return ui and ui:frame()
    end)

    prop.bind(o) {
--- cp.apple.finalcutpro.main.TimelineContents.UI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The main UI of the Timeline Contents area.
        UI = UI,

--- cp.apple.finalcutpro.main.TimelineContents.scrollAreaUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The parent `ScrollArea` UI of the Timeline Contents area.
        scrollAreaUI = scrollAreaUI,

--- cp.apple.finalcutpro.main.TimelineContents.isShowing <cp.prop: booelan; read-only; live>
--- Field
--- Checks if the Timeline is currently showing.
        isShowing = UI:ISNOT(nil),

--- cp.apple.finalcutpro.main.TimelineContents.isLoaded <cp.prop: booelan; read-only; live>
--- Field
--- Checks if the Timeline has content loaded.
        isLoaded = scrollAreaUI:ISNOT(nil),

--- cp.apple.finalcutpro.main.TimelineContents.isFocused <cp.prop: booelan; read-only>
--- Field
--- Checks if the Timeline is currently the focused panel.
        isFocused = isFocused,

--- cp.apple.finalcutpro.main.TimelineContents.horizontalScrollBarUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The `AXHorizontalScrolLbar` for the Timeline Contents area.
        horizontalScrollBarUI = horizontalScrollBarUI,

--- cp.apple.finalcutpro.main.TimelineContents.verticalScrollBarUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The `AXVerticalScrollBar` for the Timeline Contents area.
        verticalScrollBarUI = verticalScrollBarUI,

--- cp.apple.finalcutpro.main.TimelineContents.viewFrame <cp.prop: table; read-only; live>
--- Field
--- The current 'frame' of the scroll area, inside the scroll bars (if present),  or `nil` if not available.
        viewFrame = viewFrame,

--- cp.apple.finalcutpro.main.TimelineContents.viewFrame <cp.prop: table; read-only; live>
--- Field
--- The current 'frame' of the internal timeline content,  or `nil` if not available.
        timelineFrame = timelineFrame,
    }

    return o
end

-- TODO: Add documentation
function TimelineContents:parent()
    return self._parent
end

-- TODO: Add documentation
function TimelineContents:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- TIMELINE CONTENT UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function TimelineContents:show()
    self:parent():show()
    return self
end

-- TODO: Add documentation
function TimelineContents:hide()
    self:parent():hide()
    return self
end

-----------------------------------------------------------------------
--
-- PLAYHEAD:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function TimelineContents:playhead()
    if not self._playhead then
        self._playhead = Playhead.new(self, false, self.UI)
    end
    return self._playhead
end

-- TODO: Add documentation
function TimelineContents:skimmingPlayhead()
    if not self._skimmingPlayhead then
        self._skimmingPlayhead = Playhead.new(self, true, self.UI)
    end
    return self._skimmingPlayhead
end

-----------------------------------------------------------------------
--
-- VIEWING AREA:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function TimelineContents:scrollHorizontalBy(shift)
    local ui = self:horizontalScrollBarUI()
    if ui then
        local indicator = ui[1]
        local value = indicator:attributeValue("AXValue")
        indicator:setAttributeValue("AXValue", value + shift)
    end
end

-- TODO: Add documentation
function TimelineContents:scrollHorizontalTo(value)
    local ui = self:horizontalScrollBarUI()
    if ui then
        local indicator = ui[1]
        value = math.max(0, math.min(1, value))
        if indicator:attributeValue("AXValue") ~= value then
            indicator:setAttributeValue("AXValue", value)
        end
    end
end

function TimelineContents:scrollHorizontalToX(x)
    -- update the scrollbar position
    local timelineFrame = self:timelineFrame()
    local scrollWidth = timelineFrame.w - self:viewFrame().w
    local scrollPoint = timelineFrame.x*-1 + x

    local scrollTarget = scrollPoint/scrollWidth

    self:scrollHorizontalTo(scrollTarget)
end

-- TODO: Add documentation
function TimelineContents:getScrollHorizontal()
    local ui = self:horizontalScrollBarUI()
    return ui and ui[1] and ui[1]:attributeValue("AXValue")
end

-- TODO: Add documentation
function TimelineContents:scrollVerticalBy(shift)
    local ui = self:verticalScrollBarUI()
    if ui then
        local indicator = ui[1]
        local value = indicator:attributeValue("AXValue")
        indicator:setAttributeValue("AXValue", value + shift)
    end
end

-- TODO: Add documentation
function TimelineContents:scrollVerticalTo(value)
    local ui = self:verticalScrollBarUI()
    if ui then
        local indicator = ui[1]
        value = math.max(0, math.min(1, value))
        if indicator:attributeValue("AXValue") ~= value then
            indicator:setAttributeValue("AXValue", value)
        end
    end
end

-- TODO: Add documentation
function TimelineContents:getScrollVertical()
    local ui = self:verticalScrollBarUI()
    return ui and ui[1] and ui[1]:attributeValue("AXValue")
end

-----------------------------------------------------------------------
--
-- CLIPS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.TimelineContents:selectedClipsUI(expandedGroups, filterFn) -> table of axuielements
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
function TimelineContents:selectedClipsUI(expandGroups, filterFn)
    local ui = self:UI()
    if ui then
        local clips = ui:attributeValue("AXSelectedChildren")
        return self:_filterClips(clips, expandGroups, filterFn)
    end
    return nil
end

--- cp.apple.finalcutpro.main.TimelineContents:clipsUI(expandedGroups, filterFn) -> table of axuielements
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
function TimelineContents:clipsUI(expandGroups, filterFn)
    local ui = self:UI()
    if ui then
        local clips = fnutils.filter(ui:children(), function(child)
            local role = child:attributeValue("AXRole")
            return role == "AXLayoutItem" or role == "AXGroup"
        end)
        return self:_filterClips(clips, expandGroups, filterFn)
    end
    return nil
end

--- cp.apple.finalcutpro.main.TimelineContents:rangeSelectionUI() -> axuielements
--- Method
--- Returns the UI for the current 'Range Selection', if present.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The 'Range Selection' UI or `nil`
function TimelineContents:rangeSelectionUI()
    local ui = self:UI()
    if ui then
        local rangeSelectionDescription = self:app():string("FFTimelineRangeSelectionAccessibilityDescription")
        return axutils.childWithDescription(ui, rangeSelectionDescription)
    end
    return nil
end

--- cp.apple.finalcutpro.main.TimelineContents:playheadClipsUI(expandedGroups, filterFn) -> table of axuielements
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
function TimelineContents:playheadClipsUI(expandGroups, filterFn)
    local playheadPosition = self:playhead():position()
    local clips = self:clipsUI(expandGroups, function(clip)
        local frame = clip:frame()
        return frame and playheadPosition >= frame.x and playheadPosition <= (frame.x + frame.w)
           and (filterFn == nil or filterFn(clip))
    end)
    table.sort(clips, function(a, b) return a:position().y < b:position().y end)
    return clips
end

-- TODO: Add documentation
function TimelineContents:_filterClips(clips, expandGroups, filterFn)
    if expandGroups then
        return self:_expandClips(clips, filterFn)
    elseif filterFn ~= nil then
        return fnutils.filter(clips, filterFn)
    else
        return clips
    end
end

-- TODO: Add documentation
function TimelineContents:_expandClips(clips, filterFn)
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

-- TODO: Add documentation
function TimelineContents:selectClips(clipsUI)
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
function TimelineContents:selectClip(clipUI)
    return self:selectClips({clipUI})
end

-----------------------------------------------------------------------
--
-- MULTICAM ANGLE EDITOR:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function TimelineContents:anglesUI()
    return self:clipsUI()
end

-- TODO: Add documentation
function TimelineContents:angleButtonsUI(angleNumber)
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
function TimelineContents:monitorVideoInAngle(angleNumber)
    local buttons = self:angleButtonsUI(angleNumber)
    if buttons and buttons[1] then
        buttons[1]:doPress()
    end
end

-- TODO: Add documentation
function TimelineContents:toggleAudioInAngle(angleNumber)
    local buttons = self:angleButtonsUI(angleNumber)
    if buttons and buttons[2] then
        buttons[2]:doPress()
    end
end

-- TODO: Add documentation
-- Selects the clip under the playhead in the specified angle.
-- NOTE: This will only work in multicam clips
function TimelineContents:selectClipInAngle(angleNumber)
    local clipsUI = self:anglesUI()
    if clipsUI then
        local angleUI = clipsUI[angleNumber]

        local playheadPosition = self:playhead():position()
        local clipUI = axutils.childMatching(angleUI, function(child)
            local frame = child:frame()
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

return TimelineContents
