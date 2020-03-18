--- === plugins.finalcutpro.timeline.colorwheels ===
---
--- Color Wheel Enhancements.

local require = require

--local log               = require "hs.logger".new "midicolorwheels"

local deferred          = require "cp.deferred"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"

local ColorWell         = require "cp.apple.finalcutpro.inspector.color.ColorWell"

local plugin = {
    id = "finalcutpro.timeline.colorwheels",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]            = "fcpxCmds",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- TODO: All of the below code is pretty rubbish. Should be re-engineered to
    --       use Rx. This is just a quick and dirty temporary workaround.
    --
    --       Sorry David!
    --------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- Define Ranges:
    --------------------------------------------------------------------------------
    local KEY_PRESS             = ColorWell.KEY_PRESS
    local MIX_RANGES            = {0.01, 0.02, 0.03, 0.04, 0.05, 0.1}
    local SATURATION_RANGES     = {0.01, 0.02, 0.03, 0.04, 0.05, 0.1}
    local BRIGHTNESS_RANGES     = {0.01, 0.02, 0.03, 0.04, 0.05, 0.1}
    local TINT_RANGES           = {0.1, 0.2, 0.3, 0.4, 0.5, 1, 5, 10}
    local TEMPERATURE_RANGES    = {5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 100, 200}

    local fcpxCmds = deps.fcpxCmds
    local colorWheels = fcp:inspector():color():colorWheels()
    --------------------------------------------------------------------------------
    -- Reset Master Color Wheel Color:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetMasterColorWheelColor")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:master():colorOrientation({right=0, up=0})
        end)

    --------------------------------------------------------------------------------
    -- Reset Master Color Wheel Saturation:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetMasterColorWheelSaturation")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:master():saturationValue(1)
        end)

    --------------------------------------------------------------------------------
    -- Reset Master Color Wheel Brightness:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetMasterColorWheelSaturation")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:master():brightnessValue(0)
        end)

    --------------------------------------------------------------------------------
    -- Reset Shadows Color Wheel Color:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetShadowsColorWheelColor")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:shadows():colorOrientation({right=0, up=0})
        end)

    --------------------------------------------------------------------------------
    -- Reset Shadows Color Wheel Saturation:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetShadowsColorWheelSaturation")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:shadows():saturationValue(1)
        end)

    --------------------------------------------------------------------------------
    -- Reset Shadows Color Wheel Brightness:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetShadowsColorWheelSaturation")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:shadows():brightnessValue(0)
        end)

    --------------------------------------------------------------------------------
    -- Reset Midtones Color Wheel Color:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetMidtonesColorWheelColor")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:midtones():colorOrientation({right=0, up=0})
        end)

    --------------------------------------------------------------------------------
    -- Reset Midtones Color Wheel Saturation:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetMidtonesColorWheelSaturation")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:midtones():saturationValue(1)
        end)

    --------------------------------------------------------------------------------
    -- Reset Midtones Color Wheel Brightness:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetMidtonesColorWheelSaturation")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:midtones():brightnessValue(0)
        end)

    --------------------------------------------------------------------------------
    -- Reset Highlights Color Wheel Color:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetHighlightsColorWheelColor")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:highlights():colorOrientation({right=0, up=0})
        end)

    --------------------------------------------------------------------------------
    -- Reset Highlights Color Wheel Saturation:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetHighlightsColorWheelSaturation")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:highlights():saturationValue(1)
        end)

    --------------------------------------------------------------------------------
    -- Reset Highlights Color Wheel Brightness:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetHighlightsColorWheelSaturation")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:highlights():brightnessValue(0)
        end)

    --------------------------------------------------------------------------------
    -- Reset Color Wheel Temperature:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetColorWheelTemperature")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:temperature(5000)
        end)

    --------------------------------------------------------------------------------
    -- Reset Color Wheel Tint:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetColorWheelTint")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:tint(0)
        end)

    --------------------------------------------------------------------------------
    -- Reset Color Wheel Mix:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetColorWheelMix")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:mix(0)
        end)


    --------------------------------------------------------------------------------
    -- Reset Color Wheel Mix:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpResetColorWheelMix")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:mix(1)
        end)

    --------------------------------------------------------------------------------
    -- Color Wheel Master - Wheels:
    --------------------------------------------------------------------------------
    local colorWheelMasterVerticalValue = 0
    local colorWheelMasterHorizontalValue = 0
    local updateColorWheelMaster = deferred.new(0.01):action(function()
        colorWheels:show()
        colorWheels:master():nudgeColor(colorWheelMasterHorizontalValue, colorWheelMasterVerticalValue)
        colorWheelMasterVerticalValue = 0
        colorWheelMasterHorizontalValue = 0
    end)

    fcpxCmds
        :add("colorWheelMasterUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelMasterVerticalValue = colorWheelMasterVerticalValue + KEY_PRESS
            updateColorWheelMaster()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("nudge") .. " " .. i18n("up"))

    fcpxCmds
        :add("colorWheelMasterDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelMasterVerticalValue = colorWheelMasterVerticalValue - KEY_PRESS
            updateColorWheelMaster()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("nudge") .. " " .. i18n("down"))

    fcpxCmds
        :add("colorWheelMasterLeft")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelMasterHorizontalValue = colorWheelMasterHorizontalValue - KEY_PRESS
            updateColorWheelMaster()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("nudge") .. " " .. i18n("left"))

    fcpxCmds
        :add("colorWheelMasterRight")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelMasterHorizontalValue = colorWheelMasterHorizontalValue + KEY_PRESS
            updateColorWheelMaster()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("nudge") .. " " .. i18n("right"))

    fcpxCmds
        :add("colorWheelMasterReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:master():reset():press()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Master - Saturation:
    --------------------------------------------------------------------------------
    local colorWheelMasterSaturationValue = 0
    local updateColorWheelMasterSaturation = deferred.new(0.01):action(function()
        colorWheels:show()
        colorWheels:master():saturation():shiftValue(colorWheelMasterSaturationValue)
        colorWheelMasterSaturationValue = 0
    end)

    for _, v in pairs(SATURATION_RANGES) do
        fcpxCmds
            :add("colorWheelMasterSaturationUp" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelMasterSaturationValue = colorWheelMasterSaturationValue - v
                updateColorWheelMasterSaturation()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " .. v)

        fcpxCmds
            :add("colorWheelMasterSaturationDown" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelMasterSaturationValue = colorWheelMasterSaturationValue + v
                updateColorWheelMasterSaturation()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("colorWheelMasterSaturationReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:master():saturation():value(1)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("saturation") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Master - Brightness:
    --------------------------------------------------------------------------------
    local colorWheelMasterBrightnessValue = 0
    local updateColorWheelMasterBrightness = deferred.new(0.01):action(function()
        colorWheels:show()
        colorWheels:master():brightness():shiftValue(colorWheelMasterBrightnessValue)
        colorWheelMasterBrightnessValue = 0
    end)

    for _, v in pairs(BRIGHTNESS_RANGES) do
        fcpxCmds
            :add("colorWheelMasterBrightnessUp" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelMasterBrightnessValue = colorWheelMasterBrightnessValue - v
                updateColorWheelMasterBrightness()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " .. v)

        fcpxCmds
            :add("colorWheelMasterBrightnessDown" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelMasterBrightnessValue = colorWheelMasterBrightnessValue + v
                updateColorWheelMasterBrightness()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("colorWheelMasterBrightnessReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:master():brightness():value(0)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("brightness") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Shadows - Wheels:
    --------------------------------------------------------------------------------
    local colorWheelShadowsVerticalValue = 0
    local colorWheelShadowsHorizontalValue = 0
    local updateColorWheelShadows = deferred.new(0.01):action(function()
        colorWheels:show()
        colorWheels:shadows():nudgeColor(colorWheelShadowsHorizontalValue, colorWheelShadowsVerticalValue)
        colorWheelShadowsVerticalValue = 0
        colorWheelShadowsHorizontalValue = 0
    end)

    fcpxCmds
        :add("colorWheelShadowsUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelShadowsVerticalValue = colorWheelShadowsVerticalValue + KEY_PRESS
            updateColorWheelShadows()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("nudge") .. " " .. i18n("up"))

    fcpxCmds
        :add("colorWheelShadowsDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelShadowsVerticalValue = colorWheelShadowsVerticalValue - KEY_PRESS
            updateColorWheelShadows()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("nudge") .. " " .. i18n("down"))

    fcpxCmds
        :add("colorWheelShadowsLeft")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelShadowsHorizontalValue = colorWheelShadowsHorizontalValue - KEY_PRESS
            updateColorWheelShadows()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("nudge") .. " " .. i18n("left"))

    fcpxCmds
        :add("colorWheelShadowsRight")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelShadowsHorizontalValue = colorWheelShadowsHorizontalValue + KEY_PRESS
            updateColorWheelShadows()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("nudge") .. " " .. i18n("right"))

    fcpxCmds
        :add("colorWheelShadowsReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:shadows():reset():press()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Shadows - Saturation:
    --------------------------------------------------------------------------------
    local colorWheelShadowsSaturationValue = 0
    local updateColorWheelShadowsSaturation = deferred.new(0.01):action(function()
        colorWheels:show()
        colorWheels:shadows():saturation():shiftValue(colorWheelShadowsSaturationValue)
        colorWheelShadowsSaturationValue = 0
    end)

    for _, v in pairs(SATURATION_RANGES) do
        fcpxCmds
            :add("colorWheelShadowsSaturationUp" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelShadowsSaturationValue = colorWheelShadowsSaturationValue - v
                updateColorWheelShadowsSaturation()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " .. v)

        fcpxCmds
            :add("colorWheelShadowsSaturationDown" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelShadowsSaturationValue = colorWheelShadowsSaturationValue + v
                updateColorWheelShadowsSaturation()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("colorWheelShadowsSaturationReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:shadows():saturation():value(1)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("saturation") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Shadows - Brightness:
    --------------------------------------------------------------------------------
    local colorWheelShadowsBrightnessValue = 0
    local updateColorWheelShadowsBrightness = deferred.new(0.01):action(function()
        colorWheels:show()
        colorWheels:shadows():brightness():shiftValue(colorWheelShadowsBrightnessValue)
        colorWheelShadowsBrightnessValue = 0
    end)

    for _, v in pairs(BRIGHTNESS_RANGES) do
        fcpxCmds
            :add("colorWheelShadowsBrightnessUp" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelShadowsBrightnessValue = colorWheelShadowsBrightnessValue - v
                updateColorWheelShadowsBrightness()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " .. v)

        fcpxCmds
            :add("colorWheelShadowsBrightnessDown" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelShadowsBrightnessValue = colorWheelShadowsBrightnessValue + v
                updateColorWheelShadowsBrightness()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("colorWheelShadowsBrightnessReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:shadows():brightness():value(0)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("brightness") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Midtones - Wheels:
    --------------------------------------------------------------------------------
    local colorWheelMidtonesVerticalValue = 0
    local colorWheelMidtonesHorizontalValue = 0
    local updateColorWheelMidtones = deferred.new(0.01):action(function()
        colorWheels:show()
        colorWheels:midtones():nudgeColor(colorWheelMidtonesHorizontalValue, colorWheelMidtonesVerticalValue)
        colorWheelMidtonesVerticalValue = 0
        colorWheelMidtonesHorizontalValue = 0
    end)

    fcpxCmds
        :add("colorWheelMidtonesUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelMidtonesVerticalValue = colorWheelMidtonesVerticalValue + KEY_PRESS
            updateColorWheelMidtones()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("nudge") .. " " .. i18n("up"))

    fcpxCmds
        :add("colorWheelMidtonesDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelMidtonesVerticalValue = colorWheelMidtonesVerticalValue - KEY_PRESS
            updateColorWheelMidtones()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("nudge") .. " " .. i18n("down"))

    fcpxCmds
        :add("colorWheelMidtonesLeft")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelMidtonesHorizontalValue = colorWheelMidtonesHorizontalValue - KEY_PRESS
            updateColorWheelMidtones()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("nudge") .. " " .. i18n("left"))

    fcpxCmds
        :add("colorWheelMidtonesRight")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelMidtonesHorizontalValue = colorWheelMidtonesHorizontalValue + KEY_PRESS
            updateColorWheelMidtones()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("nudge") .. " " .. i18n("right"))

    fcpxCmds
        :add("colorWheelMidtonesReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:midtones():reset():press()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Midtones - Saturation:
    --------------------------------------------------------------------------------
    local colorWheelMidtonesSaturationValue = 0
    local updateColorWheelMidtonesSaturation = deferred.new(0.01):action(function()
        colorWheels:show()
        colorWheels:midtones():saturation():shiftValue(colorWheelMidtonesSaturationValue)
        colorWheelMidtonesSaturationValue = 0
    end)

    for _, v in pairs(SATURATION_RANGES) do
        fcpxCmds
            :add("colorWheelMidtonesSaturationUp" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelMidtonesSaturationValue = colorWheelMidtonesSaturationValue - v
                updateColorWheelMidtonesSaturation()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " .. v)

        fcpxCmds
            :add("colorWheelMidtonesSaturationDown" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelMidtonesSaturationValue = colorWheelMidtonesSaturationValue + v
                updateColorWheelMidtonesSaturation()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("colorWheelMidtonesSaturationReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:midtones():saturation():value(1)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("saturation") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Midtones - Brightness:
    --------------------------------------------------------------------------------
    local colorWheelMidtonesBrightnessValue = 0
    local updateColorWheelMidtonesBrightness = deferred.new(0.01):action(function()
        colorWheels:show()
        colorWheels:midtones():brightness():shiftValue(colorWheelMidtonesBrightnessValue)
        colorWheelMidtonesBrightnessValue = 0
    end)

    for _, v in pairs(BRIGHTNESS_RANGES) do
        fcpxCmds
            :add("colorWheelMidtonesBrightnessUp" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelMidtonesBrightnessValue = colorWheelMidtonesBrightnessValue - v
                updateColorWheelMidtonesBrightness()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " .. v)

        fcpxCmds
            :add("colorWheelMidtonesBrightnessDown" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelMidtonesBrightnessValue = colorWheelMidtonesBrightnessValue + v
                updateColorWheelMidtonesBrightness()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("colorWheelMidtonesBrightnessReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:midtones():brightness():value(0)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("brightness") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Highlights - Wheels:
    --------------------------------------------------------------------------------
    local colorWheelHighlightsVerticalValue = 0
    local colorWheelHighlightsHorizontalValue = 0
    local updateColorWheelHighlights = deferred.new(0.01):action(function()
        colorWheels:show()
        colorWheels:highlights():nudgeColor(colorWheelHighlightsHorizontalValue, colorWheelHighlightsVerticalValue)
        colorWheelHighlightsVerticalValue = 0
        colorWheelHighlightsHorizontalValue = 0
    end)

    fcpxCmds
        :add("colorWheelHighlightsUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelHighlightsVerticalValue = colorWheelHighlightsVerticalValue + KEY_PRESS
            updateColorWheelHighlights()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("nudge") .. " " .. i18n("up"))

    fcpxCmds
        :add("colorWheelHighlightsDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelHighlightsVerticalValue = colorWheelHighlightsVerticalValue - KEY_PRESS
            updateColorWheelHighlights()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("nudge") .. " " .. i18n("down"))

    fcpxCmds
        :add("colorWheelHighlightsLeft")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelHighlightsHorizontalValue = colorWheelHighlightsHorizontalValue - KEY_PRESS
            updateColorWheelHighlights()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("nudge") .. " " .. i18n("left"))

    fcpxCmds
        :add("colorWheelHighlightsRight")
        :groupedBy("colorWheels")
        :whenActivated(function()
            colorWheelHighlightsHorizontalValue = colorWheelHighlightsHorizontalValue + KEY_PRESS
            updateColorWheelHighlights()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("nudge") .. " " .. i18n("right"))

    fcpxCmds
        :add("colorWheelHighlightsReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:highlights():reset():press()
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Highlights - Saturation:
    --------------------------------------------------------------------------------
    local colorWheelHighlightsSaturationValue = 0
    local updateColorWheelHighlightsSaturation = deferred.new(0.01):action(function()
        colorWheels:show()
        colorWheels:highlights():saturation():shiftValue(colorWheelHighlightsSaturationValue)
        colorWheelHighlightsSaturationValue = 0
    end)

    for _, v in pairs(SATURATION_RANGES) do
        fcpxCmds
            :add("colorWheelHighlightsSaturationUp" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelHighlightsSaturationValue = colorWheelHighlightsSaturationValue - v
                updateColorWheelHighlightsSaturation()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " .. v)

        fcpxCmds
            :add("colorWheelHighlightsSaturationDown" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelHighlightsSaturationValue = colorWheelHighlightsSaturationValue + v
                updateColorWheelHighlightsSaturation()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("colorWheelHighlightsSaturationReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:highlights():saturation():value(1)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("saturation") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Highlights - Brightness:
    --------------------------------------------------------------------------------
    local colorWheelHighlightsBrightnessValue = 0
    local updateColorWheelHighlightsBrightness = deferred.new(0.01):action(function()
        colorWheels:show()
        colorWheels:highlights():brightness():shiftValue(colorWheelHighlightsBrightnessValue)
        colorWheelHighlightsBrightnessValue = 0
    end)

    for _, v in pairs(BRIGHTNESS_RANGES) do
        fcpxCmds
            :add("colorWheelHighlightsBrightnessUp" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelHighlightsBrightnessValue = colorWheelHighlightsBrightnessValue - v
                updateColorWheelHighlightsBrightness()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " .. v)

        fcpxCmds
            :add("colorWheelHighlightsBrightnessDown" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelHighlightsBrightnessValue = colorWheelHighlightsBrightnessValue + v
                updateColorWheelHighlightsBrightness()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("colorWheelHighlightsBrightnessReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:highlights():brightness():value(0)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("brightness") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel - Temperature:
    --------------------------------------------------------------------------------
    local colorWheelTemperatureValue = 0
    local updateColorWheelTemperature = deferred.new(0.01):action(function()
        colorWheels:show()
        colorWheels:temperatureSlider():shiftValue(colorWheelTemperatureValue)
        colorWheelTemperatureValue = 0
    end)

    for _, v in pairs(TEMPERATURE_RANGES) do
        fcpxCmds
            :add("colorWheelTemperatureUp" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelTemperatureValue = colorWheelTemperatureValue - v
                updateColorWheelTemperature()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("temperature") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " ..  v)

        fcpxCmds
            :add("colorWheelTemperatureDown" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelTemperatureValue = colorWheelTemperatureValue + v
                updateColorWheelTemperature()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("temperature") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("colorWheelTemperatureReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:temperatureSlider():value(5000)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("temperature") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel - Tint:
    --------------------------------------------------------------------------------
    local colorWheelTintValue = 0
    local updateColorWheelTint = deferred.new(0.01):action(function()
        colorWheels:show()
        local currentValue = colorWheels:tint()
        colorWheels:tint(currentValue + colorWheelTintValue)
        colorWheelTintValue = 0
    end)

    for _, v in pairs(TINT_RANGES) do
        fcpxCmds
            :add("colorWheelTintUp" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelTintValue = colorWheelTintValue + v
                updateColorWheelTint()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("tint") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " .. v)

        fcpxCmds
            :add("colorWheelTintDown" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelTintValue = colorWheelTintValue - v
                updateColorWheelTint()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("tint") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("colorWheelTintReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:tint(0)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("tint") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel - Mix:
    --------------------------------------------------------------------------------
    local colorWheelMixValue = 0
    local updateColorWheelMix = deferred.new(0.01):action(function()
        colorWheels:show()
        local currentValue = colorWheels:mix()
        colorWheels:mix(currentValue + colorWheelMixValue)
        colorWheelMixValue = 0
    end)

    for _, v in pairs(MIX_RANGES) do
        fcpxCmds
            :add("colorWheelMixUp" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelMixValue = colorWheelMixValue + v
                updateColorWheelMix()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("mix") .. " - " .. i18n("nudge") .. " ".. i18n("up") .. " " .. v)

        fcpxCmds
            :add("colorWheelMixDown" .. v)
            :groupedBy("colorWheels")
            :whenActivated(function()
                colorWheelMixValue = colorWheelMixValue - v
                updateColorWheelMix()
            end)
            :titled(i18n("colorWheel") .. " - " .. i18n("mix") .. " - " .. i18n("nudge") .. " ".. i18n("down") .. " " .. v)
    end

    fcpxCmds
        :add("colorWheelMixReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:mix(0)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("mix") .. " - " .. i18n("reset"))

end

return plugin