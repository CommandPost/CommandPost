--- === plugins.finalcutpro.timeline.zoomtoselection ===
---
--- Zoom the Timeline to fit the currently-selected clips.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                               = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.zoomtoselection.SELECTION_BUFFER -> number
--- Constant
--- The number of pixels of buffer space to allow the selection zoom to fit.
mod.SELECTION_BUFFER = 70

--- plugins.finalcutpro.timeline.zoomtoselection.DEFAULT_SHIFT -> number
--- Constant
--- Default Shift.
mod.DEFAULT_SHIFT = 1.0

--- plugins.finalcutpro.timeline.zoomtoselection.MIN_SHIFT -> number
--- Constant
--- Minimum Shift.
mod.MIN_SHIFT = 0.025

-- plugins.finalcutpro.timeline.zoomtoselection._selectedWidth(minClip, maxClip) -> number
-- Function
-- Selected Width
--
-- Parameters:
--  * minClip - Minimum Clip Width as number
--  * maxClip - Maximum Clip Width as number
--
-- Returns:
--  * Selected Width as number
function mod._selectedWidth(minClip, maxClip)
    return maxClip:position().x + maxClip:size().w - minClip:frame().x + mod.SELECTION_BUFFER*2
end

-- plugins.finalcutpro.timeline.zoomtoselection._zoomToFit(minClip, maxClip, shift) -> number
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
function mod._zoomToFit(minClip, maxClip, shift)
    local zoomAmount = mod.zoomAmount
    local selectedWidth = mod._selectedWidth(minClip, maxClip)
    local viewFrame = mod.contents:viewFrame()

    local dir = selectedWidth < viewFrame.w and 1 or -1

    if shift < mod.MIN_SHIFT then
        if dir == -1 then
            --------------------------------------------------------------------------------
            -- We need to zoom back out:
            --------------------------------------------------------------------------------
            shift = mod.MIN_SHIFT
        else
            --------------------------------------------------------------------------------
            -- Too small - bail.
            -- Move to the first clip position:
            --------------------------------------------------------------------------------
            mod.contents:scrollHorizontalToX(minClip:position().x - mod.SELECTION_BUFFER)
            mod.appearance:hide()
            return
        end
    end

    --------------------------------------------------------------------------------
    -- Show the appearance popup:
    --------------------------------------------------------------------------------
    mod.appearance:show()

    --------------------------------------------------------------------------------
    -- Zoom in until it fits:
    --------------------------------------------------------------------------------
    while dir == 1 and selectedWidth < viewFrame.w or dir == -1 and selectedWidth > viewFrame.w do
        zoomAmount:value(zoomAmount:value() + shift * dir)

        selectedWidth = mod._selectedWidth(minClip, maxClip)
        viewFrame = mod.contents:viewFrame()
    end

    --------------------------------------------------------------------------------
    -- Keep zooming, with better precision:
    --------------------------------------------------------------------------------
    mod._zoomToFit(minClip, maxClip, shift/2)
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
    local selectedClips = mod.contents:selectedClipsUI()
    if not selectedClips or #selectedClips == 0 then
        return false
    end

    local minClip, maxClip

    local rangeSelection = mod.contents:rangeSelectionUI()
    if rangeSelection then
        minClip = rangeSelection
        maxClip = rangeSelection
    else
        --------------------------------------------------------------------------------
        -- Find the min/max clip and 'x' value for selected clips:
        --------------------------------------------------------------------------------
        local minX, maxX
        for _,clip in ipairs(selectedClips) do
            local frame = clip:frame()
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
    mod._zoomToFit(minClip, maxClip, mod.DEFAULT_SHIFT)

    return true
end

--- plugins.finalcutpro.timeline.zoomtoselection.init() -> none
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()
    mod.appearance = fcp:timeline():toolbar():appearance()
    mod.zoomAmount = mod.appearance:zoomAmount()
    mod.contents = fcp:timeline():contents()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.zoomtoselection",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Initialise the module:
    --------------------------------------------------------------------------------
    mod.init()

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds:add("cpZoomToSelection")
            :activatedBy():option():shift("z")
            :whenActivated(mod.zoomToSelection)
    end

    return mod

end

return plugin
