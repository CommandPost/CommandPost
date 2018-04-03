--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.playback ===
---
--- Playback Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp							= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
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
    fcp:performShortcut("PlayPause")
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
    mod.play()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.playback",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]	= "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        local cmds = deps.fcpxCmds
        cmds:add("cpPlay")
            :whenActivated(mod.play)

        cmds:add("cpPause")
            :whenActivated(mod.pause)
    end

    return mod
end

return plugin