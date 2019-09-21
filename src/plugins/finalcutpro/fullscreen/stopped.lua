--- === plugins.finalcutpro.fullscreen.stopped ===
---
--- Play Full Screen & Stop

local require           = require

local eventtap          = require "hs.eventtap"

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
    deps.fcpxCmds
        :add("playFullScreenAndStop")
        :whenActivated(function()
            if not fcp:fullScreenWindow():isShowing() then
                fcp:selectMenu({"View", "Playback", "Play Full Screen"})
                if doUntil(function()
                    return fcp:fullScreenWindow():isShowing()
                end, 5, 0.1) then
                    eventtap.keyStroke({}, "space")
                    return
                end
            end
            playErrorSound()
        end)
end

return plugin