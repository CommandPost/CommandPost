--- === plugins.finalcutpro.timeline.lanes ===
---
--- Controls Final Cut Pro's Lanes.

local require   = require

local log       = require("hs.logger").new("lanes")

local fcp       = require("cp.apple.finalcutpro")
local tools     = require("cp.tools")
local i18n      = require("cp.i18n")

local mod = {}

-- MAX_LANES -> number
-- Constant
-- The maximum number of lanes.
local MAX_LANES = 10

--- plugins.finalcutpro.timeline.lanes.selectClipAtLane(whichLane) -> boolean
--- Function
--- Select Clip at Lane in Final Cut Pro
---
--- Parameters:
---  * whichLane - Lane Number
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.selectClipAtLane(whichLane)
    local content = fcp.timeline.contents
    local playheadX = content.playhead:position()

    local clips = content:clipsUI(false, function(clip)
        local frame = clip:frame()
        return playheadX >= frame.x and playheadX < (frame.x + frame.w)
    end)

    if clips == nil then
        log.d("No clips detected in selectClipAtLane().")
        return false
    end

    if whichLane > #clips then
        return false
    end

    --------------------------------------------------------------------------------
    -- Sort the table:
    --------------------------------------------------------------------------------
    table.sort(clips, function(a, b) return a:position().y > b:position().y end)

    content:selectClip(clips[whichLane])

    return true
end

local plugin = {
    id = "finalcutpro.timeline.lanes",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    for i = 1, MAX_LANES do
        fcpxCmds
            :add("cpSelectClipAtLane" .. tools.numberToWord(i))
            :groupedBy("timeline")
            :titled(i18n("cpSelectClipAtLane_customTitle", {count = i}))
            :whenActivated(function() mod.selectClipAtLane(i) end)
    end

    return mod
end

return plugin
