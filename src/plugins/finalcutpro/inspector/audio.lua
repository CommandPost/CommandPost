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
    cmds
        :add("toggleEqualization")
        :whenActivated(fcp:inspector():audio():audioEnhancements():equalization().enabled:doPress())
        :titled(i18n("toggle") .. " " .. i18n("equalization"))

    cmds
        :add("toggleLoudness")
        :whenActivated(fcp:inspector():audio():audioEnhancements():audioAnalysis():loudness().enabled:doPress())
        :titled(i18n("toggle") .. " " .. i18n("loudness"))

    cmds
        :add("toggleNoiseRemoval")
        :whenActivated(fcp:inspector():audio():audioEnhancements():audioAnalysis():noiseRemoval().enabled:doPress())
        :titled(i18n("toggle") .. " " .. i18n("noiseRemoval"))

    cmds
        :add("toggleHumRemoval")
        :whenActivated(fcp:inspector():audio():audioEnhancements():audioAnalysis():humRemoval().enabled:doPress())
        :titled(i18n("toggle") .. " " .. i18n("humRemoval"))

    --------------------------------------------------------------------------------
    -- Audio Configuration:
    --------------------------------------------------------------------------------
    for i=1, 9 do
        cmds
            :add("toggleAudioComponent" .. i)
            :whenActivated(fcp:inspector():audio():audioConfiguration():component(i):enabled():doPress())
            :titled(i18n("toggle") .. " " .. i18n("audio") .. " " .. i18n("component") .. " " .. i)

        cmds
            :add("toggleAudioSubcomponent" .. i)
            :whenActivated(fcp:inspector():audio():audioConfiguration():subcomponent(i):enabled():doPress())
            :titled(i18n("toggle") .. " " .. i18n("audio") .. " " .. i18n("subcomponent") .. " " .. i)
    end

end

return plugin