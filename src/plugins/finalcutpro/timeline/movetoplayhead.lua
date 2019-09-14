--- === plugins.finalcutpro.timeline.movetoplayhead ===
---
--- Move To Playhead.

local require = require

local log               = require("hs.logger").new("selectalltimelineclips")

local Do                = require("cp.rx.go.Do")
local fcp               = require("cp.apple.finalcutpro")

local plugin = {
    id = "finalcutpro.timeline.movetoplayhead",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]            = "fcpxCmds",
        ["finalcutpro.pasteboard.manager"]  = "pasteboardManager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Link to dependancies:
    --------------------------------------------------------------------------------
    local pasteboardManager = deps.pasteboardManager

    --------------------------------------------------------------------------------
    -- Setup Command:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpMoveToPlayhead")
        :whenActivated(function()
            Do(pasteboardManager.stopWatching)
                :Then(fcp:doShortcut("Cut"))
                :Then(fcp:doShortcut("Paste"))
                :Catch(function(message)
                    log.ef("doMoveToPlayhead: %s", message)
                end)
                :Finally(function()
                    Do(pasteboardManager.startWatching):After(2000)
                end)
                :Label("Move To Playhead")
                :Now()
        end)

    return mod
end

return plugin
