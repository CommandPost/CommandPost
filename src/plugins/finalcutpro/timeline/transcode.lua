--- === plugins.finalcutpro.timeline.transcode ===
---
--- Adds actions that allows you to transcode clips from the timeline.

local require           = require

--local log               = require "hs.logger".new "transcode"

local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local just              = require "cp.just"
local tools             = require "cp.tools"
local go                = require "cp.rx.go"

local doUntil           = just.doUntil
local playErrorSound    = tools.playErrorSound
local Do, If, Throw     = go.Do, go.If, go.Throw
local Retry, WaitUntil  = go.Retry, go.WaitUntil
local Given             = go.Given

local mod = {}

-- throwMessage(message, ...) -> cp.rx.go.Statement
-- Function
-- Returns a [Statement](cp.rx.go.Statement.md) that will make an error sound then throw the provided message.
local function throwMessage(message, ...)
    return Do(playErrorSound):Then(Throw(message, ...))
end

mod.transcodeType = {
    optimized = "optimized",
    proxy = "proxy"
}

function mod.transcodeSelectedClips(transcodeType)

    if not fcp:launch() then
        playErrorSound()
        return
    end

    local timeline = fcp:timeline()
    local contents = timeline:contents()
    local transcodeMedia = fcp:transcodeMedia()

    if not timeline:isFocused() then
        -----------------------------------------------------------------------
        -- If the timeline is not focussed, let's assume the browser is:
        -----------------------------------------------------------------------
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

        if transcodeType == mod.transcodeType.proxy then
            if not transcodeMedia:createProxyMedia():isEnabled() then
                transcodeMedia:cancel():press()
                playErrorSound()
                return
            end
            transcodeMedia:createProxyMedia():checked(true)
        end

        if transcodeType == mod.transcodeType.optimized then
            if not transcodeMedia:createOptimizedMedia():isEnabled() then
                transcodeMedia:cancel():press()
                playErrorSound()
                return
            end
            transcodeMedia:createOptimizedMedia():checked(true)
        end

        transcodeMedia:ok():press()

        if not doUntil(function()
            return not transcodeMedia:isShowing()
        end) then
            playErrorSound()
            return
        end
        return
    end

    local selectedClipsUI = contents:selectedClipsUI()
    if not selectedClipsUI then
        playErrorSound()
        return
    end

    for _, clip in pairs(selectedClipsUI) do

        if not doUntil(function()
            fcp:selectMenu({"Window", "Go To", "Timeline"})
            return contents:isFocused()
        end) then
            playErrorSound()
            return
        end

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

        if transcodeType == mod.transcodeType.proxy then
            if not transcodeMedia:createProxyMedia():isEnabled() then
                transcodeMedia:cancel():press()
                playErrorSound()
                return
            end
            transcodeMedia:createProxyMedia():checked(true)
        end

        if transcodeType == mod.transcodeType.optimized then
            if not transcodeMedia:createOptimizedMedia():isEnabled() then
                transcodeMedia:cancel():press()
                playErrorSound()
                return
            end
            transcodeMedia:createOptimizedMedia():checked(true)
        end

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

function mod.doTranscodeSelectedBrowserClips(transcodeType)
    local transcodeMedia = fcp:transcodeMedia()

    local isOptimized = transcodeType == mod.transcodeType.optimized
    local isProxy = transcodeType == mod.transcodeType.proxy

    return Do(fcp:selectMenu({"Window", "Go To", "Libraries"}))
    :Then(Retry(fcp:doSelectMenu({"File", "Transcode Media…"})):UpTo(5))
    :Then(WaitUntil(transcodeMedia.isShowing):TimeoutAfter(3000))
    :Then(If(isOptimized):Then(transcodeMedia:createOptimizedMedia():doCheck()))
    :Then(If(isProxy):Then(transcodeMedia:createProxyMedia():doCheck()))
    :Then(transcodeMedia:doDefault())
    :Then(WaitUntil(transcodeMedia.isShowing):Is(false):TimeoutAfter(3000))
end

function mod.doTranscodeSelectedTimelineClips(transcodeType)
    local timeline = fcp:timeline()
    local contents = timeline:contents()

    return Do(timeline:doFocus())
    :Then(function()
        local selectedClipsUI = contents:selectedClipsUI()

        if not selectedClipsUI then
            return throwMessage("No clips selected in the Timeline.")
        end

        Given(selectedClipsUI)
        :Then(function(clip)
            return Do(contents:doSelectClip(clip))
            :Then(fcp:doSelectMenu({"File", "Reveal in Browser"}))
            -- TODO: See if this is still necessary to get around "Reveal" not working reliably the first time.
            :Then(timeline:doFocus())
            :Then(fcp:doSelectMenu({"File", "Reveal in Browser"}))
            :Then(mod.doTranscodeSelectedBrowserClips(transcodeType))
        end)
    end)
    :Label("doTranscodeSelectedTimelineClips")
end

function mod.doTranscodeSelectedClips(transcodeType)
    -- local timeline = fcp:timeline()

    -- TODO: I18N the error messages.

    return Do(
        If(fcp:doLaunch()):Is(false):Then(throwMessage("Unable to launch Final Cut Pro"))
    ):Then(
        -- TODO: Once we get LibraryBrowser:isFocused() and/or Timeline:isFocused() working again...
        -- If(timeline.isFocused):Then(
            mod.doTranscodeSelectedTimelineClips(transcodeType)
        -- ):Otherwise(
            -- mod.doTranscodeSelectedBrowserClips(transcodeType)
        -- )
    )
    :Label("doTranscodeSelectedClips")
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
        :titled(i18n("optimizeSelectedMedia"))
        --:whenActivated(mod.doTranscodeSelectedClips(mod.transcodeType.optimized))
        :whenActivated(mod.optimizeSelectedClips)

    deps.fcpxCmds
        :add("createProxyMediaFromTimeline")
        :titled(i18n("proxySelectedMedia"))
        --:whenActivated(mod.doTranscodeSelectedClips(mod.transcodeType.proxy))
        :whenActivated(mod.proxySelectedClips)

    return mod
end

return plugin
