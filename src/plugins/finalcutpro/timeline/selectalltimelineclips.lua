--- === plugins.finalcutpro.timeline.selectalltimelineclips ===
---
--- Select All Timeline Clips

local require = require

local log                               = require("hs.logger").new("selectalltimelineclips")

local fcp                               = require("cp.apple.finalcutpro")

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

    local content = fcp.timeline.contents
    local playheadX = content.playhead:position()

    local clips = content:clipsUI(true, function(clip)
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


local plugin = {
    id = "finalcutpro.timeline.selectalltimelineclips",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Add Commands:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    fcpxCmds
        :add("cpSelectForward")
        :activatedBy():ctrl():option():cmd("right")
        :whenActivated(function() mod.selectAllTimelineClips(true) end)

    fcpxCmds
        :add("cpSelectBackwards")
        :activatedBy():ctrl():option():cmd("left")
        :whenActivated(function() mod.selectAllTimelineClips(false) end)

    return mod
end

return plugin
