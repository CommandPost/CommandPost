--- === plugins.finalcutpro.inspector.coloradjustments ===
---
--- Actions for the Final Cut Pro Color Adjustments Effect.

local require = require

--local log                   = require "hs.logger".new "videoInspector"

local deferred              = require "cp.deferred"
local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"

local plugin = {
    id              = "finalcutpro.inspector.coloradjustments",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local SHIFT_AMOUNTS = {0.1, 1, 5, 10, 15, 20, 25, 30, 35, 40}

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds

    --------------------------------------------------------------------------------
    -- Control Range Actions:
    --------------------------------------------------------------------------------
    local colorAdjustments = fcp.inspector.color.colorAdjustments

    local controlRanges = colorAdjustments.CONTROL_RANGES

    for _, id in pairs(controlRanges) do
        local label = colorAdjustments:controlRangeLabel(id)
        fcpxCmds
            :add("colorAdjustmentsControlRange" .. id)
            :whenActivated(function() colorAdjustments:controlRange(id) end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("controlRange") ..  ": " .. label)
    end

    --------------------------------------------------------------------------------
    -- Exposure:
    --------------------------------------------------------------------------------
    local exposureValue = 0
    local updateExposure = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.exposureSlider:shiftValue(exposureValue)
            exposureValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsExposureIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                exposureValue = exposureValue - v
                updateExposure()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("exposure") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsExposureDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                exposureValue = exposureValue + v
                updateExposure()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("exposure") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("exposureReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.exposure:value(0)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("exposure") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Contrast:
    --------------------------------------------------------------------------------
    local contrastValue = 0
    local updateContrast = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.contrastSlider:shiftValue(contrastValue)
            contrastValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsContrastIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                contrastValue = contrastValue - v
                updateContrast()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("contrast") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsContrastDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                contrastValue = contrastValue + v
                updateContrast()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("contrast") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("contrastReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.contrast:value(0)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("contrast") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Brightness:
    --------------------------------------------------------------------------------
    local brightnessValue = 0
    local updateBrightness = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.brightnessSlider:shiftValue(brightnessValue)
            brightnessValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsBrightnessIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                brightnessValue = brightnessValue - v
                updateBrightness()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsBrightnessDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                brightnessValue = brightnessValue + v
                updateBrightness()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("brightnessReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.brightness:value(0)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("brightness") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Saturation:
    --------------------------------------------------------------------------------
    local saturationValue = 0
    local updateSaturation = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.saturationSlider:shiftValue(saturationValue)
            saturationValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsSaturationIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                saturationValue = saturationValue - v
                updateSaturation()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsSaturationDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                saturationValue = saturationValue + v
                updateSaturation()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("saturationReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.saturation:value(0)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("saturation") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Highlights:
    --------------------------------------------------------------------------------
    local highlightsValue = 0
    local updateHighlights = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.highlightsSlider:shiftValue(highlightsValue)
            highlightsValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsHighlightsIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                highlightsValue = highlightsValue - v
                updateHighlights()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("highlights") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsHighlightsDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                highlightsValue = highlightsValue + v
                updateHighlights()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("highlights") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("highlightsReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.highlights:value(0)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("highlights") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Black Point:
    --------------------------------------------------------------------------------
    local blackPointValue = 0
    local updateBlackPoint = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.blackPointSlider:shiftValue(blackPointValue)
            blackPointValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsBlackPointIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                blackPointValue = blackPointValue - v
                updateBlackPoint()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("blackPoint") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsBlackPointDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                blackPointValue = blackPointValue + v
                updateBlackPoint()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("blackPoint") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("blackPointReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.blackPoint:value(0)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("blackPoint") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Shadows:
    --------------------------------------------------------------------------------
    local shadowsValue = 0
    local updateShadows = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.shadowsSlider:shiftValue(shadowsValue)
            shadowsValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsShadowsIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                shadowsValue = shadowsValue - v
                updateShadows()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("shadows") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsShadowsDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                shadowsValue = shadowsValue + v
                updateShadows()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("shadows") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("shadowsReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.shadows:value(0)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("shadows") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Highlights Warmth:
    --------------------------------------------------------------------------------
    local highlightsWarmthValue = 0
    local updateHighlightsWarmth = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.highlightsWarmthSlider:shiftValue(highlightsWarmthValue)
            highlightsWarmthValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsHighlightsWarmthIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                highlightsWarmthValue = highlightsWarmthValue - v
                updateHighlightsWarmth()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("highlightsWarmth") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsHighlightsWarmthDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                highlightsWarmthValue = highlightsWarmthValue + v
                updateHighlightsWarmth()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("highlightsWarmth") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("highlightsWarmthReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.highlightsWarmth:value(0)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("highlightsWarmth") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Highlights Tint:
    --------------------------------------------------------------------------------
    local highlightsTintValue = 0
    local updateHighlightsTint = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.highlightsTintSlider:shiftValue(highlightsTintValue)
            highlightsTintValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsHighlightsTintIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                highlightsTintValue = highlightsTintValue - v
                updateHighlightsTint()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("highlightsTint") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsHighlightsTintDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                highlightsTintValue = highlightsTintValue + v
                updateHighlightsTint()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("highlightsTint") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("highlightsTintReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.highlightsTint:value(0)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("highlightsTint") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Midtones Warmth:
    --------------------------------------------------------------------------------
    local midtonesWarmthValue = 0
    local updateMidtonesWarmth = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.midtonesWarmthSlider:shiftValue(midtonesWarmthValue)
            midtonesWarmthValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsMidtonesWarmthIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                midtonesWarmthValue = midtonesWarmthValue - v
                updateMidtonesWarmth()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("midtonesWarmth") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsMidtonesWarmthDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                midtonesWarmthValue = midtonesWarmthValue + v
                updateMidtonesWarmth()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("midtonesWarmth") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("midtonesWarmthReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.midtonesWarmth:value(0)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("midtonesWarmth") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Midtones Tint:
    --------------------------------------------------------------------------------
    local midtonesTintValue = 0
    local updateMidtonesTint = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.midtonesTintSlider:shiftValue(midtonesTintValue)
            midtonesTintValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsMidtonesTintIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                midtonesTintValue = midtonesTintValue - v
                updateMidtonesTint()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("midtonesTint") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsMidtonesTintDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                midtonesTintValue = midtonesTintValue + v
                updateMidtonesTint()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("midtonesTint") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("midtonesTintReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.midtonesTint:value(0)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("midtonesTint") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Shadows Warmth:
    --------------------------------------------------------------------------------
    local shadowsWarmthValue = 0
    local updateShadowsWarmth = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.shadowsWarmthSlider:shiftValue(shadowsWarmthValue)
            shadowsWarmthValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsShadowsWarmthIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                shadowsWarmthValue = shadowsWarmthValue - v
                updateShadowsWarmth()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("shadowsWarmth") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsShadowsWarmthDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                shadowsWarmthValue = shadowsWarmthValue + v
                updateShadowsWarmth()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("shadowsWarmth") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("shadowsWarmthReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.shadowsWarmth:value(0)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("shadowsWarmth") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Shadows Tint:
    --------------------------------------------------------------------------------
    local shadowsTintValue = 0
    local updateShadowsTint = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.shadowsTintSlider:shiftValue(shadowsTintValue)
            shadowsTintValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsShadowsTintIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                shadowsTintValue = shadowsTintValue - v
                updateShadowsTint()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("shadowsTint") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsShadowsTintDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                shadowsTintValue = shadowsTintValue + v
                updateShadowsTint()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("shadowsTint") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("shadowsTintReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.shadowsTint:value(0)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("shadowsTint") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Mix:
    --------------------------------------------------------------------------------
    local mixValue = 0
    local updateMix = deferred.new(0.01):action(function()
        colorAdjustments:doShow():Then(function()
            colorAdjustments.mixSlider:shiftValue(mixValue)
            mixValue = 0
        end):Now()
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        fcpxCmds
            :add("colorAdjustmentsMixIncrease" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                mixValue = mixValue - v
                updateMix()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("mix") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorAdjustmentsMixDown" .. v)
            :groupedBy("colorAdjustments")
            :whenActivated(function()
                mixValue = mixValue + v
                updateMix()
            end)
            :titled(i18n("colorAdjustments") .. " - " .. i18n("mix") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("mixReset")
        :groupedBy("colorAdjustments")
        :whenActivated(function()
            colorAdjustments:doShow():Then(function()
                colorAdjustments.mix:value(1)
            end):Now()
        end)
        :titled(i18n("colorAdjustments") .. " - " .. i18n("mix") .. " - " .. i18n("reset"))

end

return plugin
