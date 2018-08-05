--- === plugins.finalcutpro.timeline.movetoplayhead ===
---
--- Move To Playhead.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("selectalltimelineclips")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp								= require("cp.apple.finalcutpro")

local Do                                = require("cp.rx.go.Do")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.movetoplayhead.moveToPlayhead() -> cp.rx.go.Statement
--- Function
--- Move to Playhead
---
--- Parameters:
---  * None
---
--- Returns:
---  * [Statement](cp.rx.go.Statement.md) to execute.
function mod.doMoveToPlayhead()
    local pasteboardManager = mod.pasteboardManager

    return Do(pasteboardManager.stopWatching)
    :Then(fcp:doShortcut("Cut"))
    :Then(fcp:doShortcut("Paste"))
    :Catch(function(message)
        log.ef("doMoveToPlayhead: %s", message)
    end)
    :Finally(function()
        Do(pasteboardManager.startWatching):After(2000)
    end)
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.movetoplayhead",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]			= "fcpxCmds",
        ["finalcutpro.pasteboard.manager"]	= "pasteboardManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Link to dependancies:
    --------------------------------------------------------------------------------
    mod.pasteboardManager = deps.pasteboardManager

    --------------------------------------------------------------------------------
    -- Setup Command:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds:add("cpMoveToPlayhead")
            :whenActivated(function() mod.moveToPlayhead() end)
    end

    return mod
end

return plugin