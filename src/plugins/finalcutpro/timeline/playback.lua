--- === plugins.finalcutpro.timeline.playback ===
---
--- Playback Plugin.

local require                       = require

local eventtap                      = require "hs.eventtap"

local fcp                           = require "cp.apple.finalcutpro"
local i18n                          = require "cp.i18n"
local tools                         = require "cp.tools"

local playErrorSound                = tools.playErrorSound

local checkKeyboardModifiers        = eventtap.checkKeyboardModifiers

local mod = {}

--- plugins.finalcutpro.timeline.playback.play() -> none
--- Function
--- 'Play' in Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.play()
    if not fcp.viewer:isPlaying() and not fcp.eventViewer:isPlaying() then
        fcp:doShortcut("PlayPause"):Now()
    else
        playErrorSound()
    end
end

--- plugins.finalcutpro.timeline.playback.pause() -> none
--- Function
--- 'Pause' in Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.pause()
    if fcp.viewer:isPlaying() or fcp.eventViewer:isPlaying() then
        fcp:doShortcut("PlayPause"):Now()
    else
        playErrorSound()
    end
end

local plugin = {
    id = "finalcutpro.timeline.playback",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local cmds = deps.fcpxCmds

    --------------------------------------------------------------------------------
    -- Play:
    --------------------------------------------------------------------------------
    cmds
        :add("cpPlay")
        :subtitled(i18n("thisWillOnlyTriggerThePlayShortcutKeyIfAlreadyStopped"))
        :whenActivated(mod.play)

    --------------------------------------------------------------------------------
    -- Pause:
    --------------------------------------------------------------------------------
    cmds
        :add("cpPause")
        :subtitled(i18n("thisWillOnlyTriggerThePauseShortcutKeyIfAlreadyPlaying"))
        :whenActivated(mod.pause)

    --------------------------------------------------------------------------------
    -- Jump to Next Frame:
    --------------------------------------------------------------------------------
    cmds
        :add("jumpToNextFrame")
        :whenActivated(function()
            if checkKeyboardModifiers()["shift"] then
               fcp:doShortcut("JumpForward10Frames"):Now()
            else
                fcp:doShortcut("JumpToNextFrame"):Now()
            end
        end)
        :titled(i18n("jumpToNextFrame"))
        :subtitled(i18n("jumpToFrameShiftExplanation"))

    --------------------------------------------------------------------------------
    -- Jump to Previous Frame:
    --------------------------------------------------------------------------------
    cmds
        :add("jumpToPreviousFrame")
        :whenActivated(function()
            if checkKeyboardModifiers()["shift"] then
               fcp:doShortcut("JumpBackward10Frames"):Now()
            else
                fcp:doShortcut("JumpToPreviousFrame"):Now()
            end
        end)
        :titled(i18n("jumpToPreviousFrame"))
        :subtitled(i18n("jumpToFrameShiftExplanation"))


end

return plugin
