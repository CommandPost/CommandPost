--- === plugins.finalcutpro.tangent.audio ===
---
--- Final Cut Pro Audio Inspector for Tangent

local require = require

--local log                   = require("hs.logger").new("tangentVideo")

local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")
local tools                 = require("cp.tools")

local tableCount            = tools.tableCount

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
    local popupParameter                = common.popupParameter
    local popupParameters               = common.popupParameters
    local popupSliderParameter          = common.popupSliderParameter
    local sliderParameter               = common.sliderParameter
    local xyParameter                   = common.xyParameter

    --------------------------------------------------------------------------------
    -- AUDIO INSPECTOR:
    --------------------------------------------------------------------------------
    local audio                         = fcp:inspector():audio()
    local audioGroup                    = deps.fcpGroup:group(i18n("audio") .. " " .. i18n("inspector"))

    local PAN_MODES                     = audio.PAN_MODES
    local EQ_MODES                      = audio.EQ_MODES

        --------------------------------------------------------------------------------
        --
        -- VOLUME:
        --
        --------------------------------------------------------------------------------
        local volume = audio:volume()

            --------------------------------------------------------------------------------
            -- Volume:
            --------------------------------------------------------------------------------
            id = sliderParameter(audioGroup, volume, id, -95, 12, 0.1, 0)

        --------------------------------------------------------------------------------
        --
        -- AUDIO ENHANCEMENTS:
        --
        --------------------------------------------------------------------------------
        local audioEnhancements = audio:audioEnhancements()

            --------------------------------------------------------------------------------
            -- Equalisation:
            --------------------------------------------------------------------------------
            local equalization = audioEnhancements:equalization()
            local equalizationGroup = audioGroup:group(i18n("equalization"))

                --------------------------------------------------------------------------------
                -- Enable/Disable:
                --------------------------------------------------------------------------------
                id = checkboxParameter(equalizationGroup, equalization, id, "toggle")

                --------------------------------------------------------------------------------
                -- EQ Modes (Buttons):
                --------------------------------------------------------------------------------
                local eqMode = equalization.mode
                local eqModeGroup = equalizationGroup:group(i18n("mode"))
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
            local audioAnalysisGroup = audioGroup:group(i18n("audioAnalysis"))

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
                    id = checkboxParameter(loudnessGroup, loudness, id, "toggle")

                    --------------------------------------------------------------------------------
                    -- Amount / Uniformity:
                    --------------------------------------------------------------------------------
                    id = sliderParameter(loudnessGroup, loudness:amount(), id, 0, 100, 0.1, 100.0)
                    id = sliderParameter(loudnessGroup, loudness:uniformity(), id, 0, 100, 0.1, 0)

                --------------------------------------------------------------------------------
                -- Noise Removal:
                --------------------------------------------------------------------------------
                local noiseRemoval = audioAnalysis:noiseRemoval()
                local noiseRemovalGroup = audioGroup:group(i18n("noiseRemoval"))

                    --------------------------------------------------------------------------------
                    -- Enable/Disable:
                    --------------------------------------------------------------------------------
                    id = checkboxParameter(noiseRemovalGroup, noiseRemoval, id, "toggle")

                    --------------------------------------------------------------------------------
                    -- Amount / Uniformity:
                    --------------------------------------------------------------------------------
                    id = sliderParameter(noiseRemovalGroup, noiseRemoval:amount(), id, 0, 100, 0.1, 100.0)

                --------------------------------------------------------------------------------
                -- Hum Removal:
                --------------------------------------------------------------------------------
                local humRemoval = audioAnalysis:humRemoval()
                local humRemovalGroup = audioGroup:group(i18n("humRemoval"))

                    --------------------------------------------------------------------------------
                    -- Enable/Disable:
                    --------------------------------------------------------------------------------
                    id = checkboxParameter(humRemovalGroup, humRemoval, id, "toggle")

                    --------------------------------------------------------------------------------
                    -- Frequency - 50Hz / 60Hz:
                    --------------------------------------------------------------------------------
                    local frequency = humRemoval:frequency()
                    --id = checkboxParameter(humRemovalGroup, frequency.fiftyHz, id, "fiftyHz")
                    --id = checkboxParameter(humRemovalGroup, humRemoval.fiftyHz, id, "sixtyHz")

        --------------------------------------------------------------------------------
        --
        -- PAN:
        --
        --------------------------------------------------------------------------------
        local pan = audio:pan()
        local panGroup = audioGroup:group(i18n("pan"))

            --------------------------------------------------------------------------------
            -- Mode (Buttons):
            --------------------------------------------------------------------------------
            local panMode = pan:mode()
            local panModeGroup = panGroup:group(i18n("mode"))
            id = popupParameters(panModeGroup, panMode, id, PAN_MODES)

            --------------------------------------------------------------------------------
            -- Type (Knob):
            --------------------------------------------------------------------------------
            id = popupSliderParameter(panGroup, panMode, id, "pan", PAN_MODES, 1)

        --------------------------------------------------------------------------------
        --
        -- Effects:
        --
        --------------------------------------------------------------------------------
        local effects = audio:effects()
        local effectsGroup = audioGroup:group(i18n("effects"))

            --------------------------------------------------------------------------------
            -- Individual Effects:
            --------------------------------------------------------------------------------
            local individualEffectsGroup = effectsGroup:group(i18n("individualEffects"))
            for i=1, 9 do
                id = checkboxParameterByIndex(individualEffectsGroup, effects, nil, id, i18n("toggle") .. " " .. i, i)
            end

end

return plugin
