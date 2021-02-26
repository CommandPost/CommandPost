--- === plugins.finalcutpro.timeline.zoomtoselection ===
---
--- Zoom the Timeline to fit the currently-selected clips.

local require   = require

local fcp       = require "cp.apple.finalcutpro"

local mod = {}

-- SELECTION_BUFFER -> number
-- Constant
-- The number of pixels of buffer space to allow the selection zoom to fit.
local SELECTION_BUFFER = 70

-- DEFAULT_SHIFT -> number
-- Constant
-- Default Shift.
local DEFAULT_SHIFT = 1.0

-- MIN_SHIFT -> number
-- Constant
-- Minimum Shift.
local MIN_SHIFT = 0.025

-- getSelectedWidth(minClip, maxClip) -> number
-- Function
-- Gets the Selected Width.
--
-- Parameters:
--  * minClip - Minimum Clip Width as number
--  * maxClip - Maximum Clip Width as number
--
-- Returns:
--  * Selected Width as number
local function getSelectedWidth(minClip, maxClip)
    return maxClip:attributeValue("AXPosition").x + maxClip:attributeValue("AXSize").w - minClip:attributeValue("AXFrame").x + SELECTION_BUFFER*2
end

-- zoomToFit(minClip, maxClip, shift) -> number
-- Function
-- Zoom to fit.
--
-- Parameters:
--  * minClip - Minimum Clip Width as number
--  * maxClip - Maximum Clip Width as number
--  * shift - Shift as number
--
-- Returns:
--  * Selected Width as number
local function zoomToFit(minClip, maxClip, shift)

    local contents = fcp.timeline.contents
    local appearance = fcp.timeline.toolbar.appearance
    local zoomAmount = appearance.zoomAmount

    local selectedWidth = getSelectedWidth(minClip, maxClip)
    local viewFrame = contents:viewFrame()

    local dir = selectedWidth < viewFrame.w and 1 or -1

    if shift < MIN_SHIFT then
        if dir == -1 then
            --------------------------------------------------------------------------------
            -- We need to zoom back out:
            --------------------------------------------------------------------------------
            shift = MIN_SHIFT
        else
            --------------------------------------------------------------------------------
            -- Too small - bail.
            -- Move to the first clip position:
            --------------------------------------------------------------------------------
            contents:shiftHorizontalToX(minClip:attributeValue("AXPosition").x - SELECTION_BUFFER)
            appearance:hide()
            return
        end
    end

    --------------------------------------------------------------------------------
    -- Show the appearance popup:
    --------------------------------------------------------------------------------
    appearance:show()

    --------------------------------------------------------------------------------
    -- Zoom in until it fits:
    --------------------------------------------------------------------------------
    while dir == 1 and selectedWidth < viewFrame.w or dir == -1 and selectedWidth > viewFrame.w do
        zoomAmount:value(zoomAmount:value() + shift * dir)

        selectedWidth = getSelectedWidth(minClip, maxClip)
        viewFrame = contents:viewFrame()
    end

    --------------------------------------------------------------------------------
    -- Keep zooming, with better precision:
    --------------------------------------------------------------------------------
    zoomToFit(minClip, maxClip, shift/2)
end

--- plugins.finalcutpro.timeline.zoomtoselection.zoomToSelection() -> boolean
--- Method
--- Zooms the view to fit the currently-selected clips.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if there is selected content in the timeline and zooming was successful.
function mod.zoomToSelection()
    local contents = fcp.timeline.contents
    local selectedClips = contents:selectedClipsUI()
    if not selectedClips or #selectedClips == 0 then
        return false
    end

    local minClip, maxClip

    local rangeSelection = contents:rangeSelectionUI()
    if rangeSelection then
        minClip = rangeSelection
        maxClip = rangeSelection
    else
        --------------------------------------------------------------------------------
        -- Find the min/max clip and 'x' value for selected clips:
        --------------------------------------------------------------------------------
        local minX, maxX
        for _,clip in ipairs(selectedClips) do
            local frame = clip:attributeValue("AXFrame")
            if minX == nil or minX > frame.x then
                minX = frame.x
                minClip = clip
            end
            if maxX == nil or maxX < (frame.x + frame.w) then
                maxX = frame.x + frame.w
                maxClip = clip
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Zoom in until it fits, getting more precise as we go:
    --------------------------------------------------------------------------------
    zoomToFit(minClip, maxClip, DEFAULT_SHIFT)

    return true
end

local plugin = {
    id = "finalcutpro.timeline.zoomtoselection",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpZoomToSelection")
        :activatedBy():option():shift("z")
        :whenActivated(mod.zoomToSelection)

    return mod
end

return plugin
