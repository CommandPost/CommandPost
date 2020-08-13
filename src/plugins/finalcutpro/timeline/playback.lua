--- === plugins.finalcutpro.timeline.playback ===
---
--- Playback Plugin.

local require           = require

local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local playErrorSound    = tools.playErrorSound

local plugin = {
    id = "finalcutpro.timeline.playback",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps)
    local cmds = deps.fcpxCmds
    cmds
        :add("cpPlay")
        :subtitled(i18n("thisWillOnlyTriggerThePlayShortcutKeyIfAlreadyStopped"))
        :whenActivated(function()
            if not fcp:viewer():isPlaying() and not fcp:eventViewer():isPlaying() then
                fcp:doShortcut("PlayPause"):Now()
            else
                playErrorSound()
            end
        end)

    cmds
        :add("cpPause")
        :subtitled(i18n("thisWillOnlyTriggerThePauseShortcutKeyIfAlreadyPlaying"))
        :whenActivated(function()
            if fcp:viewer():isPlaying() or fcp:eventViewer():isPlaying() then
                fcp:doShortcut("PlayPause"):Now()
            else
                playErrorSound()
            end
        end)
end

return plugin
