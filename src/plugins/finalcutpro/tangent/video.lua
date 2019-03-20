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
-- THE MODULE:
--
--------------------------------------------------------------------------------

-- BLEND_MODES -> table
-- Constant
-- Blend Modes
local BLEND_MODES = {
    [1]     = {flexoID = "FFHeliumBlendModeNormal", i18n="normal"},
    [2]     = {flexoID = "FFHeliumBlendModeSubtract", i18n="subtract"},
    [3]     = {flexoID = "FFHeliumBlendModeDarken", i18n="darken"},
    [4]     = {flexoID = "FFHeliumBlendModeMultiply", i18n="multiply"},
    [5]     = {flexoID = "FFHeliumBlendModeColorBurn", i18n="colorBurn"},
    [6]     = {flexoID = "FFHeliumBlendModeLinearBurn", i18n="linearBurn"},
    [7]     = {flexoID = "FFHeliumBlendModeAdd", i18n="add"},
    [8]     = {flexoID = "FFHeliumBlendModeLighten", i18n="lighten"},
    [9]     = {flexoID = "FFHeliumBlendModeScreen", i18n="screen"},
    [10]    = {flexoID = "FFHeliumBlendModeColorDodge", i18n="colorDodge"},
    [11]    = {flexoID = "FFHeliumBlendModeLinearDodge", i18n="linearDodge"},
    [12]    = {flexoID = "FFHeliumBlendModeOverlay", i18n="overlay"},
    [13]    = {flexoID = "FFHeliumBlendModeSoftLight", i18n="softLight"},
    [14]    = {flexoID = "FFHeliumBlendModeHardLight", i18n="hardLight"},
    [15]    = {flexoID = "FFHeliumBlendModeVividLight", i18n="vividLight"},
    [16]    = {flexoID = "FFHeliumBlendModeLinearLight", i18n="linearLight"},
    [17]    = {flexoID = "FFHeliumBlendModePinLight", i18n="pinLight"},
    [18]    = {flexoID = "FFHeliumBlendModeHardMix", i18n="hardMix"},
    [19]    = {flexoID = "FFHeliumBlendModeDifference", i18n="difference"},
    [20]    = {flexoID = "FFHeliumBlendModeExclusion", i18n="exclusion"},
    [21]    = {flexoID = "FFHeliumBlendModeStencilAlpha", i18n="stencilAlpha"},
    [22]    = {flexoID = "FFHeliumBlendModeStencilLuma", i18n="stencilLuma"},
    [23]    = {flexoID = "FFHeliumBlendModeSilhouetteAlpha", i18n="silhouetteAlpha"},
    [24]    = {flexoID = "FFHeliumBlendModeSilhouetteLuma", i18n="silhouetteLuma"},
    [25]    = {flexoID = "FFHeliumBlendModeBehind", i18n="behind"},
    [26]    = {flexoID = "FFHeliumBlendModeAlphaAdd", i18n="alphaAdd"},
    [27]    = {flexoID = "FFHeliumBlendModePremultipliedMix", i18n="premultipliedMix"},
}

-- CROP_TYPES -> table
-- Constant
-- Crop Types
local CROP_TYPES = {
    [1]     = {flexoID = "FFTrim", i18n = "trim"},
    [2]     = {flexoID = "FFCrop", i18n = "crop"},
    [3]     = {flexoID = "FFKenBurns", i18n = "kenBurns"},
}

-- STABILIZATION_METHODS -> table
-- Constant
-- Stabilisation Methods
local STABILIZATION_METHODS = {
    [1]     = {flexoID = "FFStabilizationDynamic", i18n="automatic"},
    [2]     = {flexoID = "FFStabilizationUseInertiaCam", i18n="inertiaCam"},
    [3]     = {flexoID = "FFStabilizationUseSmoothCam", i18n="smoothCam"},
}

-- ROLLING_SHUTTER_AMOUNTS -> table
-- Constant
-- Rolling Shutter Amounts
local ROLLING_SHUTTER_AMOUNTS = {
    [1]     = {flexoID = "FFRollingShutterAmountNone", i18n="none"},
    [2]     = {flexoID = "FFRollingShutterAmountLow", i18n="low"},
    [3]     = {flexoID = "FFRollingShutterAmountMedium", i18n="medium"},
    [4]     = {flexoID = "FFRollingShutterAmountHigh", i18n="high"},
    [5]     = {flexoID = "FFRollingShutterAmountExtraHigh", i18n="extraHigh"},
}

-- SPATIAL_CONFORM_TYPES -> table
-- Constant
-- Spatial Conform Types
local SPATIAL_CONFORM_TYPES = {
    [1]     = {flexoID = "FFConformTypeFit", i18n="fit"},
    [2]     = {flexoID = "FFConformTypeFill", i18n="fill"},
    [3]     = {flexoID = "FFConformTypeNone", i18n="none"},
}

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
        ["core.tangent.manager"]        = "tangentManager",
    }
}

function plugin.init(deps)

    local id = 0x0F730000

    local common                = deps.common

    local checkboxParameterByIndex        = common.checkboxParameterByIndex
    local checkboxParameter     = common.checkboxParameter
    local popupParameter        = common.popupParameter
    local popupParameters       = common.popupParameters
    local popupSliderParameter  = common.popupSliderParameter
    local sliderParameter       = common.sliderParameter
    local xyParameter           = common.xyParameter

    --------------------------------------------------------------------------------
    -- VIDEO INSPECTOR:
    --------------------------------------------------------------------------------
    local video = fcp:inspector():video()
    local videoGroup = deps.fcpGroup:group(i18n("video") .. " " .. i18n("inspector"))

        --------------------------------------------------------------------------------
        --
        -- EFFECTS:
        --
        --------------------------------------------------------------------------------
        local effects = video:effects()
        local effectsGroup = videoGroup:group(effects:label())

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
