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
local tools             = require("cp.tools")
local just              = require("cp.just")
local dialog            = require("cp.dialog")

local go                = require("cp.rx.go")
local Do, Given, List   = go.Do, go.Given, go.List
local WaitUntil         = go.WaitUntil

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local function setSpatialConform(value)

    --------------------------------------------------------------------------------
    -- TODO: This could probably be Rx-ified?
    --------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- Make sure at least one clip is selected:
    --------------------------------------------------------------------------------
    local timeline = fcp:timeline()
    local timelineContents = timeline:contents()
    local clips = timelineContents:selectedClipsUI()
    if clips and #clips == 0 then
        log.df("No clips selected.")
        tools.playErrorSound()
        return
    end

    --------------------------------------------------------------------------------
    -- Process each clip individually:
    --------------------------------------------------------------------------------
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

        if #clips ~= 1 then
            --------------------------------------------------------------------------------
            -- Select the clip:
            --------------------------------------------------------------------------------
            timelineContents:selectClip(clip)

            --------------------------------------------------------------------------------
            -- TODO: I'm not exactly sure why, but this only works if I add a wait here?
            --------------------------------------------------------------------------------
            just.wait(0.3)
        end

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
            dialog.displayErrorMessage("The selected clip doesn't offer any Spatial Conform options.")
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
            dialog.displayErrorMessage("The selected clip doesn't offer any Spatial Conform options.")
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

local function timecodeComparison(a, b)
    return a:attributeValue("AXValueDescription") < b:attributeValue("AXValueDescription")
end

local function doSetSpatialConform(value)
    local timeline = fcp:timeline()
    local timelineContents = timeline:contents()
    local spatialConform = fcp:inspector():video():spatialConform()
    local spatialConformType = spatialConform:type()

    return Do(function()
        --------------------------------------------------------------------------------
        -- Make sure at least one clip is selected:
        --------------------------------------------------------------------------------
        local clips = timelineContents:selectedClipsUI()
        if clips and #clips == 0 then
            log.df("No clips selected.")
            tools.playErrorSound()
            return false
        end

        return Do(
            --------------------------------------------------------------------------------
            -- Process each clip individually:
            --------------------------------------------------------------------------------
            Given(List(clips):SortedBy(timecodeComparison))
            :Then(function(clip)
                return Do(fcp:doLaunch())
                :Then(timeline:doShow())
                :Then(timelineContents:doSelectClip(clip):ThenDelay(100))
                :Then(spatialConformType:doShow())
                :Then(function()
                    spatialConformType:value(value)
                end)
                :ThenYield()
            end)
            :Then(WaitUntil(spatialConformType.value.value):Is(value):TimeoutAfter(2000):Debug("Spatial Conform Wait"))
        )
        --------------------------------------------------------------------------------
        -- Reselect original clips:
        --------------------------------------------------------------------------------
        :Then(timelineContents:doSelectClips(clips))
        :Then(true)
    end)
    :Catch(function(message)
        dialog.displayErrorMessage(message)
        return false
    end)
    :Label("video.doSetSpatialConform")

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
            :whenActivated(doSetSpatialConform("Fit"))

        deps.fcpxCmds
            :add("cpSetSpatialConformTypeToFill")
            :whenActivated(doSetSpatialConform("Fill"))

        deps.fcpxCmds
            :add("cpSetSpatialConformTypeToNone")
            :whenActivated(doSetSpatialConform("None"))
    end

end

return plugin