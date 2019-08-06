--- === plugins.finalcutpro.timeline.transcode ===
---
--- Adds actions that allows you to transcode clips from the timeline.

local require           = require

--local log               = require "hs.logger".new "transcode"

local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local just              = require "cp.just"
local tools             = require "cp.tools"

local doUntil           = just.doUntil
local playErrorSound    = tools.playErrorSound

local mod = {}

mod.transcodeType = {
    optimized = "optimized",
    proxy = "proxy"
}

function mod.transcodeSelectedClips(type)
    local contents = fcp:timeline():contents()
    local transcodeMedia = fcp:transcodeMedia()

    if not fcp:launch() then
        playErrorSound()
        return
    end

    if not doUntil(function()
        fcp:selectMenu({"Window", "Go To", "Timeline"})
        return contents:isFocused()
    end) then
        playErrorSound()
        return
    end

    local selectedClipsUI = contents:selectedClipsUI()
    if not selectedClipsUI then
        playErrorSound()
        return
    end
    for _, clip in pairs(selectedClipsUI) do
        if not doUntil(function()
            contents:selectClip(clip)
            local selectedClips = contents:selectedClipsUI()
            return selectedClips and #selectedClips == 1 and selectedClips[1] == clip
        end) then
            playErrorSound()
            return
        end

        fcp:selectMenu({"File", "Reveal in Browser"})
        fcp:selectMenu({"Window", "Go To", "Libraries"})

        if not doUntil(function()
            return fcp:menu():isEnabled({"File", "Transcode Media…"})
        end) then
            playErrorSound()
            return
        end
        fcp:selectMenu({"File", "Transcode Media…"})
        if not doUntil(function()
            return transcodeMedia:isShowing()
        end) then
            playErrorSound()
            return
        end

        if type == mod.transcodeType.proxy then
            if not transcodeMedia:createProxyMedia():isEnabled() then
                transcodeMedia:cancel():press()
                playErrorSound()
                return
            end
        end

        if type == mod.transcodeType.optimized then
            if not transcodeMedia:createOptimizedMedia():isEnabled() then
                transcodeMedia:cancel():press()
                playErrorSound()
                return
            end
        end

        transcodeMedia:createOptimizedMedia():checked(true)
        transcodeMedia:ok():press()

        if not doUntil(function()
            return not transcodeMedia:isShowing()
        end) then
            playErrorSound()
            return
        end
    end
end

function mod.optimizeSelectedClips()
    mod.transcodeSelectedClips(mod.transcodeType.optimized)
end

function mod.proxySelectedClips()
    mod.transcodeSelectedClips(mod.transcodeType.proxy)
end

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
        :whenActivated(mod.optimizeSelectedClips)

    deps.fcpxCmds
        :add("createProxyMediaFromTimeline")
        :titled(i18n("createProxyMediaOfSelectedClipsInTimeline"))
        :whenActivated(mod.proxySelectedClips)

    return mod
end

return plugin
