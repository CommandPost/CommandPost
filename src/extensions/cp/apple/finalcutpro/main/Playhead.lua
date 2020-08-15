--- === cp.apple.finalcutpro.main.Playhead ===
---
--- Playhead Module.

local require = require

-- local log                               = require("hs.logger").new("fcpPlayhead")

local geometry                          = require("hs.geometry")

local axutils                           = require("cp.ui.axutils")
local Element                           = require("cp.ui.Element")
local prop                              = require("cp.prop")


local Playhead = Element:subclass("cp.apple.finalcutpro.main.Playhead")

--- cp.apple.finalcutpro.main.Playhead.matches(element) -> boolean
--- Function
--- Checks to see if a GUI element is the Playhead or not
---
--- Parameters:
---  * `element`    - The element you want to check
---
--- Returns:
---  * `true` if the `element` is the Playhead otherwise `false`
function Playhead.static.matches(element)
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
function Playhead.static.find(containerUI, skimming)
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

--- cp.apple.finalcutpro.main.Playhead(parent[, skimming[, containerFn[, useEventViewer]]]) -> Playhead
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
function Playhead:initialize(parent, skimming, containerUI, useEventViewer)
    containerUI = containerUI or parent.UI

    self.isSkimming = prop.THIS(skimming == true):IMMUTABLE():bind(self)
    self._useEventViewer = useEventViewer

    local UI = containerUI:mutate(function(original)
        return axutils.cache(self, "_ui", function()
            return Playhead.find(original(), self:isSkimming())
        end, Playhead.matches)
    end)

    Element.initialize(self, parent, UI)
end

function Playhead.lazy.value:viewer()
    return self:app().viewer
end

function Playhead.lazy.value:eventViewer()
    return self:app().eventViewer
end

--- cp.apple.finalcutpro.main.Playhead.isPersistent <cp.prop: boolean; read-only>
--- Field
--- Is the playhead persistent?
function Playhead.lazy.prop:isPersistent()
    return self.isSkimming:NOT()
end

--- cp.apple.finalcutpro.main.Playhead.frame <cp.prop: hs.geometry.frame; read-only; live?>
--- Field
--- Gets the frame of the playhead.
function Playhead.lazy.prop:frame()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui and ui:frame()
    end)
end

--- cp.apple.finalcutpro.main.Playhead.position <cp.prop; number; read-only; live?>
--- Field
--- Gets the horizontal position of the playhead line, which may be different to the `x` position of the playhead.
function Playhead.lazy.prop:position()
    return self.frame:mutate(function(original)
        local frm = original()
        return frm and (frm.x + frm.w/2 + 1.0)
    end)
end

--- cp.apple.finalcutpro.main.Playhead.center <cp.prop: hs.geometry.point; read-only; live?>
--- Field
--- Gets the centre point (`{x, y}`) of the playhead.
function Playhead.lazy.prop:center()
    return self.frame:mutate(function(original)
        local frm = original()
        return frm and geometry.rect(frm).center
    end)
end

--- cp.apple.finalcutpro.main.Playhead.currentViewer <cp.prop: cp.apple.finalcutpro.viewer.Viewer; read-only; live>
--- Field
--- Represents the current viewer for the playhead. This may be either the primary Viewer or the Event Viewer,
--- depending on the Playhead instance and whether the Event Viewer is enabled.
function Playhead.lazy.prop:currentViewer()
    local currentViewer = prop.new(function()
        if self._useEventViewer and self.eventViewer:isShowing() then
            return self.eventViewer
        else
            return self.viewer
        end
    end)
    if self._useEventViewer then
        currentViewer:monitor(self.eventViewer.isShowing)
    end
    return currentViewer
end

--- cp.apple.finalcutpro.main.Playhead.timecode <cp.prop: string; live?>
--- Field
--- Gets and sets the current timecode.
function Playhead.lazy.prop:timecode()
    local timecode = self.currentViewer:mutate(
        function()
            local ui = self:UI()
            return ui and ui:attributeValue("AXValue")
        end,
        function(newTimecode, original)
            original():timecode(newTimecode)
        end
    ):monitor(self.viewer.timecode)

    if self._useEventViewer then
        timecode:monitor(self.eventViewer.timecode)
    end
    return timecode
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
