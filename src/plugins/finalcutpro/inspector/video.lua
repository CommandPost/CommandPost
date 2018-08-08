--- === plugins.finalcutpro.inspector.video ===
---
--- Final Cut Pro Video Inspector Additions.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log               = require("hs.logger").new("videoInspector")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")
local tools             = require("cp.tools")
local just              = require("cp.just")
local dialog            = require("cp.dialog")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local function setSpatialConform(value)

    --------------------------------------------------------------------------------
    -- Process each clip individually:
    --------------------------------------------------------------------------------
    local timeline = fcp:timeline()
    local playhead = timeline:playhead()
    local timelineContents = timeline:contents()
    local clips = timelineContents:selectedClipsUI()
    for _,clip in tools.spairs(clips, function(t,a,b) return t[a]:attributeValue("AXValueDescription") < t[b]:attributeValue("AXValueDescription") end) do

        --------------------------------------------------------------------------------
        -- Make sure Final Cut Pro is Active:
        --------------------------------------------------------------------------------
        if not just.doUntil(function()
            fcp:launch()
            return fcp:isFrontmost()
        end) then
            dialog.displayErrorMessage("Failed to switch back to Final Cut Pro.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Make sure the Timeline is selected:
        --------------------------------------------------------------------------------
        if not just.doUntil(function()
            timeline:show()
            return timeline:isShowing()
        end) then
            dialog.displayErrorMessage("Timeline could not be shown.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Select the clip:
        --------------------------------------------------------------------------------
        timelineContents:selectClip(clip)

        --------------------------------------------------------------------------------
        -- Make sure Video Inspector is active:
        --------------------------------------------------------------------------------
        local video = fcp:inspector():video()
        if not just.doUntil(function()
            video:show()
            return video:isShowing()
        end) then
            dialog.displayErrorMessage("Video Inspector could not be shown.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Make sure there's a Spatial Conform Section:
        --------------------------------------------------------------------------------
        local spatialConform = video:spatialConform()
        if not just.doUntil(function()
            spatialConform:show()
            return spatialConform:isShowing()
        end) then
            dialog.displayErrorMessage("The selected clip doesn't offer ay Spatial Conform options.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Make sure there's a Spatial Conform Type:
        --------------------------------------------------------------------------------
        local spatialConformType = spatialConform:type()
        if not just.doUntil(function()
            spatialConformType:show()
            return spatialConformType:isShowing()
        end) then
            dialog.displayErrorMessage("The selected clip doesn't offer ay Spatial Conform options.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Set the Spatial Conform Type:
        --------------------------------------------------------------------------------
        spatialConformType:value(value)
    end

    --------------------------------------------------------------------------------
    -- Reselect original clips:
    --------------------------------------------------------------------------------
    timelineContents:selectClips(clips)

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.inspector.video",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds
            :add("cpSetSpatialConformTypeToFit")
            :whenActivated(function() setSpatialConform("Fit") end)

        deps.fcpxCmds
            :add("cpSetSpatialConformTypeToFill")
            :whenActivated(function() setSpatialConform("Fill") end)

        deps.fcpxCmds
            :add("cpSetSpatialConformTypeToNone")
            :whenActivated(function() setSpatialConform("None") end)
    end

    return mod
end

return plugin