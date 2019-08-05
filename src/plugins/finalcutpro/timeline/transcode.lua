--- === plugins.finalcutpro.timeline.transcode ===
---
--- Adds actions that allows you to transcode clips from the timeline.

local require   = require

local log       = require "hs.logger".new "transcode"
local fcp       = require "cp.apple.finalcutpro"
local tools     = require "cp.tools"
local just      = require "cp.just"

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
        :titled("Create Optimized Media of Selected Clips in Timeline")
        :whenActivated(function()
            local contents = fcp:timeline():contents()
            local selectedClipsUI = contents:selectedClipsUI()
            if not selectedClipsUI then
                tools.playErrorSound()
                return
            end
            for _, clip in pairs(selectedClipsUI) do
                contents:selectClip(clip)
                fcp:selectMenu({"File", "Reveal in Browser"})
                fcp:selectMenu({"Window", "Go To", "Libraries"})

                if not just.doUntil(function()
                    return fcp:menu():isEnabled({"File", "Transcode Media…"})
                end) then
                    tools.playErrorSound()
                    return
                end

                fcp:selectMenu({"File", "Transcode Media…"})
                log.df("DONE!")
                return
            end

        end)
end

return plugin
