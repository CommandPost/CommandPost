--- === plugins.finalcutpro.timeline.pasteboard ===
---
--- Actions related to the pasteboard.

local require = require

--local log				= require "hs.logger".new "pasteboard"

local fcp				= require "cp.apple.finalcutpro"
local tools             = require "cp.tools"

local pasteboard        = require "hs.pasteboard"
local eventtap          = require "hs.eventtap"

local plugin = {
    id = "finalcutpro.timeline.pasteboard",
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
    -- Add Commands:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    fcpxCmds
        :add("cpCopySelectedClipDurationToPasteboard")
        :whenActivated(function()
            local selectedClip
            local content = fcp.timeline.contents
            local selectedClips = content:selectedClipsUI()
            if selectedClips and #selectedClips == 1 then
                selectedClip = selectedClips[1]
            end
            if selectedClip then
                fcp:doSelectMenu({"Modify", "Change Duration…"}):Then(function()
                    local duration = fcp.viewer.timecode()
                    if duration then
                        pasteboard.setContents(duration)
                    end
                    eventtap.keyStroke({}, "return")
                end):Catch(function()
                    tools.playErrorSound()
                end):Now()
            else
                tools.playErrorSound()
            end
        end)

end

return plugin
