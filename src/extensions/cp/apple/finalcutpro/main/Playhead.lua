--- === cp.apple.finalcutpro.main.Playhead ===
---
--- Playhead Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local require = require
-- local log                               = require("hs.logger").new("fcpPlayhead")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local geometry                          = require("hs.geometry")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                           = require("cp.ui.axutils")
local prop                              = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Playhead = {}

--- cp.apple.finalcutpro.main.Playhead.matches(element) -> boolean
--- Function
--- Checks to see if a GUI element is the Playhead or not
---
--- Parameters:
---  * `element`    - The element you want to check
---
--- Returns:
---  * `true` if the `element` is the Playhead otherwise `false`
function Playhead.matches(element)
    return element and element:attributeValue("AXRole") == "AXValueIndicator"
end

--- cp.apple.finalcutpro.main.Playhead.find(containerUI, skimming) -> hs._asm.axuielement object | nil
--- Function
--- Finds the playhead (either persistent or skimming) in the specified container. Defaults to persistent.
---
--- Parameters:
---  * `containerUI` - The container UI
---  * `skimming` - Whether or not you want the skimming playhead as boolean.
---
--- Returns:
---  * The playhead `hs._asm.axuielement` object or `nil` if not found.
function Playhead.find(containerUI, skimming)
    local ui = containerUI
    if ui and #ui > 0 then
        --------------------------------------------------------------------------------
        -- The playhead is typically one of the last two children:
        --------------------------------------------------------------------------------
        local persistentPlayhead = ui[#ui-1]
        local skimmingPlayhead = ui[#ui]
        if not Playhead.matches(persistentPlayhead) then
            persistentPlayhead = skimmingPlayhead
            skimmingPlayhead = nil
            if Playhead.matches(skimmingPlayhead) then
                persistentPlayhead = nil
            end
        end
        if skimming then
            return skimmingPlayhead
        else
            return persistentPlayhead
        end
    end
    return nil
end

--- cp.apple.finalcutpro.main.Playhead.new(parent[, skimming[, containerFn[, useEventViewer]]]) -> Playhead
--- Constructor
--- Constructs a new Playhead
---
--- Parameters:
---  * parent        - The parent object
---  * skimming      - (optional) if `true`, this links to the 'skimming' playhead created under the mouse, if present.
---  * containerUI   - (optional) a `cp.prop` which returns the container axuielement which contains the playheads. If not present, it will use the parent's UI element.
---  * useEventViewer - (optional) if `true`, this will use the Event Viewer's timecode, when available.
---
--- Returns:
---  * The new `Playhead` instance.
function Playhead.new(parent, skimming, containerUI, useEventViewer)
    containerUI = containerUI or parent.UI

    local o = prop.extend({
        _parent = parent,
        isSkimming = prop.THIS(skimming == true):IMMUTABLE(),
        _useEventViewer = useEventViewer,
    }, Playhead)

    local UI = containerUI:mutate(function(original, self)
        return axutils.cache(self, "_ui", function()
            return Playhead.find(original(), self:isSkimming())
        end, Playhead.matches)
    end)

    local frame = UI:mutate(function(original)
        local ui = original()
        return ui and ui:frame()
    end)

    local viewer = o:app():viewer()
    local eventViewer = o:app():eventViewer()

    local currentViewer = prop.new(function()
        if useEventViewer and eventViewer:isShowing() then
            return eventViewer
        else
            return viewer
        end
    end)
    if useEventViewer then
        currentViewer:monitor(eventViewer.isShowing)
    end

    local timecode = currentViewer:mutate(
        function()
            local ui = UI()
            return ui and ui:attributeValue("AXValue")
        end,
        function(newTimecode, original)
            original():timecode(newTimecode)
        end
    ):monitor(viewer.timecode)

    if useEventViewer then
        timecode:monitor(eventViewer.timecode)
    end

    prop.bind(o) {
--- cp.apple.finalcutpro.main.Playhead.UI <cp.prop: hs._asm.axuielement; read-only; live?>
--- Field
--- Returns the `hs._asm.axuielement` object for the Playhead
        UI = UI,

--- cp.apple.finalcutpro.main.Playhead.isShowing <cp.prop: boolean; read-only; live?>
--- Field
--- Is the playhead showing?
        isShowing = UI:ISNOT(nil),

--- cp.apple.finalcutpro.main.Playhead.isPersistent <cp.prop: boolean; read-only>
--- Field
--- Is the playhead persistent?
        isPersistent = o.isSkimming:NOT(),

--- cp.apple.finalcutpro.main.Playhead.frame <cp.prop: hs.geometry.frame; read-only; live?>
--- Field
--- Gets the frame of the playhead.
        frame = frame,

--- cp.apple.finalcutpro.main.Playhead.position <cp.prop; number; read-only; live?>
--- Field
--- Gets the horizontal position of the playhead line, which may be different to the `x` position of the playhead.
        position = frame:mutate(function(original)
            local frm = original()
            return frm and (frm.x + frm.w/2 + 1.0)
        end),

--- cp.apple.finalcutpro.main.Playhead.center <cp.prop: hs.geometry.point; read-only; live?>
--- Field
--- Gets the centre point (`{x, y}`) of the playhead.
        center = frame:mutate(function(original)
            local frm = original()
            return frm and geometry.rect(frm).center
        end),

--- cp.apple.finalcutpro.main.Playhead.currentViewer <cp.prop: cp.apple.finalcutpro.main.Viewer; read-only; live>
--- Field
--- Represents the current viewer for the playhead. This may be either the primary Viewer or the Event Viewer,
--- depending on the Playhead instance and whether the Event Viewer is enabled.
        currentViewer = currentViewer,

--- cp.apple.finalcutpro.main.Playhead.timecode <cp.prop: string; live?>
--- Field
--- Gets and sets the current timecode.
        timecode = timecode,
    }

    return o
end

--- cp.apple.finalcutpro.main.Playhead:parent() -> table
--- Method
--- Returns the Playhead's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function Playhead:parent()
    return self._parent
end

--- cp.apple.finalcutpro.main.Playhead:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function Playhead:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- BROWSER UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Playhead:show() -> Playhead object
--- Method
--- Shows the Playhead
---
--- Parameters:
---  * None
---
--- Returns:
---  * Playhead object
function Playhead:show()
    local parent = self:parent()
    -----------------------------------------------------------------------
    -- Show the parent:
    -----------------------------------------------------------------------
    if parent:show():isShowing() then
        -----------------------------------------------------------------------
        -- Ensure the playhead is visible:
        -----------------------------------------------------------------------
        if parent.viewFrame then
            local viewFrame = parent:viewFrame()
            local position = self:position()
            if position < viewFrame.x or position > (viewFrame.x + viewFrame.w) then
                -----------------------------------------------------------------------
                -- Need to move the scrollbar:
                -----------------------------------------------------------------------
                local timelineFrame = parent:timelineFrame()
                local scrollWidth = timelineFrame.w - viewFrame.w
                local scrollPoint = position - viewFrame.w/2 - timelineFrame.x
                local scrollTarget = scrollPoint/scrollWidth
                parent:scrollHorizontalTo(scrollTarget)
            end
        end
    end
    return self
end

--- cp.apple.finalcutpro.main.Playhead:hide() -> Playhead object
--- Method
--- Hides the Playhead
---
--- Parameters:
---  * None
---
--- Returns:
---  * Playhead object
function Playhead:hide()
    self:parent():hide()
    return self
end

return Playhead
