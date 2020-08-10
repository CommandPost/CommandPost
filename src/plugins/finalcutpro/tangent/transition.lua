--- === plugins.finalcutpro.tangent.transition ===
---
--- Final Cut Pro Transition Inspector for Tangent

local require = require

--local log                   = require("hs.logger").new("tangentTrans")

local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")

local plugin = {
    id = "finalcutpro.tangent.transition",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.common"]  = "common",
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup:
    --------------------------------------------------------------------------------
    local id                            = 0x0F800000

    local common                        = deps.common
    local fcpGroup                      = deps.fcpGroup

    local doShowParameter               = common.doShowParameter
    local ninjaButtonParameter          = common.ninjaButtonParameter
    local popupParameters               = common.popupParameters
    local popupSliderParameter          = common.popupSliderParameter
    local sliderParameter               = common.sliderParameter

    --------------------------------------------------------------------------------
    -- TRANSITION INSPECTOR:
    --------------------------------------------------------------------------------
    local transition                     = fcp.inspector:transition()
    local transitionGroup                = fcpGroup:group(i18n("transition") .. " " .. i18n("inspector"))

        --------------------------------------------------------------------------------
        -- Show Inspector:
        --------------------------------------------------------------------------------
        id = doShowParameter(transitionGroup, transition, id, i18n("show") .. " " .. i18n("inspector"))

        --------------------------------------------------------------------------------
        --
        -- Cross Dissolve:
        --
        --------------------------------------------------------------------------------
        local crossDissolve = transition:crossDissolve()
        local crossDissolveGroup = transitionGroup:group(i18n("crossDissolve"))

        local LOOKS = transition.LOOKS
        local EASE_TYPES = transition.EASE_TYPES

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(crossDissolveGroup, crossDissolve.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Look (Buttons):
            --------------------------------------------------------------------------------
            local lookGroup = crossDissolveGroup:group(i18n("look"))
            id = popupParameters(lookGroup, crossDissolve:look(), id, LOOKS)

            --------------------------------------------------------------------------------
            -- Look (Knob):
            --------------------------------------------------------------------------------
            id = popupSliderParameter(crossDissolveGroup, crossDissolve:look().value, id, "look", LOOKS, 12)

            --------------------------------------------------------------------------------
            -- Amount:
            --------------------------------------------------------------------------------
            id = sliderParameter(crossDissolveGroup, crossDissolve:amount(), id, 0, 100, 0.1, 50)

            --------------------------------------------------------------------------------
            -- Ease (Buttons):
            --------------------------------------------------------------------------------
            local easeGroup = crossDissolveGroup:group(i18n("ease"))
            id = popupParameters(easeGroup, crossDissolve:ease(), id, EASE_TYPES)

            --------------------------------------------------------------------------------
            -- Ease (Knob):
            --------------------------------------------------------------------------------
            id = popupSliderParameter(crossDissolveGroup, crossDissolve:ease().value, id, "ease", EASE_TYPES, 3)

            --------------------------------------------------------------------------------
            -- Ease Amount:
            --------------------------------------------------------------------------------
            id = sliderParameter(crossDissolveGroup, crossDissolve:easeAmount(), id, 0, 100, 0.1, 0)

        --------------------------------------------------------------------------------
        --
        -- Audio Crossfade:
        --
        --------------------------------------------------------------------------------
        local audioCrossfade = transition:audioCrossfade()
        local audioCrossfadeGroup = transitionGroup:group(i18n("audioCrossfade"))

        local FADE_TYPES = transition.FADE_TYPES

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(transitionGroup, audioCrossfade.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Fade In Type (Buttons):
            --------------------------------------------------------------------------------
            local fadeInTypeGroup = audioCrossfadeGroup:group(i18n("fadeInType"))
            id = popupParameters(fadeInTypeGroup, audioCrossfade:fadeInType(), id, FADE_TYPES)

            --------------------------------------------------------------------------------
            -- Fade In Type (Knob):
            --------------------------------------------------------------------------------
            id = popupSliderParameter(audioCrossfadeGroup, audioCrossfade:fadeInType().value, id, "fadeInType", FADE_TYPES, 4)

            --------------------------------------------------------------------------------
            -- Fade Out Type (Buttons):
            --------------------------------------------------------------------------------
            local fadeOutTypeGroup = audioCrossfadeGroup:group(i18n("fadeOutType"))
            id = popupParameters(fadeOutTypeGroup, audioCrossfade:fadeOutType(), id, FADE_TYPES)

            --------------------------------------------------------------------------------
            -- Fade Out Type (Knob):
            --------------------------------------------------------------------------------
            popupSliderParameter(audioCrossfadeGroup, audioCrossfade:fadeOutType().value, id, "fadeOutType", FADE_TYPES, 4)

end

return plugin
