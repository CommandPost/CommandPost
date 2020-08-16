--- === plugins.finalcutpro.inspector.audio ===
---
--- Final Cut Pro Audio Inspector Additions.

local require = require

local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"

local plugin = {
    id              = "finalcutpro.inspector.audio",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "cmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Audio Enhancements:
    --------------------------------------------------------------------------------
    local cmds = deps.cmds
    local audio = fcp.inspector.audio
    local audioEnhancements = audio:audioEnhancements()
    local audioConfiguration = audio:audioConfiguration()
    cmds
        :add("toggleEqualization")
        :whenActivated(audioEnhancements:equalization().enabled:doPress())
        :titled(i18n("toggle") .. " " .. i18n("equalization"))

    cmds
        :add("toggleLoudness")
        :whenActivated(audioEnhancements:audioAnalysis():loudness().enabled:doPress())
        :titled(i18n("toggle") .. " " .. i18n("loudness"))

    cmds
        :add("toggleNoiseRemoval")
        :whenActivated(audioEnhancements:audioAnalysis():noiseRemoval().enabled:doPress())
        :titled(i18n("toggle") .. " " .. i18n("noiseRemoval"))

    cmds
        :add("toggleHumRemoval")
        :whenActivated(audioEnhancements:audioAnalysis():humRemoval().enabled:doPress())
        :titled(i18n("toggle") .. " " .. i18n("humRemoval"))

    --------------------------------------------------------------------------------
    -- Audio Configuration:
    --------------------------------------------------------------------------------
    for i=1, 9 do
        cmds
            :add("toggleAudioComponent" .. i)
            :whenActivated(audioConfiguration:component(i):enabled():doPress())
            :titled(i18n("toggle") .. " " .. i18n("audio") .. " " .. i18n("component") .. " " .. i)

        cmds
            :add("toggleAudioSubcomponent" .. i)
            :whenActivated(audioConfiguration:subcomponent(i):enabled():doPress())
            :titled(i18n("toggle") .. " " .. i18n("audio") .. " " .. i18n("subcomponent") .. " " .. i)
    end

    --------------------------------------------------------------------------------
    -- Volume:
    --------------------------------------------------------------------------------
    for i=-12, 12 do
        cmds
            :add("setVolumeTo" .. " " .. i)
            :whenActivated(function()
                local volume = audio:volume()
                volume:show()
                volume:value(tostring(i))
            end)
            :titled(i18n("setVolumeTo") .. " " .. tostring(i))
    end

end

return plugin