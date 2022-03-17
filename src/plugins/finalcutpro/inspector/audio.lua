--- === plugins.finalcutpro.inspector.audio ===
---
--- Final Cut Pro Audio Inspector Additions.

local require = require

local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"
local tools                 = require "cp.tools"

local playErrorSound        = tools.playErrorSound

local plugin = {
    id              = "finalcutpro.inspector.audio",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "cmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Audio Enhancements:
    --------------------------------------------------------------------------------
    local cmds = deps.cmds
    local audio = fcp.inspector.audio
    local audioEnhancements = audio:audioEnhancements()
    local audioConfiguration = audio.audioConfiguration
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
            :titled(i18n("setVolumeTo") .. " " .. tostring(i) .. " dB")
            :subtitled(i18n("controlsTheVolumeInTheFinalCutProAudioInspector"))
    end

    local increments = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1.5, 2, 2.5, 3, 3.5}
    for _, increment in pairs(increments) do
        cmds
            :add("increaseVolumeBy" .. " " .. increment)
            :whenActivated(function()
                local volume = audio:volume()
                volume:show()
                local currentValue = volume:value()
                if currentValue then
                    volume:value(currentValue + increment)
                else
                     playErrorSound()
                end
            end)
            :titled(i18n("increaseVolumeBy") .. " " .. increment .. " dB")
            :subtitled(i18n("controlsTheVolumeInTheFinalCutProAudioInspector"))

        cmds
            :add("decreaseVolumeBy" .. " " .. increment)
            :whenActivated(function()
                local volume = audio:volume()
                volume:show()
                local currentValue = volume:value()
                if currentValue then
                    volume:value(currentValue - increment)
                else
                     playErrorSound()
                end
            end)
            :titled(i18n("decreaseVolumeBy") .. " " .. increment .. " dB")
            :subtitled(i18n("controlsTheVolumeInTheFinalCutProAudioInspector"))
    end

end

return plugin