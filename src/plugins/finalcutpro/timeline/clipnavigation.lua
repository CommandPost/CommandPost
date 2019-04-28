--- === plugins.finalcutpro.timeline.clipnavigation ===
---
--- Clip Navigation Actions.

local require = require

local log               = require "hs.logger".new "clipnavigation"

local dialog            = require "cp.dialog"
local fcp               = require "cp.apple.finalcutpro"
local flicks            = require "cp.time.flicks"
local i18n              = require "cp.i18n"

local displayMessage    = dialog.displayMessage

local plugin = {
    id = "finalcutpro.timeline.clipnavigation",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    local fcpxCmds = deps.fcpxCmds

    --------------------------------------------------------------------------------
    -- Select Middle of Next Clip In Same Storyline:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("selectMiddleOfNextClipInSameLane")
        :whenActivated(function()
            local timeline = fcp:timeline()
            local contents = timeline:contents()
            local selectedClips = contents:selectedClipsUI()
            if selectedClips and #selectedClips == 1 then
                local selectedClip = selectedClips[1]
                local clips = contents:clipsUI(true, function(clip)
                    local frame = clip:frame()
                    local selectedClipFrame = selectedClip:frame()
                    if frame.y == selectedClipFrame.y and frame.x >= (selectedClipFrame.x + selectedClipFrame.w) then
                        return true
                    end
                end)

                local nextClip
                for _, clip in pairs(clips) do
                    if not nextClip then
                        nextClip = clip
                    else
                        if clip:frame().x < nextClip:frame().x then
                            nextClip = clip
                        end
                    end
                end

                if nextClip then
                    contents:selectClip(nextClip)
                    --------------------------------------------------------------------------------
                    -- Annoyingly, we can't work out the timecode of clips in a secondary storyline.
                    --------------------------------------------------------------------------------
                    if nextClip:attributeValue("AXParent"):attributeValue("AXRole") == "AXLayoutArea" then
                        local frameRate = fcp:viewer():framerate() or 25

                        local startTC = nextClip:attributeValue("AXChildren")[1]:attributeValue("AXValue")
                        local endTC = nextClip:attributeValue("AXChildren")[2]:attributeValue("AXValue")

                        local startTCinFlicks = flicks.parse(startTC, frameRate)
                        local endTCinFlicks = flicks.parse(endTC, frameRate)

                        local duration = endTCinFlicks - startTCinFlicks

                        local newPosition = startTCinFlicks + duration / 2

                        local newPositionInTC = newPosition:toTimecode(frameRate, ":")

                        timeline:playhead():timecode(newPositionInTC)
                    end
                end
            else
                displayMessage(i18n("mustHaveSingleClipSelectedInTimeline"))
            end
        end)
        :titled(i18n("selectMiddleOfNextClipInSameStoryline"))

    --------------------------------------------------------------------------------
    -- Select Middle of Previous Clip In Same Storyline:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("selectMiddleOfPreviousClipInSameLane")
        :whenActivated(function()
            local timeline = fcp:timeline()
            local contents = timeline:contents()
            local selectedClips = contents:selectedClipsUI()
            if selectedClips and #selectedClips == 1 then
                local selectedClip = selectedClips[1]
                local clips = contents:clipsUI(true, function(clip)
                    local frame = clip:frame()
                    local selectedClipFrame = selectedClip:frame()
                    if frame.y == selectedClipFrame.y and frame.x < selectedClipFrame.x then
                        return true
                    end
                end)

                local previousClip
                for _, clip in pairs(clips) do
                    if not previousClip then
                        previousClip = clip
                    else
                        if clip:frame().x > previousClip:frame().x then
                            previousClip = clip
                        end
                    end
                end

                if previousClip then
                    contents:selectClip(previousClip)
                    --------------------------------------------------------------------------------
                    -- Annoyingly, we can't work out the timecode of clips in a secondary storyline.
                    --------------------------------------------------------------------------------
                    if previousClip:attributeValue("AXParent"):attributeValue("AXRole") == "AXLayoutArea" then
                        local frameRate = fcp:viewer():framerate() or 25

                        local startTC = previousClip:attributeValue("AXChildren")[1]:attributeValue("AXValue")
                        local endTC = previousClip:attributeValue("AXChildren")[2]:attributeValue("AXValue")

                        local startTCinFlicks = flicks.parse(startTC, frameRate)
                        local endTCinFlicks = flicks.parse(endTC, frameRate)

                        local duration = endTCinFlicks - startTCinFlicks

                        local newPosition = startTCinFlicks + duration / 2

                        local newPositionInTC = newPosition:toTimecode(frameRate, ":")

                        timeline:playhead():timecode(newPositionInTC)
                    end
                end
            else
                displayMessage(i18n("mustHaveSingleClipSelectedInTimeline"))
            end
        end)
        :titled(i18n("selectMiddleOfPreviousClipInSameStoryline"))

    return mod
end

return plugin
