--- === plugins.finalcutpro.timeline.transcode ===
---
--- Adds actions that allows you to transcode clips from the timeline.

local require           = require

--local log               = require "hs.logger".new "transcode"

local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local just              = require "cp.just"
local tools             = require "cp.tools"

local playErrorSound    = tools.playErrorSound

local plugin = {
    id = "finalcutpro.timeline.transcode",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    deps.fcpxCmds
        :add("createOptimizedMediaFromTimeline")
        :titled(i18n("createOptimizedMediaOfSelectedClipsInTimeline"))
        :whenActivated(function()
            local contents = fcp:timeline():contents()
            local selectedClipsUI = contents:selectedClipsUI()
            if not selectedClipsUI then
                playErrorSound()
                return
            end
            for _, clip in pairs(selectedClipsUI) do
                contents:selectClip(clip)
                fcp:selectMenu({"File", "Reveal in Browser"})
                fcp:selectMenu({"Window", "Go To", "Libraries"})

                if not just.doUntil(function()
                    return fcp:menu():isEnabled({"File", "Transcode Media…"})
                end) then
                    playErrorSound()
                    return
                end
                fcp:selectMenu({"File", "Transcode Media…"})
                if not just.doUntil(function()
                    return fcp:transcodeMedia():isShowing()
                end) then
                    playErrorSound()
                    return
                end

                if not fcp:transcodeMedia():createOptimizedMedia():isEnabled() then
                    fcp:transcodeMedia():cancel():press()
                    playErrorSound()
                    return
                end

                fcp:transcodeMedia():createOptimizedMedia():checked(true)
                fcp:transcodeMedia():ok():press()

                if not just.doUntil(function()
                    return not fcp:transcodeMedia():isShowing()
                end) then
                    playErrorSound()
                    return
                end
            end
        end)

    deps.fcpxCmds
        :add("createProxyMediaFromTimeline")
        :titled(i18n("createProxyMediaOfSelectedClipsInTimeline"))
        :whenActivated(function()
            local contents = fcp:timeline():contents()
            local selectedClipsUI = contents:selectedClipsUI()
            if not selectedClipsUI then
                playErrorSound()
                return
            end
            for _, clip in pairs(selectedClipsUI) do
                contents:selectClip(clip)
                fcp:selectMenu({"File", "Reveal in Browser"})
                fcp:selectMenu({"Window", "Go To", "Libraries"})

                if not just.doUntil(function()
                    return fcp:menu():isEnabled({"File", "Transcode Media…"})
                end) then
                    playErrorSound()
                    return
                end
                fcp:selectMenu({"File", "Transcode Media…"})
                if not just.doUntil(function()
                    return fcp:transcodeMedia():isShowing()
                end) then
                    playErrorSound()
                    return
                end

                if not fcp:transcodeMedia():createProxyMedia():isEnabled() then
                    fcp:transcodeMedia():cancel():press()
                    playErrorSound()
                    return
                end

                fcp:transcodeMedia():createProxyMedia():checked(true)
                fcp:transcodeMedia():ok():press()

                if not just.doUntil(function()
                    return not fcp:transcodeMedia():isShowing()
                end) then
                    playErrorSound()
                    return
                end
            end
        end)
end

return plugin
