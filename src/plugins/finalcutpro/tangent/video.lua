--- === plugins.finalcutpro.tangent.video ===
---
--- Final Cut Pro Video Inspector for Tangent

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
    id = "finalcutpro.tangent.video",
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
    local id                            = 0x0F730000

    local common                        = deps.common
    local fcpGroup                      = deps.fcpGroup

    local buttonParameter               = common.buttonParameter
    local checkboxParameter             = common.checkboxParameter
    local checkboxParameterByIndex      = common.checkboxParameterByIndex
    local ninjaButtonParameter          = common.ninjaButtonParameter
    local popupParameter                = common.popupParameter
    local popupParameters               = common.popupParameters
    local popupSliderParameter          = common.popupSliderParameter
    local sliderParameter               = common.sliderParameter
    local xyParameter                   = common.xyParameter

    --------------------------------------------------------------------------------
    -- VIDEO INSPECTOR:
    --------------------------------------------------------------------------------
    local video                         = fcp:inspector():video()
    local videoGroup                    = fcpGroup:group(i18n("video") .. " " .. i18n("inspector"))

    local BLEND_MODES                   = video.BLEND_MODES
    local CROP_TYPES                    = video.CROP_TYPES
    local STABILIZATION_METHODS         = video.STABILIZATION_METHODS
    local ROLLING_SHUTTER_AMOUNTS       = video.ROLLING_SHUTTER_AMOUNTS
    local SPATIAL_CONFORM_TYPES         = video.SPATIAL_CONFORM_TYPES

        --------------------------------------------------------------------------------
        --
        -- EFFECTS:
        --
        --------------------------------------------------------------------------------
        local effects = video:effects()
        local effectsGroup = videoGroup:group(i18n("effects"))

            --------------------------------------------------------------------------------
            -- Enable/Disable:
            --------------------------------------------------------------------------------
            id = checkboxParameter(effectsGroup, effects, id, "toggle")

            --------------------------------------------------------------------------------
            -- Individual Effects:
            --------------------------------------------------------------------------------
            local individualEffectsGroup = effectsGroup:group(i18n("individualEffects"))
            for i=1, 9 do
                id = checkboxParameterByIndex(individualEffectsGroup, effects, video:compositing(), id, i18n("toggle") .. " " .. i, i)
            end

        --------------------------------------------------------------------------------
        --
        -- COMPOSITING:
        --
        --------------------------------------------------------------------------------
        local compositing = video:compositing()
        local compositingGroup = videoGroup:group(compositing:label())

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(compositingGroup, compositing.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Blend Mode (Buttons):
            --------------------------------------------------------------------------------
            local blendMode = fcp:inspector():video():compositing():blendMode()
            local blendModesGroup = compositingGroup:group(i18n("blendModes"))
            for i=1, tableCount(BLEND_MODES) do
                local v = BLEND_MODES[i]
                id = popupParameter(blendModesGroup, blendMode, id, fcp:string(v.flexoID), v.i18n)
            end

            --------------------------------------------------------------------------------
            -- Blend Mode (Knob):
            --------------------------------------------------------------------------------
            id = popupSliderParameter(blendModesGroup, blendMode, id, "blendModes", BLEND_MODES, 1)

            --------------------------------------------------------------------------------
            -- Opacity:
            --------------------------------------------------------------------------------
            id = sliderParameter(compositingGroup, compositing:opacity(), id, 0, 100, 0.1, 100)

        --------------------------------------------------------------------------------
        --
        -- TRANSFORM:
        --
        --------------------------------------------------------------------------------
        local transform = video:transform()
        local transformGroup = videoGroup:group(transform:label())

            --------------------------------------------------------------------------------
            -- Enable/Disable:
            --------------------------------------------------------------------------------
            id = checkboxParameter(transformGroup, transform, id, "toggle")

            --------------------------------------------------------------------------------
            -- Toggle UI:
            --------------------------------------------------------------------------------
            id = buttonParameter(transformGroup, transform.toggle, id, "toggleControls")

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(transformGroup, transform.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Position:
            --------------------------------------------------------------------------------
            local px, py, rotation
            id, px, py = xyParameter(transformGroup, transform:position(), id, 0, 1000, 0.1)

            --------------------------------------------------------------------------------
            -- Rotation:
            --------------------------------------------------------------------------------
            id, rotation = sliderParameter(transformGroup, transform:rotation(), id, 0, 360, 0.1)
            transformGroup:binding(tostring(transform:position()) .. " " .. tostring(transform:rotation()))
                :members(px, py, rotation)

            --------------------------------------------------------------------------------
            -- Scale:
            --------------------------------------------------------------------------------
            id = sliderParameter(transformGroup, transform:scaleAll(), id, 0, 100, 0.1, 100.0)
            id = sliderParameter(transformGroup, transform:scaleX(), id, 0, 100, 0.1, 100.0)
            id = sliderParameter(transformGroup, transform:scaleY(), id, 0, 100, 0.1, 100.0)

            --------------------------------------------------------------------------------
            -- Anchor:
            --------------------------------------------------------------------------------
            id = xyParameter(transformGroup, transform:anchor(), id, 0, 1000, 0.1)

        --------------------------------------------------------------------------------
        --
        -- CROP:
        --
        --------------------------------------------------------------------------------
        local crop = video:crop()
        local cropGroup = videoGroup:group(crop:label())

            --------------------------------------------------------------------------------
            -- Enable/Disable:
            --------------------------------------------------------------------------------
            id = checkboxParameter(cropGroup, crop, id, "toggle")

            --------------------------------------------------------------------------------
            -- Toggle UI:
            --------------------------------------------------------------------------------
            id = buttonParameter(cropGroup, crop.toggle, id, "toggleControls")

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(cropGroup, crop.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Type (Buttons):
            --------------------------------------------------------------------------------
            local cropType = fcp:inspector():video():crop():type()
            local cropTypesGroup = cropGroup:group(i18n("cropTypes"))
            id = popupParameters(cropTypesGroup, cropType, id, CROP_TYPES)

            --------------------------------------------------------------------------------
            -- Type (Knob):
            --------------------------------------------------------------------------------
            id = popupSliderParameter(cropGroup, cropType, id, "cropTypes", CROP_TYPES, 1)

            --------------------------------------------------------------------------------
            -- Left / Right / Top / Bottom:
            --------------------------------------------------------------------------------
            id = sliderParameter(cropGroup, crop:left(), id, 0, 1080, 0.1, 0)
            id = sliderParameter(cropGroup, crop:right(), id, 0, 1080, 0.1, 0)
            id = sliderParameter(cropGroup, crop:top(), id, 0, 1080, 0.1, 0)
            id = sliderParameter(cropGroup, crop:bottom(), id, 0, 1080, 0.1, 0)

        --------------------------------------------------------------------------------
        --
        -- DISTORT:
        --
        --------------------------------------------------------------------------------
        local distort = video:distort()
        local distortGroup = videoGroup:group(distort:label())

            --------------------------------------------------------------------------------
            -- Enable/Disable:
            --------------------------------------------------------------------------------
            id = checkboxParameter(distortGroup, distort, id, "toggle")

            --------------------------------------------------------------------------------
            -- Toggle UI:
            --------------------------------------------------------------------------------
            id = buttonParameter(distortGroup, distort.toggle, id, "toggleControls")

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(distortGroup, distort.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Bottom Left / Bottom Right / Top Right / Top Left:
            --------------------------------------------------------------------------------
            id = xyParameter(distortGroup, distort:bottomLeft(), id, 0, 1080, 0.1)
            id = xyParameter(distortGroup, distort:bottomRight(), id, 0, 1080, 0.1)
            id = xyParameter(distortGroup, distort:topRight(), id, 0, 1080, 0.1)
            id = xyParameter(distortGroup, distort:topLeft(), id, 0, 1080, 0.1)

        --------------------------------------------------------------------------------
        --
        -- STABILISATION:
        --
        --------------------------------------------------------------------------------
        local stabilization = video:stabilization()
        local stabilizationGroup = videoGroup:group(stabilization:label())

            --------------------------------------------------------------------------------
            -- Enable/Disable:
            --------------------------------------------------------------------------------
            id = checkboxParameter(stabilizationGroup, stabilization, id, "toggle")

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(stabilizationGroup, stabilization.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Method (Buttons):
            --------------------------------------------------------------------------------
            local stabilizationMethod = stabilization:method()
            local stabilizationMethodGroup = stabilizationGroup:group(i18n("method"))
            id = popupParameters(stabilizationMethodGroup, stabilizationMethod, id, STABILIZATION_METHODS)

            --------------------------------------------------------------------------------
            -- Method (Knob):
            --------------------------------------------------------------------------------
            id = popupSliderParameter(stabilizationGroup, stabilization:method(), id, "method", STABILIZATION_METHODS, 1)

            --------------------------------------------------------------------------------
            -- Translation Smooth / Rotation Smooth / Scale Smooth / Smoothing:
            --------------------------------------------------------------------------------
            id = sliderParameter(stabilizationGroup, stabilization:translationSmooth(), id, 0, 4.5, 0.1, 1.5)
            id = sliderParameter(stabilizationGroup, stabilization:rotationSmoooth(), id, 0, 4.5, 0.1, 1.5)
            id = sliderParameter(stabilizationGroup, stabilization:scaleSmooth(), id, 0, 4.5, 0.1, 1.5)
            id = sliderParameter(stabilizationGroup, stabilization:smoothing(), id, 0, 3, 0.1, 1)

        --------------------------------------------------------------------------------
        --
        -- ROLLING SHUTTER:
        --
        --------------------------------------------------------------------------------
        local rollingShutter = video:rollingShutter()
        local rollingShutterGroup = videoGroup:group(rollingShutter:label())

            --------------------------------------------------------------------------------
            -- Enable/Disable:
            --------------------------------------------------------------------------------
            id = checkboxParameter(rollingShutterGroup, rollingShutter, id, "toggle")

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(rollingShutterGroup, rollingShutter.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Amount (Buttons):
            --------------------------------------------------------------------------------
            local rollingShutterAmount = rollingShutter:amount()
            local rollingShutterAmountGroup = rollingShutterGroup:group(i18n("amount"))
            id = popupParameters(rollingShutterAmountGroup, rollingShutterAmount, id, ROLLING_SHUTTER_AMOUNTS)

            --------------------------------------------------------------------------------
            -- Amount (Knob):
            --------------------------------------------------------------------------------
            id = popupSliderParameter(rollingShutterGroup, rollingShutterAmount, id, "amount", ROLLING_SHUTTER_AMOUNTS, 1)

        --------------------------------------------------------------------------------
        --
        -- SPATIAL CONFORM:
        --
        --------------------------------------------------------------------------------
        local spatialConform = video:spatialConform()
        local spatialConformGroup = videoGroup:group(spatialConform:label())

            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            id = ninjaButtonParameter(spatialConformGroup, spatialConform.reset, id, "reset")

            --------------------------------------------------------------------------------
            -- Type (Buttons):
            --------------------------------------------------------------------------------
            local spatialConformType = spatialConform:type()
            local spatialConformTypeGroup = spatialConformGroup:group(i18n("type"))
            id = popupParameters(spatialConformTypeGroup, spatialConformType, id, SPATIAL_CONFORM_TYPES)

            --------------------------------------------------------------------------------
            -- Type (Knob):
            --------------------------------------------------------------------------------
            popupSliderParameter(spatialConformGroup, spatialConformType, id, "type", SPATIAL_CONFORM_TYPES, 1)

end

return plugin
