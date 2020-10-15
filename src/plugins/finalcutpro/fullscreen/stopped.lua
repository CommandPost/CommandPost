--- === plugins.finalcutpro.fullscreen.stopped ===
---
--- Play Full Screen & Stop

local require           = require

local fcp               = require "cp.apple.finalcutpro"
local just              = require "cp.just"
local tools             = require "cp.tools"

local doUntil           = just.doUntil
local playErrorSound    = tools.playErrorSound

local plugin = {
    id              = "finalcutpro.fullscreen.stopped",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    deps.fcpxCmds
        :add("playFullScreenAndStop")
        :whenActivated(function()
            if not fcp.fullScreenWindow:isShowing() then
                fcp:selectMenu({"View", "Playback", "Play Full Screen"})
                if doUntil(function()
                    return fcp.fullScreenWindow:isShowing()
                end, 5, 0.1) then
                    fcp:keyStroke({}, "space")
                    return
                end
            end
            playErrorSound()
        end)
end

return plugin