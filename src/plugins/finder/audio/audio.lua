--- === plugins.finder.audio ===
---
--- Actions for Audio Controls

local require       = require

local audiodevice   = require "hs.audiodevice"
local i18n          = require "cp.i18n"

local plugin = {
    id              = "finder.audio",
    group           = "finder",
    dependencies    = {
        ["core.commands.global"] = "global",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Add Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global
        :add("increaseVolume")
        :whenActivated(function()
            local defaultOutputDevice = audiodevice.defaultOutputDevice()
            if defaultOutputDevice then
                local current = defaultOutputDevice:outputVolume()
                defaultOutputDevice:outputVolume(current + 1)
            end
        end)
        :titled(i18n("increase") .. " " .. i18n("volume"))

    global
        :add("decreaseVolume")
        :whenActivated(function()
            local defaultOutputDevice = audiodevice.defaultOutputDevice()
            if defaultOutputDevice then
                local current = defaultOutputDevice:outputVolume()
                defaultOutputDevice:outputVolume(current - 1)
            end
        end)
        :titled(i18n("decrease") .. " " .. i18n("volume"))
end

return plugin
