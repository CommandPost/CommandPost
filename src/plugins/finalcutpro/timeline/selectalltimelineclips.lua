--- === plugins.finalcutpro.timeline.selectalltimelineclips ===
---
--- Select All Timeline Clips

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                               = require("hs.logger").new("selectalltimelineclips")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                               = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.selectalltimelineclips(forwards) -> boolean
--- Function
--- Selects all timeline clips to the left or right of the timeline playhead in Final Cut Pro.
---
--- Parameters:
---  * forwards - `true` if you want to select forwards
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.selectAllTimelineClips(forwards)

    local content = fcp:timeline():contents()
    local playheadX = content:playhead():getPosition()

    local clips = content:clipsUI(false, function(clip)
        local frame = clip:frame()
        if forwards then
            return playheadX <= frame.x
        else
            return playheadX >= frame.x
        end
    end)

    if clips then
        content:selectClips(clips)
        return true
    else
        log.df("No clips to select")
        return false
    end

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.selectalltimelineclips",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Add Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds:add("cpSelectForward")
            :activatedBy():ctrl():option():cmd("right")
            :whenActivated(function() mod.selectAllTimelineClips(true) end)

        deps.fcpxCmds:add("cpSelectBackwards")
            :activatedBy():ctrl():option():cmd("left")
            :whenActivated(function() mod.selectAllTimelineClips(false) end)
    end

    return mod

end

return plugin