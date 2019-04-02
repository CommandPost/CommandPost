--- === plugins.finalcutpro.tangent.audio ===
---
--- Final Cut Pro Audio Inspector for Tangent

local require = require

--local log                   = require("hs.logger").new("tangentVideo")

local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.audio",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.common"]  = "common",
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup:
    --------------------------------------------------------------------------------
    local id                            = 0x0F740000

    local common                        = deps.common
    local fcpGroup                      = deps.fcpGroup

    local buttonParameter               = common.buttonParameter
    local checkboxParameter             = common.checkboxParameter
    local checkboxParameterByIndex      = common.checkboxParameterByIndex
    local doShowParameter               = common.doShowParameter
    local ninjaButtonParameter          = common.ninjaButtonParameter
    local popupParameters               = common.popupParameters
    local popupSliderParameter          = common.popupSliderParameter
    local radioButtonParameter          = common.radioButtonParameter
    local sliderParameter               = common.sliderParameter
    local volumeSliderParameter         = common.volumeSliderParameter

    --------------------------------------------------------------------------------
    -- AUDIO INSPECTOR:
    --------------------------------------------------------------------------------
    local audio                         = fcp:inspector():audio()
    local audioGroup                    = fcpGroup:group(i18n("audio") .. " " .. i18n("inspector"))

    local PAN_MODES                     = audio.PAN_MODES
    local EQ_MODES                      = audio.EQ_MODES

        --------------------------------------------------------------------------------
        -- Show Inspector:
        --------------------------------------------------------------------------------
        id = doShowParameter(audioGroup, audio, id, i18n("show") .. " " .. i18n("inspector"))

        --------------------------------------------------------------------------------
        --
        -- VOLUME:
        --
        --------------------------------------------------------------------------------
        local volume = audio:volume()
        local volumeGroup = audioGroup:group(i18n("volume"))

            --------------------------------------------------------------------------------
            -- Volume:
            --------------------------------------------------------------------------------
            id = sliderParameter(volumeGroup, volume, id, -95, 12, 0.1, 0)

            --------------------------------------------------------------------------------
            -- Volume (Automatic Keyframes):
            --------------------------------------------------------------------------------
            id = volumeSliderParameter(volumeGroup, volume, id, -95, 12, 0.1, 0, i18n("volume") .. " (" .. i18n("automaticKeyframes") .. ")")

        --------------------------------------------------------------------------------
        --
        -- AUDIO ENHANCEMENTS:
        --
        --------------------------------------------------------------------------------
        local audioEnhancements = audio:audioEnhancements()
        local audioEnhancementsGroup = audioGroup:group(i18n("audioEnhancements"))

                --------------------------------------------------------------------------------
                -- Reset:
                --------------------------------------------------------------------------------
                id = ninjaButtonParameter(audioEnhancementsGroup, audioEnhancements.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Equalisation:
            --------------------------------------------------------------------------------
            local equalization = audioEnhancements:equalization()
            local equalizationGroup = audioEnhancementsGroup:group(i18n("equalization"))

                --------------------------------------------------------------------------------
                -- Enable/Disable:
                --------------------------------------------------------------------------------
                id = checkboxParameter(equalizationGroup, equalization.enabled, id, "toggle")

                --------------------------------------------------------------------------------
                -- EQ Modes (Buttons):
                --------------------------------------------------------------------------------
                local eqMode = equalization.mode
                local eqModeGroup = equalizationGroup:group(i18n("modes"))
                id = popupParameters(eqModeGroup, eqMode, id, EQ_MODES)

                --------------------------------------------------------------------------------
                -- EQ Modes (Knob):
                --------------------------------------------------------------------------------
                id = popupSliderParameter(equalizationGroup, eqMode, id, "mode", EQ_MODES, 1)

                --------------------------------------------------------------------------------
                -- Show the Advanced Equaliser UI:
                --------------------------------------------------------------------------------
                local enhanced = equalization.enhanced
                id = buttonParameter(equalizationGroup, enhanced, id, "showTheAdvancedEqualizerUI")

            --------------------------------------------------------------------------------
            -- Audio Analysis:
            --------------------------------------------------------------------------------
            local audioAnalysis = audioEnhancements:audioAnalysis()
            local audioAnalysisGroup = audioEnhancementsGroup:group(i18n("audioAnalysis"))

                    --------------------------------------------------------------------------------
                    -- Reset:
                    --------------------------------------------------------------------------------
                    id = ninjaButtonParameter(audioAnalysisGroup, audioAnalysis.reset, id, "reset")

                    --------------------------------------------------------------------------------
                    -- Magic Button:
                    --------------------------------------------------------------------------------
                    local magicButton = audioAnalysis.magic
                    id = buttonParameter(audioAnalysisGroup, magicButton, id, "magicButton")

                --------------------------------------------------------------------------------
                -- Loudness:
                --------------------------------------------------------------------------------
                local loudness = audioAnalysis:loudness()
                local loudnessGroup = audioGroup:group(i18n("loudness"))

                    --------------------------------------------------------------------------------
                    -- Enable/Disable:
                    --------------------------------------------------------------------------------
                    id = checkboxParameter(loudnessGroup, loudness.enabled, id, "toggle")

                    --------------------------------------------------------------------------------
                    -- Reset:
                    --------------------------------------------------------------------------------
                    id = ninjaButtonParameter(loudnessGroup, loudness.reset, id, "reset")

                    --------------------------------------------------------------------------------
                    -- Amount / Uniformity:
                    --------------------------------------------------------------------------------
                    id = sliderParameter(loudnessGroup, loudness:amount(), id, 0, 100, 0.1, 100.0)
                    id = sliderParameter(loudnessGroup, loudness:uniformity(), id, 0, 100, 0.1, 0)

                --------------------------------------------------------------------------------
                -- Noise Removal:
                --------------------------------------------------------------------------------
                local noiseRemoval = audioAnalysis:noiseRemoval()
                local noiseRemovalGroup = audioEnhancementsGroup:group(i18n("noiseRemoval"))

                    --------------------------------------------------------------------------------
                    -- Enable/Disable:
                    --------------------------------------------------------------------------------
                    id = checkboxParameter(noiseRemovalGroup, noiseRemoval.enabled, id, "toggle")

                    --------------------------------------------------------------------------------
                    -- Reset:
                    --------------------------------------------------------------------------------
                    id = ninjaButtonParameter(noiseRemovalGroup, noiseRemoval.reset, id, "reset")

                    --------------------------------------------------------------------------------
                    -- Amount / Uniformity:
                    --------------------------------------------------------------------------------
                    id = sliderParameter(noiseRemovalGroup, noiseRemoval:amount(), id, 0, 100, 0.1, 100.0)

                --------------------------------------------------------------------------------
                -- Hum Removal:
                --------------------------------------------------------------------------------
                local humRemoval = audioAnalysis:humRemoval()
                local humRemovalGroup = audioEnhancementsGroup:group(i18n("humRemoval"))

                    --------------------------------------------------------------------------------
                    -- Enable/Disable:
                    --------------------------------------------------------------------------------
                    id = checkboxParameter(humRemovalGroup, humRemoval.enabled, id, "toggle")

                    --------------------------------------------------------------------------------
                    -- Reset:
                    --------------------------------------------------------------------------------
                    id = ninjaButtonParameter(humRemovalGroup, humRemoval.reset, id, "reset")

                    --------------------------------------------------------------------------------
                    -- Frequency - 50Hz / 60Hz:
                    --------------------------------------------------------------------------------
                    local frequency = humRemoval:frequency()
                    id = radioButtonParameter(humRemovalGroup, frequency.fiftyHz, id, "fiftyHz")
                    id = radioButtonParameter(humRemovalGroup, frequency.sixtyHz, id, "sixtyHz")

        --------------------------------------------------------------------------------
        --
        -- PAN:
        --
        --------------------------------------------------------------------------------
        local pan = audio:pan()
        local panGroup = audioGroup:group(i18n("pan"))

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(panGroup, pan.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Mode (Buttons):
            --------------------------------------------------------------------------------
            local panMode = pan:mode()
            local panModeGroup = panGroup:group(i18n("modes"))
            id = popupParameters(panModeGroup, panMode, id, PAN_MODES)

            --------------------------------------------------------------------------------
            -- Type (Knob):
            --------------------------------------------------------------------------------
            id = popupSliderParameter(panGroup, panMode.value, id, "pan", PAN_MODES, 1)

            --------------------------------------------------------------------------------
            -- Amount:
            --------------------------------------------------------------------------------
            id = sliderParameter(panGroup, pan:amount(), id, -100, 100, 0.1, 0)

            --------------------------------------------------------------------------------
            -- TODO: Add Surround Panner.
            --------------------------------------------------------------------------------
            id = id + 20

        --------------------------------------------------------------------------------
        --
        -- Effects:
        --
        --------------------------------------------------------------------------------
        local effects = audio:effects()
        local effectsGroup = audioGroup:group(i18n("effects"))

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(effectsGroup, effects.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Individual Effects:
            --------------------------------------------------------------------------------
            local individualEffectsGroup = effectsGroup:group(i18n("individualEffects"))
            for i=1, 9 do
                id = checkboxParameterByIndex(individualEffectsGroup, effects, nil, id, i18n("toggle") .. " " .. i, i)
            end

        --------------------------------------------------------------------------------
        --
        -- Audio Configuration:
        --
        --------------------------------------------------------------------------------
        local audioConfiguration = audio:audioConfiguration()
        local audioConfigurationGroup = audioGroup:group(i18n("audioConfiguration"))

            --------------------------------------------------------------------------------
            -- Individual Components:
            --------------------------------------------------------------------------------
            local componentsGroup = audioConfigurationGroup:group(i18n("components"))
            for i=1, 9 do
                id = buttonParameter(componentsGroup, audioConfiguration:component(i):enabled(), id, i18n("toggle") .. " " .. i)
            end

            --------------------------------------------------------------------------------
            -- Individual Subcomponents:
            --------------------------------------------------------------------------------
            local subcomponentsGroup = audioConfigurationGroup:group(i18n("subcomponents"))
            for i=1, 9 do
                id = buttonParameter(subcomponentsGroup, audioConfiguration:subcomponent(i):enabled(), id, i18n("toggle") .. " " .. i)
            end

end

return plugin
