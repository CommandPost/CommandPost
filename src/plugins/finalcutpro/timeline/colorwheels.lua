--- === plugins.finalcutpro.timeline.colorwheels ===
---
--- Color Wheel Enhancements.

local require = require

--local log               = require "hs.logger".new "midicolorwheels"

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

    local fcpxCmds = deps.fcpxCmds

    local KEY_PRESS = ColorWell.KEY_PRESS

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
    fcpxCmds
        :add("colorWheelMasterUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:master():nudgeColor(0, KEY_PRESS)
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("nudge") .. " " .. i18n("up"))

    fcpxCmds
        :add("colorWheelMasterDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:master():nudgeColor(0, KEY_PRESS * -1)
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("nudge") .. " " .. i18n("down"))

    fcpxCmds
        :add("colorWheelMasterLeft")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:master():nudgeColor(KEY_PRESS * -1, 0)
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("nudge") .. " " .. i18n("left"))

    fcpxCmds
        :add("colorWheelMasterRight")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:master():nudgeColor(KEY_PRESS, 0)
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("nudge") .. " " .. i18n("right"))

    fcpxCmds
        :add("colorWheelMasterReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:master():reset():press()
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Master - Saturation:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("colorWheelMasterSaturationUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:master():saturation():shiftValue(-0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("up"))

    fcpxCmds
        :add("colorWheelMasterSaturationDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:master():saturation():shiftValue(0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("down"))

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
    fcpxCmds
        :add("colorWheelMasterBrightnessUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:master():brightness():shiftValue(-0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("up"))

    fcpxCmds
        :add("colorWheelMasterBrightnessDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:master():brightness():shiftValue(0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("master") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("down"))

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
    fcpxCmds
        :add("colorWheelShadowsUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:shadows():nudgeColor(0, KEY_PRESS)
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("nudge") .. " " .. i18n("up"))

    fcpxCmds
        :add("colorWheelShadowsDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:shadows():nudgeColor(0, KEY_PRESS * -1)
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("nudge") .. " " .. i18n("down"))

    fcpxCmds
        :add("colorWheelShadowsLeft")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:shadows():nudgeColor(KEY_PRESS * -1, 0)
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("nudge") .. " " .. i18n("left"))

    fcpxCmds
        :add("colorWheelShadowsRight")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:shadows():nudgeColor(KEY_PRESS, 0)
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("nudge") .. " " .. i18n("right"))

    fcpxCmds
        :add("colorWheelShadowsReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:shadows():reset():press()
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Shadows - Saturation:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("colorWheelShadowsSaturationUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:shadows():saturation():shiftValue(-0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("up"))

    fcpxCmds
        :add("colorWheelShadowsSaturationDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:shadows():saturation():shiftValue(0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("down"))

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
    fcpxCmds
        :add("colorWheelShadowsBrightnessUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:shadows():brightness():shiftValue(-0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("up"))

    fcpxCmds
        :add("colorWheelShadowsBrightnessDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:shadows():brightness():shiftValue(0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("down"))

    fcpxCmds
        :add("colorWheelShadowsBrightnessReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:shadows():brightness():value(0)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("shadows") .. " - " .. i18n("brightness") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Midtones:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("colorWheelMidtonesUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:midtones():nudgeColor(0, KEY_PRESS)
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("nudge") .. " " .. i18n("up"))

    fcpxCmds
        :add("colorWheelMidtonesDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:midtones():nudgeColor(0, KEY_PRESS * -1)
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("nudge") .. " " .. i18n("down"))

    fcpxCmds
        :add("colorWheelMidtonesLeft")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:midtones():nudgeColor(KEY_PRESS * -1, 0)
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("nudge") .. " " .. i18n("left"))

    fcpxCmds
        :add("colorWheelMidtonesRight")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:midtones():nudgeColor(KEY_PRESS, 0)
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("nudge") .. " " .. i18n("right"))

    fcpxCmds
        :add("colorWheelMidtonesReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
                colorWheels:midtones():reset():press()
        end)        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Midtones - Saturation:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("colorWheelMidtonesSaturationUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:midtones():saturation():shiftValue(-0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("up"))

    fcpxCmds
        :add("colorWheelMidtonesSaturationDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:midtones():saturation():shiftValue(0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("down"))

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
    fcpxCmds
        :add("colorWheelMidtonesBrightnessUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:midtones():brightness():shiftValue(-0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("up"))

    fcpxCmds
        :add("colorWheelMidtonesBrightnessDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:midtones():brightness():shiftValue(0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("down"))

    fcpxCmds
        :add("colorWheelMidtonesBrightnessReset")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:midtones():brightness():value(0)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("midtones") .. " - " .. i18n("brightness") .. " - " .. i18n("reset"))

    --------------------------------------------------------------------------------
    -- Color Wheel Highlights:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("colorWheelHighlightsUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:highlights():nudgeColor(0, KEY_PRESS)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("nudge") .. " " .. i18n("up"))

    fcpxCmds
        :add("colorWheelHighlightsDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:highlights():nudgeColor(0, KEY_PRESS * -1)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("nudge") .. " " .. i18n("down"))

    fcpxCmds
        :add("colorWheelHighlightsLeft")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:highlights():nudgeColor(KEY_PRESS * -1, 0)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("nudge") .. " " .. i18n("left"))

    fcpxCmds
        :add("colorWheelHighlightsRight")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:highlights():nudgeColor(KEY_PRESS, 0)
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
    fcpxCmds
        :add("colorWheelHighlightsSaturationUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:highlights():saturation():shiftValue(-0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("up"))

    fcpxCmds
        :add("colorWheelHighlightsSaturationDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:highlights():saturation():shiftValue(0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("saturation") .. " - " .. i18n("nudge") .. " ".. i18n("down"))

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
    fcpxCmds
        :add("colorWheelHighlightsBrightnessUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:highlights():brightness():shiftValue(-0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("up"))

    fcpxCmds
        :add("colorWheelHighlightsBrightnessDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:highlights():brightness():shiftValue(0.01)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("highlights") .. " - " .. i18n("brightness") .. " - " .. i18n("nudge") .. " ".. i18n("down"))

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
    fcpxCmds
        :add("colorWheelTemperatureUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:temperatureSlider():shiftValue(-5)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("temperature") .. " - " .. i18n("nudge") .. " ".. i18n("up"))

    fcpxCmds
        :add("colorWheelTemperatureDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            colorWheels:temperatureSlider():shiftValue(5)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("temperature") .. " - " .. i18n("nudge") .. " ".. i18n("down"))

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
    fcpxCmds
        :add("colorWheelTintUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            local currentValue = colorWheels:tint()
            colorWheels:tint(currentValue + 1)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("tint") .. " - " .. i18n("nudge") .. " ".. i18n("up"))

    fcpxCmds
        :add("colorWheelTintDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            local currentValue = colorWheels:tint()
            colorWheels:tint(currentValue - 1)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("tint") .. " - " .. i18n("nudge") .. " ".. i18n("down"))

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
    fcpxCmds
        :add("colorWheelMixUp")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            local currentValue = colorWheels:mix()
            colorWheels:mix(currentValue + 0.1)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("mix") .. " - " .. i18n("nudge") .. " ".. i18n("up"))

    fcpxCmds
        :add("colorWheelMixDown")
        :groupedBy("colorWheels")
        :whenActivated(function()
            if not colorWheels:isShowing() then colorWheels:show() end
            local currentValue = colorWheels:mix()
            colorWheels:mix(currentValue - 0.1)
        end)
        :titled(i18n("colorWheel") .. " - " .. i18n("mix") .. " - " .. i18n("nudge") .. " ".. i18n("down"))

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