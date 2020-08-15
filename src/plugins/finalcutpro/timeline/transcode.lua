--- === plugins.finalcutpro.timeline.transcode ===
---
--- Adds actions that allows you to transcode clips from the timeline.

local require           = require

--local log               = require "hs.logger".new "transcode"

local fcp               = require "cp.apple.finalcutpro"
local go                = require "cp.rx.go"
local i18n              = require "cp.i18n"
local just              = require "cp.just"
local tools             = require "cp.tools"

local doUntil           = just.doUntil
local playErrorSound    = tools.playErrorSound

local Do                = go.Do
local Given             = go.Given
local If                = go.If
local Retry             = go.Retry
local Throw             = go.Throw
local WaitUntil         = go.WaitUntil

local mod = {}

-- throwMessage(message, ...) -> cp.rx.go.Statement
-- Function
-- Returns a [Statement](cp.rx.go.Statement.md) that will make an error sound then throw the provided message.
local function throwMessage(message, ...)
    return Do(playErrorSound):Then(Throw(message, ...))
end

--- plugins.finalcutpro.timeline.transcode.transcodeType -> table
--- Constant
--- Transcode type.
mod.transcodeType = {
    optimized = "optimized",
    proxy = "proxy"
}

--- plugins.finalcutpro.timeline.transcode.transcodeSelectedClips(transcodeType) -> none
--- Function
--- Transcode selected clips.
---
--- Parameters:
---  * transcodeType - Either "optimized" or "proxy"
---
--- Returns:
---  * None
function mod.transcodeSelectedClips(transcodeType)
    if not fcp:launch() then
        playErrorSound()
        return
    end

    local timeline = fcp.timeline
    local contents = timeline:contents()
    local transcodeMedia = fcp.transcodeMedia

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

--- plugins.finalcutpro.timeline.transcode.optimizeSelectedClips() -> none
--- Function
--- Create optimised media for selected clips.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.optimizeSelectedClips()
    mod.transcodeSelectedClips(mod.transcodeType.optimized)
end

--- plugins.finalcutpro.timeline.transcode.proxySelectedClips() -> none
--- Function
--- Create Proxies for selected clips.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.proxySelectedClips()
    mod.transcodeSelectedClips(mod.transcodeType.proxy)
end

--- plugins.finalcutpro.timeline.transcode.doTranscodeSelectedBrowserClips() -> Statement
--- Function
--- Creates a [Statement](cp.rx.go.Statement.md) to transcode selected browser clips.
---
--- Parameters:
---  * transcodeType - Either "optimized" or "proxy"
---
--- Returns:
---  * [Statement](cp.rx.go.Statement.md) to execute
function mod.doTranscodeSelectedBrowserClips(transcodeType)
    local transcodeMedia = fcp.transcodeMedia

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

--- plugins.finalcutpro.timeline.transcode.doTranscodeSelectedTimelineClips() -> Statement
--- Function
--- Creates a [Statement](cp.rx.go.Statement.md) to transcode selected timeline clips.
---
--- Parameters:
---  * transcodeType - Either "optimized" or "proxy"
---
--- Returns:
---  * [Statement](cp.rx.go.Statement.md) to execute
function mod.doTranscodeSelectedTimelineClips(transcodeType)
    local timeline = fcp.timeline
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
            :Then(mod.doTranscodeSelectedBrowserClips(transcodeType))
        end)
    end)
    :Label("doTranscodeSelectedTimelineClips")
end

--- plugins.finalcutpro.timeline.transcode.doTranscodeSelectedClips() -> Statement
--- Function
--- Creates a [Statement](cp.rx.go.Statement.md) to transcode selected clips.
---
--- Parameters:
---  * transcodeType - Either "optimized" or "proxy"
---
--- Returns:
---  * [Statement](cp.rx.go.Statement.md) to execute
function mod.doTranscodeSelectedClips(transcodeType)
    local timeline = fcp.timeline
    return Do(
        If(fcp:doLaunch()):Is(false):Then(throwMessage("Unable to launch Final Cut Pro"))
    ):Then(
        If(timeline.isFocused):Then(
            mod.doTranscodeSelectedTimelineClips(transcodeType)
        ):Otherwise(
            mod.doTranscodeSelectedBrowserClips(transcodeType)
        )
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
        :whenActivated(mod.optimizeSelectedClips)
        --:whenActivated(mod.doTranscodeSelectedClips(mod.transcodeType.optimized))

    deps.fcpxCmds
        :add("createProxyMediaFromTimeline")
        :titled(i18n("proxySelectedMedia"))
        :whenActivated(mod.proxySelectedClips)
        --:whenActivated(mod.doTranscodeSelectedClips(mod.transcodeType.proxy))

    return mod
end

return plugin
